#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <GLES3/gl3.h>
#include <algorithm>
#include <array>
#include <cmath>
#include <fstream>
#include <iostream>
#include <iterator>
#include <stdexcept>
#include <string>
#include <vector>

static void check(bool value, const char* message) {
    if (!value) throw std::runtime_error(message);
}
static GLuint compile(GLenum type, const std::string& source) {
    GLuint shader = glCreateShader(type);
    const char* text = source.c_str();
    glShaderSource(shader, 1, &text, nullptr); glCompileShader(shader);
    GLint success; glGetShaderiv(shader, GL_COMPILE_STATUS, &success);
    if (!success) {
        char message[4096]; glGetShaderInfoLog(shader, sizeof(message), nullptr, message);
        throw std::runtime_error(message);
    }
    return shader;
}

int main(int argc, char** argv) {
    try {
        if (argc != 2) return 2;
        EGLDisplay display = eglGetPlatformDisplay(EGL_PLATFORM_SURFACELESS_MESA, EGL_DEFAULT_DISPLAY, nullptr);
        check(eglInitialize(display, nullptr, nullptr), "EGL initialization failed");
        eglBindAPI(EGL_OPENGL_ES_API);
        const EGLint attributes[] = {EGL_SURFACE_TYPE,EGL_PBUFFER_BIT,EGL_RENDERABLE_TYPE,EGL_OPENGL_ES3_BIT,
            EGL_RED_SIZE,8,EGL_GREEN_SIZE,8,EGL_BLUE_SIZE,8,EGL_ALPHA_SIZE,8,EGL_NONE};
        EGLConfig config; EGLint count;
        check(eglChooseConfig(display,attributes,&config,1,&count) && count,"EGL config unavailable");
        const EGLint ca[] = {EGL_CONTEXT_CLIENT_VERSION,3,EGL_NONE};
        EGLContext context = eglCreateContext(display,config,EGL_NO_CONTEXT,ca);
        const EGLint sa[] = {EGL_WIDTH,320,EGL_HEIGHT,320,EGL_NONE};
        EGLSurface surface = eglCreatePbufferSurface(display,config,sa);
        check(eglMakeCurrent(display,surface,surface,context),"EGL context unavailable");
        std::ifstream file(argv[1]);
        std::string fragment{std::istreambuf_iterator<char>(file),std::istreambuf_iterator<char>()};
        const char* vertex = R"(#version 300 es
layout(location=0) in vec2 position;
out vec2 v_texcoord;
void main() {gl_Position=vec4(position,0,1); v_texcoord=position*0.5+0.5;})";
        GLuint program=glCreateProgram();
        glAttachShader(program,compile(GL_VERTEX_SHADER,vertex));
        glAttachShader(program,compile(GL_FRAGMENT_SHADER,fragment));
        glLinkProgram(program); GLint linked; glGetProgramiv(program,GL_LINK_STATUS,&linked);
        check(linked,"Wallpaper shader did not link"); glUseProgram(program);
        GLuint vao,vbo,texture;
        glGenVertexArrays(1,&vao); glBindVertexArray(vao);
        glGenBuffers(1,&vbo); glBindBuffer(GL_ARRAY_BUFFER,vbo);
        const float vertices[] = {-1,-1,1,-1,-1,1,1,1};
        glBufferData(GL_ARRAY_BUFFER,sizeof(vertices),vertices,GL_STATIC_DRAW);
        glEnableVertexAttribArray(0); glVertexAttribPointer(0,2,GL_FLOAT,GL_FALSE,0,nullptr);
        glGenTextures(1,&texture); glBindTexture(GL_TEXTURE_2D,texture);
        std::vector<unsigned char> pixels(320*180*4,255);
        for(int y=0;y<180;y++) for(int x=0;x<320;x++) {
            auto i=(y*320+x)*4;
            pixels[i]=x<80?255:0; pixels[i+1]=x>=80&&x<240?255:0; pixels[i+2]=x>=240?255:0;
        }
        glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA,320,180,0,GL_RGBA,GL_UNSIGNED_BYTE,pixels.data());
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
        glUniform1i(glGetUniformLocation(program,"tex"),0);
        glUniform1f(glGetUniformLocation(program,"phase"),0);
        auto draw=[&](float p,float mode,int width,int height,float x=1,float y=0) {
            glUniform1f(glGetUniformLocation(program,"progress"),p);
            glUniform1f(glGetUniformLocation(program,"mode"),mode);
            glUniform2f(glGetUniformLocation(program,"fullSize"),width,height);
            glUniform2f(glGetUniformLocation(program,"direction"),x,y);
            glViewport(0,0,width,height); glDrawArrays(GL_TRIANGLE_STRIP,0,4);
        };
        auto pixel=[&](int x,int y) {
            std::array<unsigned char,4> result; glReadPixels(x,y,1,1,GL_RGBA,GL_UNSIGNED_BYTE,result.data()); return result;
        };
        const std::array<std::array<float,2>,8> directions{{{1,0},{-1,0},{0,1},{0,-1},{1,1},{1,-1},{-1,1},{-1,-1}}};
        for(int mode=0;mode<5;mode++) for(auto d:directions) for(auto size:{std::pair{320,180},std::pair{180,320}}) {
            draw(0,mode,size.first,size.second,d[0],d[1]);
            for(auto point:{std::pair{0,0},std::pair{size.first-1,size.second-1},std::pair{size.first/2,size.second/2}})
                check(pixel(point.first,point.second)[3]==255,"Old endpoint contains a hole");
            draw(1,mode,size.first,size.second,d[0],d[1]);
            for(auto point:{std::pair{0,0},std::pair{size.first-1,size.second-1},std::pair{size.first/2,size.second/2}})
                check(pixel(point.first,point.second)[3]==0,"New endpoint contains residual pixels");
        }
        draw(0,0,320,180);
        check(pixel(160,90)[1]>240 && pixel(0,90)[0]>240 && pixel(319,90)[2]>240,"Native framebuffer sampling changed colours or centre");
        draw(.5,0,320,180);
        int minimum=320,maximum=0;
        for(int y=10;y<170;y+=4) {
            int x=0; while(x<319 && pixel(x,y)[3]<128) ++x;
            minimum=std::min(minimum,x); maximum=std::max(maximum,x);
        }
        check(maximum-minimum>25,"Wave collapsed into a straight wipe");
        check(pixel(20,90)[3]==0 && pixel(300,90)[3]==255,"Wave reveal reversed");
        draw(.25,0,320,180); check(pixel(100,90)[3]==255,"Wave reveals too early");
        draw(.75,0,320,180); check(pixel(220,90)[3]==0,"Wave does not advance");
        draw(.5,3,320,180); check(std::abs(int(pixel(160,90)[3])-128)<=1,"Fade alpha is incorrect");
        draw(.5,4,320,180); check(pixel(20,90)[3]==0 && pixel(300,90)[3]==255,"Wipe is incorrect");
        draw(.5,1,320,180);
        check(pixel(160,90)[3]==0 && pixel(319,179)[3]==255,"Grow mask is incorrect");
        check(std::abs(int(pixel(240,90)[3])-int(pixel(160,170)[3]))<=2,"Radial mask is stretched");
        draw(.5,2,320,180); check(pixel(160,90)[3]==255 && pixel(319,179)[3]==0,"Outer mask is incorrect");
        glEnable(GL_BLEND); glBlendFunc(GL_ONE,GL_ONE_MINUS_SRC_ALPHA);
        glClearColor(.1F,.2F,.8F,1.F); glClear(GL_COLOR_BUFFER_BIT);
        draw(.5,0,320,180);
        check(pixel(20,90)[2]>200 && pixel(300,90)[2]>240,"Wave compositing discarded the new wallpaper");
        check(pixel(20,90)[3]==255 && pixel(300,90)[3]==255,"Composited wallpaper contains alpha holes");
        check(glGetError()==GL_NO_ERROR,"Wallpaper rendering GL error");
        std::cout << "Wallpaper pixels: native wave, fade, wipe, grow, outer, framebuffer sampling, blend, 8 directions, portrait and landscape passed\n";
        return 0;
    } catch(const std::exception& error) { std::cerr << error.what() << '\n'; return 1; }
}
