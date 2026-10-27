#include "../../native/hyprland/TerminalGlass.hpp"
#include "../../native/hyprland/BarRefraction.hpp"
#include "../../native/hyprland/LyricsBeat.hpp"
#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <GLES3/gl3.h>
#include <algorithm>
#include <array>
#include <cmath>
#include <cstdlib>
#include <fstream>
#include <iostream>
#include <iterator>
#include <stdexcept>
#include <string>
#include <vector>

constexpr int WIDTH = 400, HEIGHT = 300;

GLuint compile(GLenum type, const std::string& source) {
    GLuint shader = glCreateShader(type);
    const char* text = source.c_str();
    glShaderSource(shader, 1, &text, nullptr);
    glCompileShader(shader);
    GLint success;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &success);
    if (!success) {
        char message[4096];
        glGetShaderInfoLog(shader, sizeof(message), nullptr, message);
        throw std::runtime_error(message);
    }
    return shader;
}

int main(int argc, char** argv) {
    try {
        if (argc != 4) return 2;
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
        const EGLint surfaceAttributes[] = {EGL_WIDTH, WIDTH, EGL_HEIGHT, HEIGHT, EGL_NONE};
        EGLSurface surface = eglCreatePbufferSurface(display, config, surfaceAttributes);
        if (!eglMakeCurrent(display, surface, surface, context)) return 77;

        GLuint program = glCreateProgram();
        std::string vertexSource, fragmentSource;
        for (int index = 1; index <= 2; ++index) {
            std::ifstream file(argv[index]);
            std::string source{std::istreambuf_iterator<char>(file), std::istreambuf_iterator<char>()};
            (index == 1 ? vertexSource : fragmentSource) = source;
            glAttachShader(program, compile(index == 1 ? GL_VERTEX_SHADER : GL_FRAGMENT_SHADER, withTerminalGlassOptics(source)));
        }
        glLinkProgram(program);
        GLint linked;
        glGetProgramiv(program, GL_LINK_STATUS, &linked);
        if (!linked) throw std::runtime_error("Bar shader did not link");
        glUseProgram(program);

        GLuint vao, buffer, texture;
        glGenVertexArrays(1, &vao);
        glBindVertexArray(vao);
        glGenBuffers(1, &buffer);
        glBindBuffer(GL_ARRAY_BUFFER, buffer);
        const float vertices[] = {-1,1,0,0, -1,-1,0,1, 1,1,1,0, 1,-1,1,1};
        glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
        for (auto [name, offset] : {std::pair{"pos", 0}, std::pair{"texcoord", 2}}) {
            GLint location = glGetAttribLocation(program, name);
            glEnableVertexAttribArray(location);
            glVertexAttribPointer(location, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(float), reinterpret_cast<void*>(offset * sizeof(float)));
        }
        glGenTextures(1, &texture);
        glBindTexture(GL_TEXTURE_2D, texture);
        const unsigned char background[] = {96, 128, 160, 255};
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 1, 1, 0, GL_RGBA, GL_UNSIGNED_BYTE, background);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        auto one = [&](const char* name, float value) { glUniform1f(glGetUniformLocation(program,name),value); };
        auto two = [&](const char* name, float x, float y) { glUniform2f(glGetUniformLocation(program,name),x,y); };
        auto four = [&](const char* name, float x, float y, float z, float w) { glUniform4f(glGetUniformLocation(program,name),x,y,z,w); };
        for (int i=0; i<LYRICS_BEAT_SLOTS*2; ++i) {
            const std::string name="musicColors["+std::to_string(i)+"]";
            glUniform3f(glGetUniformLocation(program,name.c_str()),.25F,.5F,.93F);
        }
        const float identity[] = {1,0,0, 0,1,0, 0,0,1};
        glUniformMatrix3fv(glGetUniformLocation(program,"proj"),1,GL_FALSE,identity);
        two("fullSize",WIDTH,HEIGHT);
        two("windowTopLeft",0,0);
        two("windowBottomRight",1,1);
        four("frameInterior",40,30,420,252);
        one("frameRadius",20);
        four("barTint",0.1,0.12,0.15,0.3);
        one("radius",18);
        one("radiusOuter",8);
        one("alpha",1);
        one("barBrightness",1);
        std::array<float,96> bands;
        bands.fill(0.6);
        glUniform1fv(glGetUniformLocation(program,"barBands"),96,bands.data());
        auto draw = [&] { glClearColor(0,0,0,0); glClear(GL_COLOR_BUFFER_BIT); glDrawArrays(GL_TRIANGLE_STRIP,0,4); };
        auto alpha = [&](int x, int y) {
            unsigned char pixel[4];
            glReadPixels(x,HEIGHT-y-1,1,1,GL_RGBA,GL_UNSIGNED_BYTE,pixel);
            return pixel[3];
        };
        auto check = [&](bool value, const char* message) { if (!value) throw std::runtime_error(message); };
        const float joinedLiquid = std::getenv("VELORA_TEST_OPTICAL_JOINS") ? 3.F : 2.F;
        one("opticalScale",1);
        for (const auto text : {"", "-1", "10.1", "nan", "inf", "1 2", "1garbage"})
            check(!parseBarRefraction(text), "Invalid bar refraction control accepted");
        check(parseBarRefraction("0") == 0.F && parseBarRefraction("10") == 10.F
            && parseBarRefraction("4.5 ") == 4.5F, "Valid bar refraction control rejected");
        for (const auto text : {"", "eDP-1 reset extra", "eDP-1 nan 0 1", "eDP-1 0 0 2",
                "eDP-1 -1 0 .5", "eDP-1 .5 .5 inf", "eDP-1 .5garbage .5 .5"})
            check(!parseLyricsBeat(text), "Invalid Lyrics beat command accepted");
        check(parseLyricsBeat("eDP-1 reset")->reset && parseLyricsBeat("eDP-1 .9 .4 .7")->strength==.7F,
            "Valid Lyrics beat command rejected");
        check(parseLyricsBeat("eDP-1 .9 .4 .7 1 0 0 0 1 0")->colors[4]==1.F,
            "Album colors were lost in the beat command");
        check(!parseLyricsBeat("eDP-1 .9 .4 .7 1 0 nan 0 1 0")
            && !parseLyricsBeat("eDP-1 .9 .4 .7 1 0 0 0 2 0"),"Invalid album palette accepted");

        four("barMaterial",1,1,1,0);
        one("thick",3);
        two("topLeft",0,-135);
        two("bottomRight",200,15);
        two("uvOffset",0,-75);
        two("uvSize",55,35);
        four("pointer_shape",0,30,0,1);
        draw();
        check(alpha(200,75)>250,"Attached notification lost its material");
        check(alpha(200,32)>250,"Notification connection lost its material");
        check(alpha(200,140)==0,"Top panel paints outside its shape");
        check(alpha(200,220)==0,"Wave was drawn above application windows");
        four("statusPanel",110,-70,45,26);
        four("statusMetrics",110,25,18,8);
        draw();
        check(alpha(200,75)>250,"Open menu lost its material when notified");
        check(alpha(310,80)>250,"Notification lost its material beside an open menu");
        four("chargingPanel",-110,-70,55,38);
        four("chargingMetrics",-110,34,28,8);
        draw();
        check(alpha(90,80)>250,"Charging morph lost the shared bar material");
        check(alpha(90,36)>250,"Charging morph has a gap below the battery");
        check(alpha(90,140)==0,"Charging material escapes its contour");
        check(alpha(200,75)>250 && alpha(310,80)>250,
            "Charging must coexist with an open menu and a notification");
        std::array<unsigned char,4> barPixel{};
        glReadPixels(90,HEIGHT-15-1,1,1,GL_RGBA,GL_UNSIGNED_BYTE,barPixel.data());
        for (int y=24;y<105;++y) {
            std::array<unsigned char,4> pixel{};
            glReadPixels(90,HEIGHT-y-1,1,1,GL_RGBA,GL_UNSIGNED_BYTE,pixel.data());
            check(pixel==barPixel,"Charging/bar join changes color or opacity");
        }
        auto pixelAt = [&](int x, int y) {
            std::array<unsigned char,4> pixel{};
            glReadPixels(x,HEIGHT-y-1,1,1,GL_RGBA,GL_UNSIGNED_BYTE,pixel.data());
            return pixel;
        };
        auto chargeDifference = [](const auto& a, const auto& b) {
            return std::abs(int(a[0])-int(b[0])) + std::abs(int(a[1])-int(b[1]))
                + std::abs(int(a[2])-int(b[2]));
        };
        const auto unlit = pixelAt(210,15);
        for (float gain : {.2F,.55F,1.2F}) {
            one("barBrightness",gain);
            draw();
            const auto dimmed=pixelAt(210,15);
            check(dimmed[3]==unlit[3],"Bar brightness changes material coverage/opacity");
            for (int channel=0;channel<3;++channel)
                check(std::abs(int(dimmed[channel])-std::min(255,int(std::lround(unlit[channel]*gain))))<=1,
                    "Bar brightness does not scale the actual material");
        }
        one("barBrightness",1);
        draw();
        check(pixelAt(210,15)==unlit,"Resetting bar brightness does not restore the exact material");
        four("chargingLight",90,30,0.3,0.55);
        draw();
        const auto lit = pixelAt(210,15);
        check(chargeDifference(lit,unlit)>12,"Charging color does not spread along the existing topbar");
        check(lit[3]==unlit[3],"Charging gradient adds a second layer of opacity");
        check(alpha(90,140)==0,"Charging color leaks outside the unified surface");
        four("chargingLight",90,30,0.3,0.1);
        draw();
        check(chargeDifference(pixelAt(210,15),unlit)<chargeDifference(lit,unlit),
            "Charging color does not dissipate as its intensity drops");
        four("chargingLight",90,30,1,0);
        draw();
        check(pixelAt(210,15)==unlit,"Charging color does not restore the original bar composition");
        four("chargingPanel",0,0,0,0);
        four("chargingLight",90,30,0.3,0.55);
        draw();
        check(chargeDifference(pixelAt(210,15),unlit)>12,
            "Suppressing the charging body also removed the topbar gradient");
        check(alpha(90,80)==0,"Suppressed charging body remains behind the side panel");
        four("chargingLight",0,0,1,0);
        four("statusPanel",0,0,0,0);
        draw();
        const auto timerUnlit=pixelAt(210,15);
        four("timerLight",90,30,0.3,0.62);
        draw();
        const auto timerLit=pixelAt(210,15);
        check(timerLit[0]>timerUnlit[0] && timerLit[1]<timerUnlit[1],
            "Timer completion does not pulse red inside the bar material");
        check(timerLit[3]==timerUnlit[3],"Timer pulse changes bar transparency");
        four("timerPanel",-82,-74,110,26);
        four("timerMetrics",-110,48,18,14);
        four("statusPanel",110,-70,45,26);
        four("statusMetrics",110,25,18,8);
        draw();
        check(alpha(90,42)>250 && alpha(90,76)>250,
            "Timer alert has a gap between the clock and its action morph");
        check(alpha(90,125)==0,"Timer alert material exceeds its compact contour");
        check(alpha(310,80)>250,"Timer alert removed an independent notification");
        four("chargingLight",90,30,0.3,0.55);
        draw();
        check(chargeDifference(pixelAt(210,15),timerLit)>2,
            "Timer and charging light fields cannot coexist");
        four("chargingLight",0,0,1,0);
        four("timerLight",0,0,0,0);
        four("statusPanel",0,0,0,0);
        four("timerPanel",0,0,0,0);
        draw();
        check(pixelAt(210,15)==timerUnlit,"Dismissing timer alert does not restore the bar material");
        four("musicLights[0]",90,30,.3,.55);
        for (const auto name : {"musicColors[0]","musicColors[1]"})
            glUniform3f(glGetUniformLocation(program,name),1,0,0);
        draw(); const auto redAlbum=pixelAt(210,15);
        for (const auto name : {"musicColors[0]","musicColors[1]"})
            glUniform3f(glGetUniformLocation(program,name),0,1,0);
        draw(); const auto greenAlbum=pixelAt(210,15);
        check(redAlbum[0]>greenAlbum[0] && greenAlbum[1]>redAlbum[1],
            "Music gradient ignores the actual album palette");
        check(redAlbum[3]==timerUnlit[3] && greenAlbum[3]==timerUnlit[3],
            "Album-based gradient changes the bar opacity");
        four("musicLights[0]",0,0,0,0);
        for (const auto name : {"musicColors[0]","musicColors[1]"})
            glUniform3f(glGetUniformLocation(program,name),.25F,.5F,.93F);

        one("thick",4);
        two("topLeft",-200,0);
        two("bottomRight",40,180);
        two("uvOffset",-142,-10);
        two("uvSize",30,65);
        four("sideLabel",-100,-10,20,35);
        four("pointer_shape",1,0,132,1);
        one("radiusOuter",12);
        draw();
        check(alpha(60,140)>250,"Volume slider lost its enclosing material");
        check(alpha(100,140)>250,"Volume label lost its enclosing material");
        check(alpha(160,140)==0,"Sidebar paints outside its shape");
        check(alpha(200,220)==0,"Sidebar puts the wave above windows");
        check(alpha(200,290)==0,"Upper sidebar duplicates the desktop bottom frame");

        four("barMaterial",2,1,1,WIDTH);
        draw();
        check(alpha(20,140)==0,"Desktop wave duplicates the sidebar tint");
        check(alpha(60,140)==0,"Desktop wave duplicates the attached controls");
        check(alpha(200,290)>250,"Desktop wave does not own the bottom frame");
        check(alpha(200,130)==0,"Desktop wave exceeds its amplitude");
        // Check the unobstructed span, including the former frame/wave join.
        for (int x=65;x<WIDTH-12;++x) {
            check(alpha(x,220)>250,"Continuous wave contains a column gap");
            check(alpha(x,280)>250,"Continuous wave leaves a gap at its base");
            // Scan across the former cut, not just two pixels above it. The
            // material and its coverage must stay identical through the base.
            std::array<unsigned char,4> previous{};
            for (int y=278;y<HEIGHT;++y) {
                std::array<unsigned char,4> pixel{};
                glReadPixels(x,HEIGHT-y-1,1,1,GL_RGBA,GL_UNSIGNED_BYTE,pixel.data());
                check(pixel[3]>250,"Frame/wave join contains a transparent seam");
                if (y>278) check(pixel==previous,"Frame/wave join changes tint or coverage");
                previous=pixel;
            }
        }
        // Turning the analyzer off must leave the same bottom frame mounted.
        four("barMaterial",2,1,1,0);
        draw();
        check(alpha(200,290)>250,"Disabling the spectrum removes the bottom frame");
        check(alpha(200,220)==0,"Disabled spectrum still draws a wave");
        check(alpha(20,140)==0,"Disabled spectrum duplicates the upper sidebar");
        // The moving bottom must be an actual contour, with no old strips
        // below it. Exercise both passes and reversed intermediate poses.
        for (float progress : {0.25F,0.5F,0.75F,1.F,0.75F,0.5F,0.25F,0.F}) {
            float remaining = 1-progress;
            float railRemaining = std::min(1.F,remaining/.22F);
            float rise = std::clamp((progress-.35F)/.65F,0.F,1.F);
            float limit = 30 + 270*(1-rise);
            four("frameInterior",40*railRemaining,30,WIDTH-44*railRemaining,std::max(.01F,270*(1-rise)-18*railRemaining));
            one("frameRadius",20*(1-rise));
            two("frameFold",progress,limit);
            for (float pass : {1.F,2.F}) {
                four("barMaterial",pass,1,1,0);
                draw();
                if (progress>0) {
                    check(alpha(200,290)==0,"Fold leaves the old bottom frame on screen");
                    if (progress>.35) {
                        check(alpha(2,290)==0,"Fold leaves the old sidebar below its moving corners");
                        check(alpha(398,290)==0,"Fold leaves the opposite frame below its moving corners");
                    }
                }
                if (remaining>.01 && pass==2.F)
                    check(alpha(2,std::lround(limit-3))>250,"Bottom frame loses its moving corner");
                if (progress>0 && progress<1)
                    check(alpha(200,std::lround(limit-3))==0,"Bottom frame crosses the middle instead of rising along its corners");
                if (remaining>.01 && pass==1.F)
                    check(alpha(2,std::lround(30+100*(1-rise)))>250,"Side frame disappears during morph");
                if (progress==1.F)
                    check(alpha(200,80)==0 && alpha(2,80)==0,"Folded frame still covers the canvas");
            }
            if (progress==1.F) {
                one("thick",3);
                four("barMaterial",1,1,1,0);
                two("topLeft",0,-135);
                two("bottomRight",200,15);
                two("uvSize",0,0);
                draw();
                check(alpha(200,15)>250,"Infinite Desktop removes the existing topbar");
                check(alpha(200,80)==0,"Folded topbar adds a second surface below the strip");
                one("thick",4);
                two("topLeft",-200,0);
                two("bottomRight",40,180);
                two("uvSize",30,65);
            }
        }
        two("frameFold",0,0);
        four("frameInterior",40,30,420,252);
        one("frameRadius",20);
        // A bass-heavy input previously raised only the left side. Each half
        // must now receive the same beat response, without raising silence.
        two("uvSize",0,0);
        four("sideLabel",0,0,0,0);
        bands.fill(0.05);
        for (int index=0;index<32;++index) bands[index]=0.6;
        glUniform1fv(glGetUniformLocation(program,"barBands"),96,bands.data());
        four("barMaterial",2,1,1,WIDTH);
        draw();
        check(alpha(80,220)>250,"Bass no longer raises the left side");
        check(alpha(320,220)>250,"Bass does not raise the right side equally");
        for (int x=65;x<WIDTH/2;++x)
            for (int y=175;y<282;++y)
                check(std::abs(int(alpha(x,y))-int(alpha(WIDTH-x-1,y)))<=1,
                    "Left/right beat response is unbalanced");
        bands.fill(0);
        glUniform1fv(glGetUniformLocation(program,"barBands"),96,bands.data());
        draw();
        check(alpha(80,220)==0 && alpha(320,220)==0,"Balanced wave moves in silence");
        // Settings and the bottom frame share one SDF and material. Sample
        // actual shader output across the old seam, with spectrum disabled.
        four("barMaterial",2,1,1,0);
        four("bottomPanel",200,225,110,95);
        two("bottomMetrics",18,32);
        draw();
        check(alpha(200,145)>250,"Connected Settings body is missing");
        check(alpha(88,278)>250,"Settings lost the concave bottom connection");
        check(alpha(75,200)==0,"Settings material escapes its side boundary");
        check(alpha(20,275)==0,"Connected Settings cover the sidebar avatar");
        std::array<unsigned char,4> seamReference{};
        glReadPixels(200,HEIGHT-260-1,1,1,GL_RGBA,GL_UNSIGNED_BYTE,seamReference.data());
        for (int y=261;y<HEIGHT;++y) {
            std::array<unsigned char,4> pixel{};
            glReadPixels(200,HEIGHT-y-1,1,1,GL_RGBA,GL_UNSIGNED_BYTE,pixel.data());
            check(pixel==seamReference,"Settings/base join changes tint or coverage");
        }
        four("barMaterial",1,1,1,0);
        draw();
        check(alpha(200,290)==0 && alpha(200,200)==0,"Upper host duplicates connected Settings");
        four("barMaterial",2,1,1,0);
        four("bottomPanel",0,0,0,0);
        draw();
        check(alpha(200,200)==0 && alpha(200,290)>250,"Closing Settings does not restore the bare frame");
        // Tall right panels are partitioned between upper/bottom material
        // passes, with exactly one opaque owner on every row.
        four("frameInterior",40,30,356,252);
        four("oppositePanel",336,165,60,135);
        one("oppositeContour",1);
        const std::array<float,21> curve{0,.058,.089,.066,.016,0,.05,.074,.042,.005,.008,.079,.071,.008,0,.055,.074,.024,.005,.029,.063};
        glUniform1fv(glGetUniformLocation(program,"oppositeCurve"),21,curve.data());
        std::array<int,HEIGHT> upper{};
        four("barMaterial",1,1,1,0);
        one("thick",4);
        draw();
        for(int y=30;y<HEIGHT;++y) upper[y]=alpha(345,y);
        check(alpha(280,95)>alpha(280,57),"Right panel lost the reference waves");
        four("barMaterial",2,1,1,0);
        draw();
        for(int y=30;y<HEIGHT;++y)
            check(upper[y]+alpha(345,y)==255,"Right panel has a gap or double material at the bottom join");
        // Spotify/Lyrics/WhatsApp share the topbar's color field even though
        // their host begins below it. Compare real shader pixels across that
        // offset and across the upper/bottom material ownership boundary.
        auto chargingColumn = [&] {
            std::array<std::array<unsigned char,4>,HEIGHT> pixels{};
            for (int y=0;y<HEIGHT;++y) pixels[y]=pixelAt(345,y);
            return pixels;
        };
        two("uvSize",0,0);
        four("sideLabel",0,0,0,0);
        for (int style=0;style<3;++style) for (int effect=0;effect<4;++effect) {
            auto panelCurve=curve;
            for (auto& value:panelCurve) value*=style==0 ? 0.F : style==1 ? 1.F : 1.4F;
            one("oppositeContour",style==0 ? 0 : style);
            glUniform1fv(glGetUniformLocation(program,"oppositeCurve"),21,panelCurve.data());
            one("thick",3);
            four("barMaterial",1,1,1,0);
            four("chargingLight",0,0,1,0);
            four("timerLight",0,0,0,0);
            four("musicLights[0]",0,0,0,0);
            four("musicLights[1]",0,0,0,0);
            draw();
            const auto plainDeep=pixelAt(345,240);
            if (effect==0 || effect==2) four("chargingLight",345,30,0.4,0.55);
            if (effect==1 || effect==2) four("timerLight",345,30,0.4,0.62);
            if (effect==3) four("musicLights[0]",345,140,0.4,0.55);
            draw();
            const auto referenceUpper=chargingColumn();
            if (effect==3) {
                four("musicLights[1]",345,140,0.4,0.55); draw();
                check(chargingColumn()==referenceUpper,"Overlapping percussion waves accumulate excess brightness");
            }
            check(chargeDifference(referenceUpper[240],plainDeep)>8,
                "Bar light does not travel down into the panel body");
            four("barMaterial",2,1,1,0);
            draw();
            const auto referenceBottom=chargingColumn();
            // The actual side host excludes the topbar's first 30 pixels.
            glViewport(0,0,WIDTH,HEIGHT-30);
            two("windowTopLeft",0,30.F/HEIGHT);
            one("thick",4);
            four("barMaterial",1,1,1,0);
            draw();
            const auto sideUpper=chargingColumn();
            four("barMaterial",2,1,1,0);
            draw();
            const auto sideBottom=chargingColumn();
            for (int y=30;y<HEIGHT;++y) {
                const auto& expected=referenceUpper[y][3] ? referenceUpper[y] : referenceBottom[y];
                const auto& actual=sideUpper[y][3] ? sideUpper[y] : sideBottom[y];
                check(int(sideUpper[y][3])+int(sideBottom[y][3])==255,
                    "Bar light changes ownership or opacity at the panel join");
                for (int channel=0;channel<4;++channel)
                    check(std::abs(int(actual[channel])-int(expected[channel]))<=1,
                        "Bar light breaks between topbar, side panel and bottom passes");
            }
            glViewport(0,0,WIDTH,HEIGHT);
            two("windowTopLeft",0,0);
        }
        four("chargingLight",0,0,1,0);
        four("timerLight",0,0,0,0);
        four("musicLights[0]",0,0,0,0);
        four("musicLights[1]",0,0,0,0);
        one("oppositeContour",1);
        glUniform1fv(glGetUniformLocation(program,"oppositeCurve"),21,curve.data());
        // The left rail consumes the same contour, with one material owner.
        two("uvSize",0,0);
        four("sideLabel",0,0,0,0);
        std::array<float,21> strongCurve;
        strongCurve.fill(.25F);
        glUniform1fv(glGetUniformLocation(program,"oppositeCurve"),21,strongCurve.data());
        glUniform1fv(glGetUniformLocation(program,"sideCurve"),21,strongCurve.data());
        one("sideWaveScale",.55F);
        one("sideWaveWidth",66);
        one("waveDockProgress",1);
        four("barMaterial",1,1,1,0);
        draw();
        check(alpha(50,150)>250 && alpha(65,150)==0,"Left wave missing or exceeds shared contour");
        for(int y=30;y<HEIGHT;++y) upper[y]=alpha(50,y);
        four("barMaterial",2,1,1,0);
        draw();
        for(int y=30;y<HEIGHT;++y)
            check(upper[y]+alpha(50,y)==255,"Left wave has a gap or double material at the bottom join");
        one("sideWaveScale",0);
        one("waveDockProgress",0);
        four("barMaterial",1,1,1,0);
        draw();
        check(alpha(50,150)==0,"Left wave remains after closing Spotify");
        // The lower wave retracts toward the left while the rail rises.
        bands.fill(.6);
        glUniform1fv(glGetUniformLocation(program,"barBands"),96,bands.data());
        four("barMaterial",2,1,1,WIDTH);
        draw();
        check(alpha(200,220)>250,"Bottom wave did not return after undocking");
        one("waveDockProgress",.5F);
        draw();
        check(alpha(200,220)==0 && alpha(80,260)>250,"Bottom wave does not retract progressively");
        one("waveDockProgress",1);
        draw();
        check(alpha(80,260)==0 && alpha(200,290)>250,"Docking hides the base or leaves lower peaks");
        one("waveDockProgress",0);
        four("oppositePanel",376,150,20,82);
        one("oppositeContour",0);
        const std::array<float,21> flat{};
        glUniform1fv(glGetUniformLocation(program,"oppositeCurve"),21,flat.data());
        four("oppositeLabel",326,98,30,22);
        four("barMaterial",1,1,1,0);
        draw();
        check(alpha(320,98)>250 && alpha(320,155)==0,"Lyrics extension escapes its row");
        four("oppositeLabel",0,0,0,0);
        four("oppositePanel",0,0,0,0);
        draw();
        check(alpha(320,98)==0,"Closing right panel leaves material behind");

        // The toolbox is an expansion of the top-left corner. Both upper
        // hosts must evaluate its full contour and own each pixel once;
        // the old sidebar distance field left a refracted line at x=40.
        four("frameInterior",40,30,356,252);
        four("frameTopPanel",140,105,140,75);
        four("frameTopMetrics",45,0,18,8);
        two("uvOffset",-60,-45); two("uvSize",140,75);
        two("topLeft",0,-135); two("bottomRight",200,15);
        four("pointer_shape",-155,0,0,1);
        four("pointer_position",0,0,0,1);
        four("color",0,0,0,0);
        one("brightness",1); one("contrast",16); one("distort",4);
        one("barRefractionStrength",4.6F);
        four("barMaterial",1,joinedLiquid,1,0); one("thick",3); draw();
        std::vector<std::array<unsigned char,4>> cornerTop(WIDTH*HEIGHT), cornerSide(WIDTH*HEIGHT);
        glReadPixels(0,0,WIDTH,HEIGHT,GL_RGBA,GL_UNSIGNED_BYTE,cornerTop.data());
        one("thick",4); two("uvSize",0,0);
        four("pointer_shape",1,0,132,1); draw();
        glReadPixels(0,0,WIDTH,HEIGHT,GL_RGBA,GL_UNSIGNED_BYTE,cornerSide.data());
        for(int y=65;y<145;++y) for(int x=32;x<90;++x) {
            const int i=(HEIGHT-y-1)*WIDTH+x;
            check(int(cornerTop[i][3])+cornerSide[i][3]==255,
                "Toolbox/rail join has a gap or duplicate material");
            const auto& value=cornerTop[i][3] ? cornerTop[i] : cornerSide[i];
            const auto& center=cornerTop[(HEIGHT-y-1)*WIDTH+140];
            for(int channel=0;channel<3 && joinedLiquid==2;++channel)
                check(std::abs(int(value[channel])-int(center[channel]))<=2,
                    "Toolbox retains the old rail optical rim through its body");
        }
        if(joinedLiquid==3) for(int y=75;y<135;++y) for(int channel=0;channel<3;++channel) {
            // A thick optical rim shades the actual outer boundary broadly.
            // At the obsolete x=40 rail edge, the material must stay smooth.
            auto colorAt=[&](int x) { double sum=0;
                for(int row=y-2;row<=y+2;++row) { const int i=(HEIGHT-row-1)*WIDTH+x;
                    sum+=cornerTop[i][3] ? cornerTop[i][channel] : cornerSide[i][channel]; }
                return sum/5; };
            check(std::abs(colorAt(39)-2*colorAt(40)+colorAt(41))<=2,
                "New glass has an optical line at the old toolbox/rail boundary");
        }
        four("frameTopPanel",0,0,0,0);
        four("frameTopMetrics",0,0,0,0);
        draw();
        check(alpha(60,95)==0,"Closing the toolbox leaves its shared material behind");

        // A tall lower wave must reach the rail and an open right panel.
        // Inspect both coverage and real liquid colour: an opaque pixel can
        // still refract/light an obsolete edge inside the merged surface.
        bands.fill(.9F);
        glUniform1fv(glGetUniformLocation(program,"barBands"),96,bands.data());
        four("frameInterior",40,30,356,252);
        four("oppositePanel",336,165,60,135);
        one("oppositeContour",0);
        two("uvSize",0,0);
        four("sideLabel",0,0,0,0);
        four("pointer_position",0,0,0,1);
        four("pointer_shape",1,0,132,1);
        four("color",0,0,0,0);
        one("brightness",1); one("contrast",16); one("distort",4);
        one("barRefractionStrength",4.6F);
        auto pixels = [&] {
            std::vector<std::array<unsigned char,4>> result(WIDTH*HEIGHT);
            glReadPixels(0,0,WIDTH,HEIGHT,GL_RGBA,GL_UNSIGNED_BYTE,result.data());
            return result;
        };
        four("barMaterial",1,joinedLiquid,1,WIDTH); draw(); const auto highUpper=pixels();
        four("barMaterial",2,joinedLiquid,1,WIDTH); draw(); const auto highLower=pixels();
        for (int y=165;y<250;++y) for (int x=8;x<WIDTH-8;++x) {
            const int i=(HEIGHT-y-1)*WIDTH+x;
            check(int(highUpper[i][3])+highLower[i][3]==255,
                "High wave has a hole or duplicate coverage beside a rail/menu");
            const auto& value=highUpper[i][3] ? highUpper[i] : highLower[i];
            const auto& center=highLower[(HEIGHT-y-1)*WIDTH+180];
            for(int channel=0;channel<3 && joinedLiquid==2;++channel)
                check(std::abs(int(value[channel])-int(center[channel]))<=2,
                    "High wave retains an internal liquid rim at a rail/menu join");
        }
        if(joinedLiquid==3) for(int y=200;y<240;++y) for(int seam : {40,276}) for(int channel=0;channel<3;++channel) {
            auto colorAt=[&](int x) { double sum=0;
                for(int row=y-2;row<=y+2;++row) { const int i=(HEIGHT-row-1)*WIDTH+x;
                    sum+=highUpper[i][3] ? highUpper[i][channel] : highLower[i][channel]; }
                return sum/5; };
            check(std::abs(colorAt(seam-1)-2*colorAt(seam)+colorAt(seam+1))<=2,
                "New glass has an optical line at the old rail/wave boundary");
        }
        // Real hosts snapshot at different layer depths. The upper snapshot
        // can already contain the shaded desktop wave. Deliberately supply
        // different sources to catch the optical rectangle at the bottom cut.
        GLuint upperTexture;
        glGenTextures(1,&upperTexture);
        glActiveTexture(GL_TEXTURE0); glBindTexture(GL_TEXTURE_2D,upperTexture);
        const unsigned char upperBackground[] = {180,32,65,255};
        glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA,1,1,0,GL_RGBA,GL_UNSIGNED_BYTE,upperBackground);
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST);
        for (int unit : {2,3}) { glActiveTexture(GL_TEXTURE0+unit); glBindTexture(GL_TEXTURE_2D,texture); }
        glUniform1i(glGetUniformLocation(program,"frameBackdrop"),2);
        glUniform1i(glGetUniformLocation(program,"frameBlur"),3);
        glActiveTexture(GL_TEXTURE0);
        four("barMaterial",1,joinedLiquid,1,WIDTH); one("frameFusion",1); draw(); const auto fusedUpper=pixels();
        for (int y=165;y<250;++y) for (int x : {20,40,41,278,300,345}) {
            const int i=(HEIGHT-y-1)*WIDTH+x;
            if (!fusedUpper[i][3]) continue;
            for (int channel=0;channel<3;++channel)
                check(std::abs(int(fusedUpper[i][channel])-int(joinedLiquid==3 ? highUpper[i][channel] : highLower[(HEIGHT-y-1)*WIDTH+180][channel]))<=2,
                    "Frame/wave join shades two different backdrop snapshots");
        }
        check(fusedUpper[(HEIGHT-70-1)*WIDTH+20][0]>highUpper[(HEIGHT-70-1)*WIDTH+20][0]+20,
            "Fusion replaced the live panel backdrop away from its lower join");
        // Exercise the actual upper raster fringe, not only an infinite quad.
        // The old 40 px scissor omitted the owned antialias column at x=40.
        glEnable(GL_SCISSOR_TEST); glScissor(0,0,42,HEIGHT); draw();
        check(alpha(40,200)==255,"Raster clips the shared rail/wave antialias fringe");
        glDisable(GL_SCISSOR_TEST);
        // Silence must restore the original contour, rather than making the
        // join appear seamless by raising a permanent minimum wave height.
        bands.fill(0);
        glUniform1fv(glGetUniformLocation(program,"barBands"),96,bands.data());
        one("frameFusion",1); four("barMaterial",1,2,1,0); draw();
        const auto quietUpper=pixels();
        glActiveTexture(GL_TEXTURE0); glBindTexture(GL_TEXTURE_2D,texture);
        one("frameFusion",0);
        four("barMaterial",2,2,1,WIDTH); draw();
        const auto quietLower=pixels();
        for(int channel=0;channel<3;++channel)
            check(std::abs(int(quietUpper[(HEIGHT-258-1)*WIDTH+20][channel])
                -int(quietLower[(HEIGHT-261-1)*WIDTH+20][channel]))<=2,
                "Bottom ownership cut leaves a horizontal backdrop line in silence");
        check(alpha(180,165)==0,"Fusion raises the visualizer in silence");
        glDeleteTextures(1,&upperTexture);
        four("oppositePanel",0,0,0,0);
        check(glGetError()==GL_NO_ERROR,"OpenGL error while drawing the bar");
        // Matching bars use the exact Kitty optics, followed by the managed
        // Kitty background tint/opacity. Compare real shader output, including
        // strength zero/max, rather than checking only similarly named knobs.
        const GLuint barProgram=program;
        const float upright[] = {-1,-1,0,0, -1,1,0,1, 1,-1,1,0, 1,1,1,1};
        glBufferData(GL_ARRAY_BUFFER,sizeof(upright),upright,GL_STATIC_DRAW);
        std::vector<std::array<unsigned char,4>> sharp(WIDTH*HEIGHT);
        for (int y=0;y<HEIGHT;++y) for (int x=0;x<WIDTH;++x)
            sharp[y*WIDTH+x]={static_cast<unsigned char>(40+x*.4),static_cast<unsigned char>(24+y*.5),90,255};
        glActiveTexture(GL_TEXTURE0);glBindTexture(GL_TEXTURE_2D,texture);
        glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA,WIDTH,HEIGHT,0,GL_RGBA,GL_UNSIGNED_BYTE,sharp.data());
        GLuint blurTexture;glGenTextures(1,&blurTexture);
        glActiveTexture(GL_TEXTURE1);glBindTexture(GL_TEXTURE_2D,blurTexture);
        const unsigned char blurred[] = {48,50,75,255};
        glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA,1,1,0,GL_RGBA,GL_UNSIGNED_BYTE,blurred);
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST);
        GLuint kittyProgram=glCreateProgram();
        glAttachShader(kittyProgram,compile(GL_VERTEX_SHADER,vertexSource));
        glAttachShader(kittyProgram,compile(GL_FRAGMENT_SHADER,withTerminalGlassOptics(TERMINAL_GLASS_FRAGMENT)));
        glLinkProgram(kittyProgram);glGetProgramiv(kittyProgram,GL_LINK_STATUS,&linked);
        check(linked,"Kitty material did not link in bar comparison");
        auto use = [&](GLuint value) {
            program=value;glUseProgram(program);
            for(auto [name,offset] : {std::pair{"pos",0},std::pair{"texcoord",2}}) {
                const GLint location=glGetAttribLocation(program,name);
                glEnableVertexAttribArray(location);
                glVertexAttribPointer(location,2,GL_FLOAT,GL_FALSE,4*sizeof(float),reinterpret_cast<void*>(offset*sizeof(float)));
            }
            glUniformMatrix3fv(glGetUniformLocation(program,"proj"),1,GL_FALSE,identity);
            glUniform1i(glGetUniformLocation(program,"tex"),0);
            two("fullSize",WIDTH,HEIGHT);
        };
        auto sample = [&](int x,int y) {
            std::array<unsigned char,4> value;
            glReadPixels(x,y,1,1,GL_RGBA,GL_UNSIGNED_BYTE,value.data());
            return value;
        };
        const std::array<std::pair<int,int>,5> points={{{2,150},{100,150},{200,150},{200,2},{350,210}}};
        // Render the independent bar at the screenshot's 8% tint. The extra
        // range must actually move scene pixels on horizontal/vertical bars
        // and their attached Settings, not only update a numeric preference.
        use(barProgram);
        two("windowTopLeft",0,0);two("windowBottomRight",1,1);
        four("kittyMatch",0,0,0,0);four("barMaterial",1,2,0,0);
        four("barTint",.12F,.13F,.18F,.08F);
        four("pointer_position",0,0,0,1);four("pointer_shape",0,0,0,1);
        four("oppositePanel",0,0,0,0);four("oppositeLabel",0,0,0,0);
        four("bottomPanel",0,0,0,0);two("frost",0,0);two("frameFold",0,0);
        one("thick",0);one("frameRadius",0);one("radius",8);one("alpha",1);
        one("distort",4);one("contrast",16);one("noise",0);
        one("brightness",1);one("vibrancy",0);four("color",0,0,0,0);one("time",0);
        auto image = [&] {
            std::vector<std::array<unsigned char,4>> pixels(WIDTH*HEIGHT);
            glReadPixels(0,0,WIDTH,HEIGHT,GL_RGBA,GL_UNSIGNED_BYTE,pixels.data());
            return pixels;
        };
        auto difference = [&](const auto& a,const auto& b,const auto& probes) {
            float sum=0;
            for (const auto [x,y] : probes) for(int channel=0;channel<3;++channel)
                sum+=std::abs(int(a[y*WIDTH+x][channel])-int(b[y*WIDTH+x][channel]));
            return sum/(probes.size()*3);
        };
        struct LensCase { float x,y,w,h; std::array<std::pair<int,int>,3> probes; };
        const std::array<LensCase,3> lenses={{
            {0,-135,200,15,{{{60,15},{150,15},{300,15}}}},
            {-180,0,20,150,{{{20,50},{20,150},{20,250}}}},
            {0,0,170,120,{{{110,75},{270,210},{60,170}}}}
        }};
        for (const auto& shape : lenses) {
            two("topLeft",shape.x,shape.y);two("bottomRight",shape.w,shape.h);
            one("barRefractionStrength",0);draw();const auto zero=image();
            one("barRefractionStrength",1);draw();const auto normal=image();
            one("barRefractionStrength",5);draw();const auto medium=image();
            one("barRefractionStrength",10);draw();const auto strong=image();
            check(difference(normal,strong,shape.probes)>2.0F,"Independent bar refraction is imperceptible at 10x");
            check(difference(normal,strong,shape.probes)>difference(normal,medium,shape.probes)+.5F,
                "Bar strength saturates before its extended range");
            for (size_t pixel=0;pixel<zero.size();++pixel)
                check(zero[pixel][3]==strong[pixel][3],"Refraction changes the bar/frame silhouette");
        }
        // Simulate a compositor blur work buffer valid only around a tiny
        // damaged patch. Rays at 10x reach outside the old unpadded scissor.
        // Padding must match a complete backdrop without drawing more pixels.
        two("topLeft",0,0); two("bottomRight",190,140);
        const int patchX=310, patchY=205, patchSize=8;
        for (float gain : {1.F,6.2F,10.F}) {
            one("barRefractionStrength",gain);
            glActiveTexture(GL_TEXTURE0); glBindTexture(GL_TEXTURE_2D,texture);
            glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA,WIDTH,HEIGHT,0,GL_RGBA,GL_UNSIGNED_BYTE,sharp.data());
            draw(); const auto complete=image();
            const int padding=barRefractionSamplePadding(gain,WIDTH,4.44F);
            for (int margin : {0,padding}) {
                auto clipped=sharp;
                for (int y=0;y<HEIGHT;++y) for (int x=0;x<WIDTH;++x)
                    if (x<patchX-margin || x>=patchX+patchSize+margin
                            || y<patchY-margin || y>=patchY+patchSize+margin)
                        clipped[y*WIDTH+x]={0,0,0,0};
                glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA,WIDTH,HEIGHT,0,GL_RGBA,GL_UNSIGNED_BYTE,clipped.data());
                draw(); const auto partial=image();
                int changed=0;
                for (int y=patchY;y<patchY+patchSize;++y) for (int x=patchX;x<patchX+patchSize;++x)
                    changed += partial[y*WIDTH+x]!=complete[y*WIDTH+x];
                if (margin==padding) check(changed==0,"Strong refraction samples outside the prepared blur backdrop");
                else if (gain>1) check(changed>0,"Unpadded control failed to reproduce a black blur edge");
            }
        }
        glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA,WIDTH,HEIGHT,0,GL_RGBA,GL_UNSIGNED_BYTE,sharp.data());
        four("barMaterial",1,1,1,0);
        one("barRefractionStrength",0);draw();const auto glassZero=image();
        one("barRefractionStrength",10);draw();
        check(glassZero==image(),"Bar refraction changes the translucent material");
        // The second liquid is an independent optical model. Its geometry,
        // controls, and static grain must survive changes in the ray strength.
        four("barMaterial",1,3,0,0); one("opticalScale",1);
        two("topLeft",0,0);two("bottomRight",170,120);
        one("frameFusion",0);four("frameInterior",0,0,0,0);
        one("barRefractionStrength",1);draw();const auto opticalNormal=image();
        one("time",100);draw();
        check(image()==opticalNormal,"Optical glass shimmers when only time changes");
        one("barRefractionStrength",10);draw();const auto opticalStrong=image();
        check(difference(opticalNormal,opticalStrong,lenses[2].probes)>2,"Optical refraction strength does not move the backdrop");
        for (size_t pixel=0;pixel<opticalNormal.size();++pixel)
            check(opticalNormal[pixel][3]==opticalStrong[pixel][3],"New glass changes the surface silhouette");
        four("barMaterial",1,2,0,0);one("barRefractionStrength",1);draw();
        check(difference(image(),opticalNormal,lenses[2].probes)>2,"New glass still uses the legacy lens");
        four("barMaterial",1,3,0,0);one("barBrightness",.5F);draw();const auto opticalDim=image();
        for (const auto [x,y] : lenses[2].probes) for(int channel=0;channel<3;++channel)
            check(std::abs(int(opticalDim[y*WIDTH+x][channel])*2-int(opticalNormal[y*WIDTH+x][channel]))<=2,
                "New glass brightness does not scale its optical finish");
        one("barBrightness",1);two("frost",0,1);draw();
        check(difference(image(),opticalNormal,lenses[2].probes)>2,"Optical glass ignores the light colour scheme");
        two("frost",0,0);four("barMaterial",1,1,1,0);one("barRefractionStrength",10);
        // New rays also need a valid source halo after partial repainting.
        four("barMaterial",1,3,0,0);
        for(float gain : {1.F,6.2F,10.F}) {
            one("barRefractionStrength",gain);
            glBindTexture(GL_TEXTURE_2D,texture);
            glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA,WIDTH,HEIGHT,0,GL_RGBA,GL_UNSIGNED_BYTE,sharp.data());
            draw();const auto complete=image();
            const int margin=opticalGlassSamplePadding(gain,1);
            auto clipped=sharp;
            for(int y=0;y<HEIGHT;++y) for(int x=0;x<WIDTH;++x)
                if(x<patchX-margin || x>=patchX+patchSize+margin || y<patchY-margin || y>=patchY+patchSize+margin)
                    clipped[y*WIDTH+x]={0,0,0,0};
            glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA,WIDTH,HEIGHT,0,GL_RGBA,GL_UNSIGNED_BYTE,clipped.data());
            draw();const auto partial=image();
            for(int y=patchY;y<patchY+patchSize;++y) for(int x=patchX;x<patchX+patchSize;++x)
                check(partial[y*WIDTH+x]==complete[y*WIDTH+x],"Optical glass samples outside its prepared source halo");
        }
        glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA,WIDTH,HEIGHT,0,GL_RGBA,GL_UNSIGNED_BYTE,sharp.data());
        four("barMaterial",1,1,1,0);one("barRefractionStrength",10);
        // Leave the independent strength at 10x: shared Kitty optics must
        // still match the terminal, independently of this saved preference.
        for(float strength : {0.F,.25F,1.F,2.F,3.F}) {
            use(barProgram);
            four("barMaterial",1,2,1,0);four("kittyMatch",1,strength,TERMINAL_REFRACTION_PIXELS,TERMINAL_RIM_WIDTH);
            four("kittyLensBox",WIDTH*.5F,HEIGHT*.5F,WIDTH*.5F,HEIGHT*.5F);
            four("barTint",.12F,.13F,.18F,143.F/255.F);
            glUniform1i(glGetUniformLocation(program,"kittyBlur"),1);
            two("windowTopLeft",0,0);two("windowBottomRight",1,1);
            two("topLeft",0,0);two("bottomRight",WIDTH*.5F,HEIGHT*.5F);
            one("thick",0);one("radius",16);one("alpha",1);one("frameRadius",0);
            two("frameFold",0,0);one("time",0);draw();
            std::array<std::array<unsigned char,4>,5> actual;
            for(size_t i=0;i<points.size();++i) actual[i]=sample(points[i].first,points[i].second);
            one("time",500);draw();
            for(size_t i=0;i<points.size();++i)
                check(actual[i]==sample(points[i].first,points[i].second),"Matching bars still animate a different optical profile");
            use(kittyProgram);
            two("bottomRight",WIDTH,HEIGHT);one("radius",16);one("roundingPower",2);
            one("distort",TERMINAL_REFRACTION_PIXELS);one("contrast",TERMINAL_RIM_WIDTH);
            one("alpha",strength);one("vibrancy",1);
            glUniform1i(glGetUniformLocation(program,"blurredBG"),1);draw();
            for(size_t i=0;i<points.size();++i) {
                const auto expected=sample(points[i].first,points[i].second);
                for(int channel=0;channel<3;++channel) {
                    const float tint[]={.12F,.13F,.18F};
                    const float composed=expected[channel]*(1.F-143.F/255.F)+tint[channel]*143.F;
                    check(std::abs(actual[i][channel]-composed)<=1.5F,"Bar refraction/tint differs from the Kitty material");
                }
                check(actual[i][3]==255,"Matching material changed surface coverage");
            }
        }
        glDeleteProgram(kittyProgram);
        // Restore the original texture orientation for the coverage probes.
        glBufferData(GL_ARRAY_BUFFER,sizeof(vertices),vertices,GL_STATIC_DRAW);
        fragmentSource=withTerminalGlassOptics(fragmentSource);
        // Inspect the real SDF inside the attached contacts shelf. Coverage
        // alone misses a shallow internal distance that creates a liquid rim.
        const auto mainStart = fragmentSource.rfind("void main()");
        check(mainStart != std::string::npos,"Fragment entry point missing");
        const auto probeSource = fragmentSource.substr(0,mainStart) + R"GLSL(
