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
        if (argc != 4) return 2;
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
out vec2 qt_TexCoord0;
void main() {gl_Position=vec4(position,0,1); qt_TexCoord0=position*0.5+0.5;})";
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
        std::ifstream input(argv[2],std::ios::binary);
        std::vector<unsigned char> pixels{std::istreambuf_iterator<char>(input),std::istreambuf_iterator<char>()};
        check(pixels.size()==112*112*4,"Invalid input image");
        glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA,112,112,0,GL_RGBA,GL_UNSIGNED_BYTE,pixels.data());
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S,GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_T,GL_CLAMP_TO_EDGE);
        glUniform1i(glGetUniformLocation(program,"source"),0);
        glUniform2f(glGetUniformLocation(program,"pixelStep"),.75f/28,.75f/28);
        glUniform4f(glGetUniformLocation(program,"ink"),1,1,1,1);
        glUniform1f(glGetUniformLocation(program,"qt_Opacity"),1);
        glViewport(0,0,112,112);glDrawArrays(GL_TRIANGLE_STRIP,0,4);
        std::vector<unsigned char> result(112*112*4);
        glReadPixels(0,0,112,112,GL_RGBA,GL_UNSIGNED_BYTE,result.data());
        check(glGetError()==GL_NO_ERROR,"Render failed");
        std::ofstream output(argv[3],std::ios::binary);output.write(reinterpret_cast<char*>(result.data()),result.size());
        eglDestroySurface(display,surface);eglDestroyContext(display,context);eglTerminate(display);
        return 0;
    } catch(const std::exception& error) { std::cerr<<error.what()<<"\n";return 1; }
}
