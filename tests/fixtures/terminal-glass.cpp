#include "../../native/hyprland/TerminalGlass.hpp"
#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <GLES3/gl3.h>
#include <hyprutils/math/Box.hpp>
#include <hyprutils/math/Mat3x3.hpp>
#include <algorithm>
#include <array>
#include <cmath>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <iterator>
#include <stdexcept>
#include <vector>

int W = 256, H = 192;
int X = 32, Y = 24, WIDTH = 192, HEIGHT = 144;
using Pixel = std::array<unsigned char, 4>;
using FloatPixel = std::array<float, 4>;
void check(bool condition, const char* message) {
    if (!condition) throw std::runtime_error(message);
}
GLuint program(const std::string& vertex, const std::string& fragment) {
    GLuint result = glCreateProgram();
    for (auto [type, source] : {std::pair{GL_VERTEX_SHADER, vertex}, std::pair{GL_FRAGMENT_SHADER, fragment}}) {
        GLuint shader = glCreateShader(type);
        const char* text = source.c_str();
        glShaderSource(shader, 1, &text, nullptr);
        glCompileShader(shader);
        GLint compiled = 0;
        glGetShaderiv(shader, GL_COMPILE_STATUS, &compiled);
        if (!compiled) {
            char message[4096];
            glGetShaderInfoLog(shader, sizeof(message), nullptr, message);
            throw std::runtime_error(message);
        }
        glAttachShader(result, shader);
        glDeleteShader(shader);
    }
    glLinkProgram(result);
    GLint linked = 0;
    glGetProgramiv(result, GL_LINK_STATUS, &linked);
    check(linked, "Shader did not link");
    return result;
}
GLuint texture(int width, int height, const void* data = nullptr,
               GLint format = GL_RGBA, GLenum type = GL_UNSIGNED_BYTE, GLint filtering = GL_NEAREST) {
    GLuint result;
    glGenTextures(1, &result);
    glBindTexture(GL_TEXTURE_2D, result);
    glTexImage2D(GL_TEXTURE_2D, 0, format, width, height, 0, GL_RGBA, type, data);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, filtering);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, filtering);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    return result;
}
GLuint target(GLuint texture) {
    GLuint result;
    glGenFramebuffers(1, &result);
    glBindFramebuffer(GL_FRAMEBUFFER, result);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, texture, 0);
    check(glCheckFramebufferStatus(GL_FRAMEBUFFER) == GL_FRAMEBUFFER_COMPLETE, "Incomplete framebuffer");
    return result;
}
Pixel pixel(int x, int y) {
    Pixel result;
    glReadPixels(x, y, 1, 1, GL_RGBA, GL_UNSIGNED_BYTE, result.data());
    return result;
}
void one(GLuint p, const char* name, float a) { glUniform1f(glGetUniformLocation(p, name), a); }
void two(GLuint p, const char* name, float a, float b) { glUniform2f(glGetUniformLocation(p, name), a, b); }
void sampler(GLuint p, const char* name, int unit, GLuint tex) {
    glActiveTexture(GL_TEXTURE0 + unit);
    glBindTexture(GL_TEXTURE_2D, tex);
    glUniform1i(glGetUniformLocation(p, name), unit);
}
void geometry(GLuint p, int x, int y, int width, int height,
              Hyprutils::Math::eTransform transform = Hyprutils::Math::HYPRUTILS_TRANSFORM_NORMAL) {
    using namespace Hyprutils::Math;
    const auto matrix = Mat3x3::outputProjection({W, H}, HYPRUTILS_TRANSFORM_NORMAL)
        .projectBox({double(x), double(y), double(width), double(height)}, transform).transpose().getMatrix();
    glUniformMatrix3fv(glGetUniformLocation(p, "proj"), 1, GL_FALSE, matrix.data());
}

void savePreview(const std::filesystem::path& path, GLuint framebuffer, const std::vector<Pixel>& scene) {
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    std::vector<Pixel> pixels(W * H);
    glReadPixels(0, 0, W, H, GL_RGBA, GL_UNSIGNED_BYTE, pixels.data());
    std::ofstream output(path, std::ios::binary);
    output << "P6\n" << W << ' ' << H << "\n255\n";
    for (int y = H - 1; y >= 0; --y) for (int x = 0; x < W; ++x) {
        const auto p = pixels[y * W + x], backdrop = scene[y * W + x];
        Pixel composed{};
        for (int i=0;i<3;++i) composed[i]=std::min(255.F,p[i]+backdrop[i]*(1.F-p[3]/255.F));
        output.write(reinterpret_cast<const char*>(composed.data()), 3);
    }
    check(output.good(), "Cannot save shader preview");
}