void main() {
    float depth = clamp(-oppositePanelSdf(v_texcoord * fullSize) / 64.0, 0.0, 1.0);
    fragColor = vec4(depth, 0.0, 0.0, 1.0);
}
)GLSL";
        program = glCreateProgram();
        glAttachShader(program,compile(GL_VERTEX_SHADER,vertexSource));
        glAttachShader(program,compile(GL_FRAGMENT_SHADER,probeSource));
        glLinkProgram(program); glGetProgramiv(program,GL_LINK_STATUS,&linked);
        check(linked,"Shelf SDF probe did not link");
        glUseProgram(program);
        for (auto [name, offset] : {std::pair{"pos",0}, std::pair{"texcoord",2}}) {
            GLint location=glGetAttribLocation(program,name);
            glEnableVertexAttribArray(location);
            glVertexAttribPointer(location,2,GL_FLOAT,GL_FALSE,4*sizeof(float),reinterpret_cast<void*>(offset*sizeof(float)));
        }
        glUniformMatrix3fv(glGetUniformLocation(program,"proj"),1,GL_FALSE,identity);
        two("fullSize",WIDTH,HEIGHT);
        four("oppositePanel",360,150,40,150);
        four("oppositeLabel",260,68,60,38);
        glUniform1fv(glGetUniformLocation(program,"oppositeCurve"),21,flat.data());
        draw();
        auto depth = [&](int x,int y) {
            unsigned char pixel[4];
            glReadPixels(x,HEIGHT-y-1,1,1,GL_RGBA,GL_UNSIGNED_BYTE,pixel);
            return pixel[0];
        };
        check(depth(320,68)>120,"Contacts shelf and chat retain an internal optical seam");
        check(depth(240,68)>120,"Contacts shelf loses its interior material");
        check(depth(190,68)==0,"Shelf fusion moves its outer edge into the desktop");
        // Vertical contacts remain part of the same liquid, including partial
        // poses while the column grows downward from the topbar.
        for (float progress : {0.1F,0.5F,1.0F}) {
            four("oppositeLabel",320-42*progress,110*progress,42*progress,110*progress);
            draw();
            check(depth(320,std::lround(110*progress))>14,"Vertical contacts retain an internal optical seam");
            check(depth(std::floor(320-84*progress)-8,std::lround(110*progress))==0,"Vertical contacts move their outer edge into the desktop");
        }
        check(glGetError()==GL_NO_ERROR,"OpenGL error while checking the shelf join");
        // Render both Gaussian passes from production. A delta stripe has a
        // known analytical profile; constant channels and alpha must survive.
        std::ifstream blurFile(argv[3]);
        const std::string blurSource{std::istreambuf_iterator<char>(blurFile),std::istreambuf_iterator<char>()};
        const GLuint gaussianProgram=glCreateProgram();
        glAttachShader(gaussianProgram,compile(GL_VERTEX_SHADER,vertexSource));
        glAttachShader(gaussianProgram,compile(GL_FRAGMENT_SHADER,blurSource));
        glLinkProgram(gaussianProgram);glGetProgramiv(gaussianProgram,GL_LINK_STATUS,&linked);
        check(linked,"Optical Gaussian shader did not link");
        for(int y=0;y<HEIGHT;++y) for(int x=0;x<WIDTH;++x)
            sharp[y*WIDTH+x]={96,static_cast<unsigned char>(x==WIDTH/2 ? 255 : 0),
                static_cast<unsigned char>(y==HEIGHT/2 ? 255 : 0),255};
        glActiveTexture(GL_TEXTURE0);glBindTexture(GL_TEXTURE_2D,texture);
        glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA,WIDTH,HEIGHT,0,GL_RGBA,GL_UNSIGNED_BYTE,sharp.data());
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
        GLuint horizontalTexture,horizontalFramebuffer;
        glGenTextures(1,&horizontalTexture);glBindTexture(GL_TEXTURE_2D,horizontalTexture);
        glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA,WIDTH,HEIGHT,0,GL_RGBA,GL_UNSIGNED_BYTE,nullptr);
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
        glGenFramebuffers(1,&horizontalFramebuffer);glBindFramebuffer(GL_FRAMEBUFFER,horizontalFramebuffer);
        glFramebufferTexture2D(GL_FRAMEBUFFER,GL_COLOR_ATTACHMENT0,GL_TEXTURE_2D,horizontalTexture,0);
        check(glCheckFramebufferStatus(GL_FRAMEBUFFER)==GL_FRAMEBUFFER_COMPLETE,"Gaussian work target incomplete");
        use(gaussianProgram);one("radius",3.5F);two("uvOffset",1.F/WIDTH,0);
        glBindTexture(GL_TEXTURE_2D,texture);draw();
        glBindFramebuffer(GL_FRAMEBUFFER,0);glBindTexture(GL_TEXTURE_2D,horizontalTexture);
        two("uvOffset",0,1.F/HEIGHT);draw();
        double total=0;
        for(int offset=-11;offset<=11;++offset) total+=std::exp(-.5*offset*offset/(3.5*3.5));
        for(int offset : {-9,-5,0,5,9}) {
            const int expected=std::lround(255*std::exp(-.5*offset*offset/(3.5*3.5))/total);
            const auto horizontal=sample(WIDTH/2+offset,HEIGHT/2);
            const auto vertical=sample(WIDTH/2,HEIGHT/2+offset);
            check(std::abs(int(horizontal[1])-expected)<=1 && std::abs(int(vertical[2])-expected)<=1,
                "Gaussian blur does not follow the analytical source-space profile");
            check(horizontal[0]==96 && vertical[0]==96 && horizontal[3]==255 && vertical[3]==255,
                "Gaussian passes change a constant channel or alpha");
        }
        check(glGetError()==GL_NO_ERROR,"OpenGL error in the optical Gaussian passes");
        std::cout << "Notification, volume, frame and desktop wave rendered correctly\n";
        eglMakeCurrent(display,EGL_NO_SURFACE,EGL_NO_SURFACE,EGL_NO_CONTEXT);
        eglDestroySurface(display,surface);
        eglDestroyContext(display,context);
        eglTerminate(display);
    } catch (const std::exception& error) {
        std::cerr << error.what() << '\n';
        return 1;
    }
}