int main(int argc, char** argv) {
    try {
        if (argc != 3 && argc != 4 && argc != 5) return 2;
        check(kittyClass("kitty") && kittyClass("Kitty") && kittyClass("KITTY"), "Kitty class matching");
        check(!kittyClass("mykitty") && !kittyClass("kitty-helper"), "Kitty class scope");
        check(kittyExecutable("/opt/kitty/bin/kitty") && kittyExecutable("/usr/bin/kitty (deleted)"), "Custom class executable");
        check(!kittyExecutable("/usr/bin/alacritty") && !kittyExecutable("/tmp/not-kitty"), "Other applications");
        for (const char* text : {"1 0", "0 1", "1 3", "1 2.5"})
            check(parseTerminalGlassControl(text).has_value(), "Valid terminal control rejected");
        for (const char* text : {"2 1", "-1 1", "1 -1", "1 3.1", "1 nan", "1 inf", "1", "1 1 extra"})
            check(!parseTerminalGlassControl(text), "Invalid control changes terminal state");
        const auto off=parseTerminalGlassControl("0 2.5"), on=parseTerminalGlassControl("1 2.5");
        check(off && on && !off->enabled && on->enabled && off->strength==on->strength,
            "Toggle loses saved refraction intensity");
        EGLDisplay display = eglGetPlatformDisplay(EGL_PLATFORM_SURFACELESS_MESA, EGL_DEFAULT_DISPLAY, nullptr);
        if (!eglInitialize(display, nullptr, nullptr)) return 77;
        eglBindAPI(EGL_OPENGL_ES_API);
        const EGLint attributes[] = {EGL_SURFACE_TYPE, EGL_PBUFFER_BIT, EGL_RENDERABLE_TYPE, EGL_OPENGL_ES3_BIT,
            EGL_RED_SIZE, 8, EGL_GREEN_SIZE, 8, EGL_BLUE_SIZE, 8, EGL_ALPHA_SIZE, 8, EGL_NONE};
        EGLConfig config;
        EGLint count;
        if (!eglChooseConfig(display, attributes, &config, 1, &count) || !count) return 77;
        const EGLint contextAttributes[] = {EGL_CONTEXT_CLIENT_VERSION, 3, EGL_NONE};
        EGLContext context = eglCreateContext(display, config, EGL_NO_CONTEXT, contextAttributes);
        const EGLint surfaceAttributes[] = {EGL_WIDTH, W, EGL_HEIGHT, H, EGL_NONE};
        EGLSurface surface = eglCreatePbufferSurface(display, config, surfaceAttributes);
        if (!eglMakeCurrent(display, surface, surface, context)) return 77;
        auto read = [](const char* path) { std::ifstream input(path); return std::string{std::istreambuf_iterator<char>(input), {}}; };
        const auto vertex = read(argv[1]);
        GLuint glass = program(vertex, withTerminalGlassOptics(TERMINAL_GLASS_FRAGMENT));
        GLuint client = program(vertex, read(argv[2]));
        GLuint vao, buffer;
        glGenVertexArrays(1, &vao);
        glBindVertexArray(vao);
        glGenBuffers(1, &buffer);
        glBindBuffer(GL_ARRAY_BUFFER, buffer);
        const float vertices[] = {0,0,0,0, 0,1,0,1, 1,0,1,0, 1,1,1,1};
        glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
        auto bindAttributes = [&](GLuint p) {
            glUseProgram(p);
            for (auto [name, offset] : {std::pair{"pos", 0}, std::pair{"texcoord", 2}}) {
                GLint location = glGetAttribLocation(p, name);
                glEnableVertexAttribArray(location);
                glVertexAttribPointer(location, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(float), reinterpret_cast<void*>(offset * sizeof(float)));
            }
        };
        std::vector<Pixel> pixels(W * H);
        for (int y = 0; y < H; ++y) for (int x = 0; x < W; ++x)
            pixels[y * W + x] = {static_cast<unsigned char>(16 + x * .8), static_cast<unsigned char>(24 + y * .9), 100, 255};
        GLuint background = texture(W, H, pixels.data());
        GLuint opticalSource = background;
        GLuint lensTexture = texture(W, H), lensFB = target(lensTexture);
        GLuint resultTexture = texture(W, H), resultFB = target(resultTexture);
        GLuint identityTexture = texture(W, H), identityFB = target(identityTexture);
        std::vector<Pixel> content(64 * 64, Pixel{12, 16, 20, 102});
        for (int y = 29; y < 35; ++y) for (int x = 3; x < 6; ++x)
            content[y * 64 + x] = {230, 191, 91, 255};
        GLuint foreground = texture(64, 64, content.data());
        glViewport(0, 0, W, H);
        glClearColor(0, 0, 0, 0);
        float refractionPixels=TERMINAL_REFRACTION_PIXELS, rimWidth=TERMINAL_RIM_WIDTH;
        auto drawGlass = [&](GLuint fb, float strength, int x=X, int width=WIDTH,
                             int y=Y, int height=HEIGHT, float scale=1.F) {
            glBindFramebuffer(GL_FRAMEBUFFER, fb);
            bindAttributes(glass);
            geometry(glass, x, y, width, height);
            sampler(glass, "tex", 0, opticalSource);
            sampler(glass, "blurredBG", 1, background);
            two(glass, "fullSize", W, H);
            two(glass, "bottomRight", width, height);
            one(glass, "radius", 16 * scale);
            one(glass, "roundingPower", 2);
            one(glass, "distort", refractionPixels * scale);
            one(glass, "contrast", rimWidth * scale);
            one(glass, "alpha", strength);
            one(glass, "vibrancy", 1);
            glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        };
        glBindFramebuffer(GL_FRAMEBUFFER, lensFB);
        glClear(GL_COLOR_BUFFER_BIT);
        drawGlass(lensFB, 1);
        check(pixel(X-1, Y+50)[3] == 0, "Glass exceeds its window");
        check(std::abs(pixel(X+WIDTH/2, Y+HEIGHT/2)[0] - pixels[(Y+HEIGHT/2)*W+X+WIDTH/2][0]) <= 1, "Focal point is displaced");
        check(pixel(X+2, Y+HEIGHT/2)[0] >= pixels[(Y+HEIGHT/2)*W+X+2][0] + 6, "Rim has no refraction");
        check(pixel(X+2,Y+HEIGHT/2)[0] <= pixels[(Y+HEIGHT/2)*W+X+2][0] + 11,
            "Default rim is still excessively displaced");
        check(pixel(X+WIDTH/4,Y+HEIGHT/2)[0] >= pixels[(Y+HEIGHT/2)*W+X+WIDTH/4][0] + 2,
            "Body has only blur/highlight instead of refraction");

        // Encode sampling coordinates in floating point textures. Neutral
        // reflections cancel when subtracting blue, exposing the actual ray
        // of the production shader without duplicating its displacement math.
        const GLuint savedBackground = background, savedOpticalSource = opticalSource;
        std::vector<FloatPixel> coordinates(W * H), rays(W * H);
        for (int y=0;y<H;++y) for (int x=0;x<W;++x)
            coordinates[y*W+x] = {.1F+.45F*(x+.5F)/W, .1F+.45F*(y+.5F)/H, .1F, 1.F};
        background = opticalSource = texture(W,H,coordinates.data(),GL_RGBA32F,GL_FLOAT,GL_LINEAR);
        const GLuint rayTexture=texture(W,H,nullptr,GL_RGBA32F,GL_FLOAT), rayFB=target(rayTexture);
        auto ray = [&](int x,int y) {
            const auto p=rays[y*W+x];
            return std::array<float,2>{(p[0]-p[2])*W/.45F, (p[1]-p[2])*H/.45F};
        };
        for (auto [width,height] : {std::pair{192,144}, {208,32}, {40,152}, {20,18}})
            for (float scale : {1.F,2.F}) for (float strength : {0.F,.25F,1.F,2.F,3.F}) {
                drawGlass(rayFB,strength,24,width,24,height,scale);
                glReadPixels(0,0,W,H,GL_RGBA,GL_FLOAT,rays.data());
                for (int y=25;y<24+height-2;++y) for (int x=25;x<24+width-2;++x) {
                    const auto p=ray(x,y), px=ray(x+1,y), py=ray(x,y+1);
                    const float xx=px[0]-p[0], xy=py[0]-p[0], yx=px[1]-p[1], yy=py[1]-p[1];
                    const float determinant=xx*yy-xy*yx;
                    check(std::isfinite(determinant) && xx>.25F && yy>.25F && determinant>.20F,
                        "Lens folds/inverts the wallpaper in a compact, wide or tall window");
                    check(xx<2.5F && yy<2.5F && std::abs(xy)<1.F && std::abs(yx)<1.F,
                        "Lens contains a discontinuity or excessive stretch");
                    if (strength==0.F) {
                        check(std::abs(p[0]-x-.5F)<.002F && std::abs(p[1]-y-.5F)<.002F,
                            "Zero intensity changes the sampling coordinates");
                    }
                }
                if (width==192 && height==144 && scale==1.F && strength==1.F) {
                    const auto p=ray(24+width/4,24+height/2);
                    check(p[0]-(24+width/4+.5F)>2.F,
                        "Body does not refract beyond the optical rim");
                    const auto top=ray(24+width/2,24+height/4);
                    check(top[1]-(24+height/4+.5F)>3.F,
                        "Body refraction points the wrong way in texture space");
                }
            }
        glDeleteFramebuffers(1,&rayFB);
        glDeleteTextures(1,&rayTexture);
        glDeleteTextures(1,&background);
        background=savedBackground;opticalSource=savedOpticalSource;
        drawGlass(lensFB,1);
        glBindFramebuffer(GL_FRAMEBUFFER, identityFB);
        glClear(GL_COLOR_BUFFER_BIT);
        drawGlass(identityFB, 0);
        for (int x : {X+2, X+WIDTH/2, X+WIDTH-3}) {
            check(pixel(x,Y+HEIGHT/2) == pixels[(Y+HEIGHT/2)*W+x], "Strength zero changes the backdrop");
        }
        auto drawClient = [&](GLuint backdrop, float alpha, bool rotated=false) {
            glBindFramebuffer(GL_FRAMEBUFFER, resultFB);
            glClear(GL_COLOR_BUFFER_BIT);
            bindAttributes(client);
            geometry(client, X, Y, WIDTH, HEIGHT, rotated
                ? Hyprutils::Math::HYPRUTILS_TRANSFORM_180 : Hyprutils::Math::HYPRUTILS_TRANSFORM_NORMAL);
            sampler(client, "tex", 0, foreground);
            sampler(client, "blurredBG", 1, backdrop);
            two(client, "uvSize", float(WIDTH)/W, float(HEIGHT)/H);
            two(client, "uvOffset", float(X)/W, float(Y)/H);
            two(client, "topLeft", X, Y);
            two(client, "fullSize", WIDTH, HEIGHT);
            one(client, "radius", 16);
            one(client, "roundingPower", 2);
            one(client, "alpha", alpha);
            glUniform1i(glGetUniformLocation(client, "discardAlpha"), GL_TRUE);
            one(client, "discardAlphaValue", 0);
            glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        };
        drawClient(lensTexture, 1);
        check(pixel(X+13, Y+HEIGHT/2) == Pixel{230,191,91,255}, "Opaque glyph is blurred or refracted");
        check(pixel(X,Y)[3] == 0 && pixel(X-1,Y+50)[3] == 0, "Client rounding was lost");
        check(pixel(X+2,Y+HEIGHT/2)[0] > pixels[(Y+HEIGHT/2)*W+X+2][0]*.6+12*.4, "Transparent client loses the lens");
        drawClient(lensTexture, 1, true);
        check(pixel(X+WIDTH-14, Y+HEIGHT/2) == Pixel{230,191,91,255}, "Output transform distorts the glyph");
        for (float alpha : {0.F, .35F, 1.F}) {
            drawClient(background, alpha);
            const auto expected = pixel(X+2,Y+HEIGHT/2);
            drawClient(identityTexture, alpha);
            check(pixel(X+2,Y+HEIGHT/2) == expected, "Identity lens changes client fade/composition");
        }
        // Reuse the same target for another window/resize; then update only
        // the damaged strip, leaving its untouched pixels intact.
        glBindFramebuffer(GL_FRAMEBUFFER, lensFB);
        glClear(GL_COLOR_BUFFER_BIT);
        drawGlass(lensFB, 1, 80, 140);
        check(pixel(82,Y+HEIGHT/2)[0] > pixels[(Y+HEIGHT/2)*W+82][0]+6, "Resize uses stale geometry");
        const Pixel untouched = pixel(150,Y+HEIGHT/2);
        const Pixel oldRim = pixel(82,Y+HEIGHT/2);
        for (auto& p : pixels) p[2] += 30;
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, background);
        glTexSubImage2D(GL_TEXTURE_2D,0,0,0,W,H,GL_RGBA,GL_UNSIGNED_BYTE,pixels.data());
        glEnable(GL_SCISSOR_TEST);
        glScissor(80,Y,8,HEIGHT);
        drawGlass(lensFB,1,80,140);
        glDisable(GL_SCISSOR_TEST);
        check(pixel(150,Y+HEIGHT/2) == untouched, "Partial damage overwrites unaffected pixels");
        check(pixel(82,Y+HEIGHT/2)[2] >= oldRim[2]+28, "Partial damage leaves a stale backdrop");

        // A pre-blurred source has already lost the detail needed for a lens.
        // Reproduce a strongly blurred wallpaper, then compose the sharp GPU
        // scene through a Kitty background with the user's actual 56% opacity.
        for (auto& p : pixels) p = {88,100,122,255};
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, background);
        glTexSubImage2D(GL_TEXTURE_2D,0,0,0,W,H,GL_RGBA,GL_UNSIGNED_BYTE,pixels.data());
        for (int y=0;y<H;++y) for (int x=0;x<W;++x)
            pixels[y*W+x] = ((x/8+y/8)%2) ? Pixel{240,230,180,255} : Pixel{20,35,65,255};
        const GLuint liveSceneTexture=texture(W,H,pixels.data());
        const GLuint sceneFB=target(liveSceneTexture);
        const GLuint desktopTexture=texture(W,H), desktopFB=target(desktopTexture);
        glBindFramebuffer(GL_READ_FRAMEBUFFER,sceneFB);
        glBindFramebuffer(GL_DRAW_FRAMEBUFFER,desktopFB);
        glBlitFramebuffer(0,0,W,H,0,0,W,H,GL_COLOR_BUFFER_BIT,GL_NEAREST);
        opticalSource=argc==4 ? background : desktopTexture;
        // Damage tracking may retain opaque glyphs in the working framebuffer.
        // The pre-window desktop cache must stay independent of those pixels.
        glBindFramebuffer(GL_FRAMEBUFFER,sceneFB);
        glEnable(GL_SCISSOR_TEST);
        glScissor(X+WIDTH/2-8,Y+HEIGHT/2-8,16,16);
        glClearColor(1,0,0,1);
        glClear(GL_COLOR_BUFFER_BIT);
        glDisable(GL_SCISSOR_TEST);
        glClearColor(0,0,0,0);
        check(sceneFB != lensFB && desktopFB!=sceneFB, "Scene, desktop and lens share targets");
        for (auto& p : content) if (p[3]!=255) p={20,19,29,143};
        glBindTexture(GL_TEXTURE_2D,foreground);
        glTexSubImage2D(GL_TEXTURE_2D,0,0,0,64,64,GL_RGBA,GL_UNSIGNED_BYTE,content.data());
        drawClient(background,1);
        const Pixel frostedBody=pixel(X+WIDTH/2,Y+HEIGHT/2);
        drawGlass(lensFB,1);
        drawClient(lensTexture,1);
        const Pixel liquidBody=pixel(X+WIDTH/2,Y+HEIGHT/2);
        check(std::abs(int(liquidBody[0])-int(frostedBody[0]))>=12,
            "Liquid is imperceptible after realistic Kitty opacity and native blur");
        const auto sourcePixel=pixels[(Y+HEIGHT/2)*W+X+WIDTH/2];
        const float clientAlpha=143.F/255.F;
        const float materialRed=(88.F*(1-.42F)+sourcePixel[0]*.42F);
        const float expectedRed=materialRed*(1-clientAlpha)+20.F*clientAlpha;
        check(std::abs(liquidBody[0]-expectedRed)<=2,
            "Liquid samples stale client pixels instead of the pre-window desktop");
        check(pixel(X+13,Y+HEIGHT/2)==Pixel{230,191,91,255},
            "Sharp scene alters opaque foreground pixels");
        drawGlass(identityFB,0);
        drawClient(identityTexture,1);
        check(pixel(X+WIDTH/2,Y+HEIGHT/2)==frostedBody,
            "Disabling liquid leaves sharp details behind");
        check(glGetError() == GL_NO_ERROR, "OpenGL error");

        if (argc == 5 && std::string(argv[3]) == "--follow-bar") {
            // Same production fragment for both materials. Compare the final
            // installed compositor client shader with the bar, including the
            // premultiplied, quantized Kitty background and opaque glyphs.
            const GLuint shared = program(vertex, withTerminalGlassOptics(read(argv[4])));
            for(int y=0;y<H;++y) for(int x=0;x<W;++x) {
                pixels[y*W+x] = {static_cast<unsigned char>(x*255/W),
                    static_cast<unsigned char>(y*255/H), static_cast<unsigned char>((x+y)*255/(W+H)),255};
                if(x>W*2/3) pixels[y*W+x]={255,255,255,255};
            }
            glActiveTexture(GL_TEXTURE0);glBindTexture(GL_TEXTURE_2D,background);
            glTexSubImage2D(GL_TEXTURE_2D,0,0,0,W,H,GL_RGBA,GL_UNSIGNED_BYTE,pixels.data());
            const bool eightBit = std::getenv("VELORA_KITTY_FOLLOW_8BIT");
            const GLuint opticalTexture = texture(W,H,nullptr,eightBit ? GL_RGBA8 : GL_RGBA16F,
                eightBit ? GL_UNSIGNED_BYTE : GL_HALF_FLOAT);
            const GLuint opticalFB = target(opticalTexture);
            const GLuint referenceTexture = texture(W,H), referenceFB = target(referenceTexture);
            auto four = [&](const char* name,float a,float b,float c,float d) {
                glUniform4f(glGetUniformLocation(shared,name),a,b,c,d);
            };
            auto render = [&](bool terminal,float strength,int mode,float opacity,float brightness=1.F,float barBrightness=1.F) {
                glBindFramebuffer(GL_FRAMEBUFFER,terminal ? opticalFB : referenceFB);
                glClear(GL_COLOR_BUFFER_BIT);
                bindAttributes(shared);
                geometry(shared,X,Y,WIDTH,HEIGHT);
                sampler(shared,"tex",0,background);
                two(shared,"fullSize",W,H);
                two(shared,"windowTopLeft",float(X)/W,float(Y)/H);
                two(shared,"windowBottomRight",float(X+WIDTH)/W,float(Y+HEIGHT)/H);
                two(shared,"topLeft",0,0);two(shared,"bottomRight",WIDTH*.5F,HEIGHT*.5F);
                one(shared,"radius",16);one(shared,"alpha",1);
                one(shared,"distort",4);one(shared,"contrast",16);one(shared,"noise",.35F);
                one(shared,"brightness",1.025F);one(shared,"vibrancy",1.12F);
                one(shared,"barRefractionStrength",strength);
                one(shared,"terminalBackdrop",terminal ? 1 : 0);
                one(shared,"terminalBrightness",brightness);
                one(shared,"barBrightness",barBrightness);
                four("barMaterial",1,mode,1,0);
                four("barTint",38.F/255.F,29.F/255.F,36.F/255.F,opacity);
                four("pointer_shape",0,0,0,1);four("pointer_position",0,0,0,W/1600.F);
                four("color",.94F,.97F,1,.08F*.32F);
                one(shared,"time",0);
                glDrawArrays(GL_TRIANGLE_STRIP,0,4);
            };
            for (const float opacity : {.024F,.1672889191513762F,.56F,.96F}) {
                const Pixel premultiplied = {
                    static_cast<unsigned char>(std::lround(38*opacity)),
                    static_cast<unsigned char>(std::lround(29*opacity)),
                    static_cast<unsigned char>(std::lround(36*opacity)),
                    static_cast<unsigned char>(std::lround(255*opacity))};
                std::fill(content.begin(),content.end(),premultiplied);
                for(int y=29;y<35;++y) for(int x=3;x<6;++x)
                    content[y*64+x]={230,191,91,255};
                glActiveTexture(GL_TEXTURE0);glBindTexture(GL_TEXTURE_2D,foreground);
                glTexSubImage2D(GL_TEXTURE_2D,0,0,0,64,64,GL_RGBA,GL_UNSIGNED_BYTE,content.data());
                for(float barBrightness : {.4F,1.F}) for(float brightness : {.96F,1.F,1.04F}) for(int mode : {1,2}) for(float strength : {0.F,1.F,4.59274656F,10.F}) {
                    render(false,strength,mode,opacity,1,barBrightness);
                    std::vector<Pixel> expected(W*H);
                    glReadPixels(0,0,W,H,GL_RGBA,GL_UNSIGNED_BYTE,expected.data());
                    render(true,strength,mode,opacity,brightness,barBrightness);
                    drawClient(opticalTexture,1);
                    for(int y=Y+20;y<Y+HEIGHT-20;y+=7) for(int x=X+20;x<X+WIDTH-20;x+=7) {
                        const auto actual=pixel(x,y), wanted=expected[y*W+x];
                        for(int channel=0;channel<3;++channel)
                            check(std::abs(int(actual[channel])-std::min(255,int(std::lround(wanted[channel]*brightness))))<=1,
                                "Final Kitty colour/opacity differs from the bar (double tint or clipped intermediate)");
                    }
                    check(pixel(X+13,Y+HEIGHT/2)==Pixel{230,191,91,255},"Following the bar changes an opaque glyph");
                    check(pixel(X,Y)[3]==0,"Following the bar loses native rounded corners");
                }
            }
            glDeleteFramebuffers(1,&opticalFB);glDeleteFramebuffers(1,&referenceFB);
            glDeleteTextures(1,&opticalTexture);glDeleteTextures(1,&referenceTexture);
            glDeleteProgram(shared);
        }

        // Optional review artifact: render the exact optics and real client
        // shader at desktop size, from externally supplied fixture pixels.
        // This is offline test output, never a production capture/overlay.
        if (const char* directory=std::getenv("VELORA_TERMINAL_GLASS_PREVIEW")) {
            const std::filesystem::path preview{directory};
            W=1200;H=800;X=160;Y=100;WIDTH=880;HEIGHT=600;
            auto input = [&](const char* name,int width,int height) {
                std::vector<Pixel> data(width*height);
                std::ifstream file(preview/name,std::ios::binary);
                file.read(reinterpret_cast<char*>(data.data()),data.size()*sizeof(Pixel));
                check(file.gcount()==static_cast<std::streamsize>(data.size()*sizeof(Pixel)),
                    "Incomplete preview input");
                return data;
            };
            const auto scene=input("scene.rgba",W,H);
            const auto frost=input("blur.rgba",W,H);
            const auto text=input("client.rgba",WIDTH,HEIGHT);
            opticalSource=texture(W,H,scene.data(),GL_RGBA,GL_UNSIGNED_BYTE,GL_LINEAR);
            background=texture(W,H,frost.data(),GL_RGBA,GL_UNSIGNED_BYTE,GL_LINEAR);
            foreground=texture(WIDTH,HEIGHT,text.data());
            lensTexture=texture(W,H);lensFB=target(lensTexture);
            resultTexture=texture(W,H);resultFB=target(resultTexture);
            glViewport(0,0,W,H);
            drawClient(background,1);
            savePreview(preview/"blur.ppm",resultFB,scene);
            drawGlass(lensFB,1);
            drawClient(lensTexture,1);
            savePreview(preview/"liquid-default.ppm",resultFB,scene);
            drawGlass(lensFB,3);
            drawClient(lensTexture,1);
            savePreview(preview/"liquid-maximum.ppm",resultFB,scene);
            if (std::filesystem::exists(preview/"previous.frag")) {
                glass=program(vertex,read((preview/"previous.frag").c_str()));
                refractionPixels=28;rimWidth=56;
                drawGlass(lensFB,1);
                drawClient(lensTexture,1);
                savePreview(preview/"previous.ppm",resultFB,scene);
            }
            check(glGetError()==GL_NO_ERROR,"OpenGL error in preview");
        }
        eglMakeCurrent(display, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
        eglDestroySurface(display, surface);
        eglDestroyContext(display, context);
        eglTerminate(display);
        return 0;
    } catch (const std::exception& error) {
        std::cerr << error.what() << '\n';
        return 1;
    }
}
