#include <hyprland/src/config/ConfigValue.hpp>
#include <hyprland/src/config/ConfigManager.hpp>
#include <hyprland/src/config/values/types/FloatValue.hpp>
#include <hyprland/src/config/values/types/IntValue.hpp>
#include <hyprland/src/desktop/view/LayerSurface.hpp>
#include <hyprland/src/desktop/view/Window.hpp>
#include <hyprland/src/event/EventBus.hpp>
#include <hyprland/src/managers/EventManager.hpp>
#include <hyprland/src/managers/eventLoop/EventLoopManager.hpp>
#include <hyprland/src/plugins/PluginAPI.hpp>
#include <hyprland/src/render/ElementRenderer.hpp>
#include <hyprland/src/render/OpenGL.hpp>
#include <hyprland/src/render/Renderer.hpp>
#include <hyprland/src/render/Shader.hpp>
#include <hyprland/src/render/gl/GLElementRenderer.hpp>
#include <hyprland/src/render/gl/GLFramebuffer.hpp>
#include <hyprland/src/render/pass/TexPassElement.hpp>
#include <hyprland/src/state/MonitorState.hpp>

#include <algorithm>
#include <array>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <format>
#include <filesystem>
#include <sstream>
#include <stdexcept>
#include <string>
#include <unordered_map>
#include <vector>
#include <hyprutils/utils/ScopeGuard.hpp>
#include <lua.hpp>
#include <drm_fourcc.h>
#include "WallpaperTransition.hpp"
#include "TerminalGlass.hpp"
#include "BarRefraction.hpp"
#include "LyricsBeat.hpp"

namespace {
constexpr auto DESKTOP_NAMESPACE = "velora-shell-lock-preview-desktop";
constexpr auto PANEL_NAMESPACE   = "velora-shell-lock-preview-panel";
constexpr auto TOPBAR_NAMESPACE  = "velora-shell-topbar";
constexpr auto UNIFIED_BAR_NAMESPACE = "velora-shell-unified-bar";
constexpr auto RIGHT_MENU_NAMESPACE = "velora-shell-right-menu";
constexpr auto SETTINGS_NAMESPACE = "velora-shell-settings";
constexpr auto EDITOR_NAMESPACE = "velora-shell-editor";
constexpr auto SELECTOR_NAMESPACE = "velora-wallpaper-selector";
constexpr auto SHARED_WIDGETS_NAMESPACE = "velora-shell-shared-widgets";
constexpr auto WALLPAPER_EFFECTS_NAMESPACE = "velora-shell-wallpaper-effects";
constexpr size_t SHARED_WIDGET_COUNT = 6;

HANDLE         g_handle  = nullptr;
CFunctionHook* g_drawTex = nullptr;
CFunctionHook* g_drawGLTex = nullptr;
CFunctionHook* g_drawGLPreBlur = nullptr;
CHyprSignalListener g_tickListener;
SP<CEventLoopTimer> g_causticsTimer;
SP<Render::GL::CGLFramebuffer> g_clearBackdrop;
std::unordered_map<std::string, SP<Render::GL::CGLFramebuffer>> g_frameBackdrops;
// Retain the desktop source before its wave is shaded. Upper frame pixels
// near that same wave must not sample and refract the already shaded wave.
struct SFrameFusionBackdrop {
    SP<Render::GL::CGLFramebuffer> sharp, blurred;
};
std::unordered_map<std::string, SFrameFusionBackdrop> g_frameFusionBackdrops;
struct SOpticalBlurBuffers {
    SP<Render::GL::CGLFramebuffer> horizontal, vertical;
};
std::unordered_map<std::string, SOpticalBlurBuffers> g_opticalBlurBuffers;
uint64_t g_clearBackdropCopies = 0;

SP<Config::Values::CIntValue> g_desktopSize;
SP<Config::Values::CIntValue> g_desktopPasses;
SP<Config::Values::CFloatValue> g_desktopNoise;
SP<Config::Values::CFloatValue> g_desktopContrast;
SP<Config::Values::CFloatValue> g_desktopBrightness;
SP<Config::Values::CFloatValue> g_desktopVibrancy;
SP<Config::Values::CFloatValue> g_desktopVibrancyDarkness;
SP<Config::Values::CIntValue> g_panelSize;
SP<Config::Values::CIntValue> g_panelPasses;
SP<Config::Values::CFloatValue> g_panelNoise;
SP<Config::Values::CFloatValue> g_panelContrast;
SP<Config::Values::CFloatValue> g_panelBrightness;
SP<Config::Values::CFloatValue> g_panelVibrancy;
SP<Config::Values::CFloatValue> g_panelVibrancyDarkness;
SP<Config::Values::CFloatValue> g_panelRefraction;
SP<Config::Values::CFloatValue> g_panelEdgeWidth;
SP<Config::Values::CFloatValue> g_panelDispersion;
SP<Config::Values::CFloatValue> g_panelTint;
SP<Config::Values::CIntValue> g_topbarSize;
SP<Config::Values::CIntValue> g_topbarPasses;
SP<Config::Values::CFloatValue> g_topbarNoise;
SP<Config::Values::CFloatValue> g_topbarContrast;
SP<Config::Values::CFloatValue> g_topbarBrightness;
SP<Config::Values::CFloatValue> g_topbarVibrancy;
SP<Config::Values::CFloatValue> g_topbarVibrancyDarkness;

CConfigValue<Config::INTEGER> g_globalSize;
CConfigValue<Config::INTEGER> g_globalPasses;
CConfigValue<Config::FLOAT> g_globalNoise;
CConfigValue<Config::FLOAT> g_globalContrast;
CConfigValue<Config::FLOAT> g_globalBrightness;
CConfigValue<Config::FLOAT> g_globalVibrancy;
CConfigValue<Config::FLOAT> g_globalVibrancyDarkness;

SP<SHyprCtlCommand> g_statusCommand;
uint64_t            g_desktopDraws = 0;
uint64_t            g_panelDraws   = 0;
uint64_t            g_topbarDraws  = 0;
uint64_t            g_refractionDraws = 0;
uint64_t            g_topbarRefractionDraws = 0;
uint64_t            g_rightMenuDraws = 0;
uint64_t            g_rightMenuRefractionDraws = 0;
uint64_t            g_settingsDraws = 0;
uint64_t            g_settingsRefractionDraws = 0;
uint64_t            g_editorDraws = 0;
uint64_t            g_editorRefractionDraws = 0;
uint64_t            g_sharedWidgetDraws = 0;
uint64_t            g_sharedWidgetRefractionDraws = 0;
bool                g_unloading    = false;
bool                g_editorialLock = false;
bool                g_liquidShaderFailed = false;
bool                g_desktopShaderFailed = false;
SP<CShader>          g_liquidShader;
SP<CShader>          g_desktopShader;
SP<CShader>          g_opticalBlurShader;
SP<CShader>          g_terminalShader;
SP<CShader>          g_terminalBarShader;
struct STerminalBackdrop {
    PHLMONITORREF monitor;
    SP<Render::GL::CGLFramebuffer> material, desktop;
};
std::unordered_map<std::string, STerminalBackdrop> g_terminalBackdrops;
SP<Config::Values::CIntValue> g_terminalGlass;
SP<Config::Values::CFloatValue> g_terminalStrength;
std::optional<STerminalGlassControl> g_terminalControl;
bool g_terminalBarMatch = false;
bool g_terminalFollowBar = false;
float g_terminalBarBrightness = 1.F;
float g_barBrightness = 1.F;
uint64_t g_terminalFollowBarDraws = 0;
SP<Config::Values::CFloatValue> g_barRefraction;
std::optional<float> g_barRefractionOverride;
float barRefractionStrength() {
    return g_barRefractionOverride.value_or(g_barRefraction ? g_barRefraction->value() : BAR_DEFAULT_REFRACTION);
}
uint64_t g_terminalBarMatchDraws = 0;
bool terminalGlassEnabled() { return g_terminalControl ? g_terminalControl->enabled : g_terminalGlass && g_terminalGlass->value(); }
float terminalGlassStrength() { return g_terminalControl ? g_terminalControl->strength : g_terminalStrength ? g_terminalStrength->value() : 1.F; }
bool terminalOpticsActive() { return terminalGlassEnabled() && (g_terminalFollowBar || terminalGlassStrength() > 0.F); }
bool g_terminalShaderFailed = false;
uint64_t g_terminalGlassDraws = 0;
uint64_t g_terminalSharpDraws = 0;
uint64_t g_terminalDesktopCopies = 0;
struct SKittyIdentity { PHLWINDOWREF window; bool kitty = false; };
std::unordered_map<const Desktop::View::CWindow*, SKittyIdentity> g_kittyIdentities;

struct SWallpaperTransition {
    SWallpaperTransitionTiming timing;
    std::unordered_map<std::string, SP<Render::IFramebuffer>> frames;
    float mode = 0.F, phase = 0.F;
    std::array<float, 2> direction{1.F, 0.F};
};
SWallpaperTransition g_wallpaperTransition;
SP<CShader> g_wallpaperShader;
SP<CEventLoopTimer> g_wallpaperTimer;
int g_wallpaperLastDirection = -1;

struct SBlurTransition {
    float current = 0.F;
    float start   = 0.F;
    float target  = 0.F;
    float durationSeconds = 0.52F;
    std::chrono::steady_clock::time_point started = std::chrono::steady_clock::now();
    bool animating = false;
};

SBlurTransition g_transition;

struct SCausticsState {
    bool enabled = false;
    bool lines = true;
    bool animating = false;
    float intensity = 0.F;
    float phase = 0.F;
    std::chrono::steady_clock::time_point lastTick = std::chrono::steady_clock::now();
};

SCausticsState g_caustics;
uint64_t g_causticsFrames = 0;

struct SDialMorph {
    bool active = false;
    float depth = 0.F;
    float halfHeight = 0.F;
    float centerY = 408.F;
};

SDialMorph g_dialMorph;

struct STopbarMorph {
    bool active = false;
    float opacity = 1.F;
    float x = 0.F;
    float y = 0.F;
    float width = 1.F;
    float height = 1.F;
    float radius = 0.F;
    bool connected = false;
    float barHeight = 0.F;
    float anchorX = 0.F;
    float neckHalfWidth = 0.F;
    float joinSize = 0.F;
    float sideBodyY = 0.F;
    float sideBodyWidth = 0.F;
    float sideBodyHeight = 0.F;
    float bottomHeight = 0.F;
    float oppositeWidth = 0.F;
    std::array<float, 3> oppositePanel{}; // y, width, height
    float oppositeContour = 0.F;
    std::array<float, 21> oppositeCurve{};
    float sideWaveScale = 0.F;
    float waveDockProgress = 0.F;
    float sideWaveWidth = 0.F;
    std::array<float, 21> sideCurve{};
    std::array<float, 3> oppositeLabel{}; // y, width, height
    float sideLabelY = 0.F;
    float sideLabelWidth = 0.F;
    float sideLabelHeight = 0.F;
    float desktopFold = 0.F;
    // Optional execution/notification panel, independent of the open menu.
    std::array<float, 8> statusPanel{};
    // Charging extends the same bar while menus and notifications stay open.
    std::array<float, 8> chargingPanel{};
    float chargingProgress = 1.F;
    float chargingStrength = 0.F;
    std::array<float, 8> timerPanel{};
    std::array<float, 3> timerLight{}; // normalized anchor, pulse progress, intensity
};

constexpr size_t TOPBAR_SHAPE_COUNT = 3;
constexpr size_t EDITOR_SHAPE_COUNT = 6;
std::array<STopbarMorph, TOPBAR_SHAPE_COUNT> g_topbarShapes;
// Each monitor owns its anchor and expansion. Legacy/sidebar shapes stay separate.
std::unordered_map<std::string, STopbarMorph> g_connectedTopbars;
std::unordered_map<std::string, STopbarMorph> g_selectorShapes;
// The editor owns the bottom material while Settings are attached. The desktop
// host relinquishes that same pass, so neither tint nor blur is composited twice.
std::unordered_map<std::string, STopbarMorph> g_bottomSettings;
bool hasBottomSettings(const std::string& monitor) {
    return g_bottomSettings.contains(monitor);
}
std::unordered_map<std::string, STopbarMorph> g_unifiedBarShapes;
struct SDesktopBarMaterial {
    int mode = 1; // solid, glass, liquid
    std::array<float, 4> tint{};
    bool blur = true;
    bool spectrum = false;
    std::array<float, 96> bands{};
};
std::unordered_map<std::string, SDesktopBarMaterial> g_desktopBarMaterials;
struct SLyricsBeatPulse {
    float x, y, strength;
    std::array<float, 6> colors;
    std::chrono::steady_clock::time_point started;
};
std::unordered_map<std::string, std::vector<SLyricsBeatPulse>> g_lyricsBeats;
uint64_t g_lyricsBeatCount = 0;
const STopbarMorph& unifiedBarShape(const std::string& monitor) {
    static const STopbarMorph empty;
    const auto found = g_unifiedBarShapes.find(monitor);
    return found == g_unifiedBarShapes.end() ? empty : found->second;
}
bool g_barBlurEnabled = true;
bool g_luaDispatch = false;
uint64_t g_topbarBlurDraws = 0;
uint64_t g_sidebarBlurDraws = 0;
uint64_t g_waveBlurDraws = 0;
bool g_widgetBlurEnabled = true;
float g_wallpaperBlur = 0.F;
bool g_liquidFrosted = true;
bool g_liquidLight = false;
uint64_t g_widgetBlurDraws = 0;
std::array<STopbarMorph, EDITOR_SHAPE_COUNT> g_editorShapes;
STopbarMorph g_settingsMorph;

struct SAppearanceOptics {
    float blur = 0.55F;
    float contrast = 1.08F;
    float reflection = 0.35F;
    bool preview = false;
};

SAppearanceOptics g_committedAppearance;
SAppearanceOptics g_activeAppearance;

int appearanceBlurSize(const int base) {
    const float factor = std::clamp(
        g_activeAppearance.blur / 0.55F, 0.F, 1.82F);
    return std::clamp(static_cast<int>(std::lround(base * factor)), 0, 40);
}

float appearanceContrast(const float base) {
    return base * std::clamp(
        g_activeAppearance.contrast / 1.08F, 0.60F, 1.60F);
}

float appearanceReflection() {
    return std::clamp(
        g_activeAppearance.reflection / 0.35F, 0.F, 2.86F);
}

struct SRightMenuMorph {
    bool active = false;
    float depth = 0.F;
    float halfHeight = 0.F;
    float straightHalfHeight = 0.F;
    float railWidth = 0.F;
    float centerY = 0.5F;
};

SRightMenuMorph g_rightMenuMorph;

struct SSharedWidgetShape {
    bool active = false;
    float x = 0.F;
    float y = 0.F;
    float width = 0.F;
    float height = 0.F;
    float radius = 0.F;
    float rotation = 0.F;
    float opacity = 0.F;
};

std::array<SSharedWidgetShape, SHARED_WIDGET_COUNT> g_sharedWidgetShapes;
bool g_sharedWidgetShapesActive = false;
bool g_sharedWidgetCaustics = false;

using DrawTexFn = void (*)(Render::IElementRenderer*, WP<CTexPassElement>, const CRegion&);
using DrawGLTexFn = void (*)(Render::GL::CGLElementRenderer*, WP<CTexPassElement>, const CRegion&);
using DrawGLPreBlurFn = void (*)(Render::GL::CGLElementRenderer*, WP<CPreBlurElement>, const CRegion&);

constexpr auto LIQUID_GLASS_VERTEX = R"GLSL(#version 300 es

uniform mat3 proj;

in vec2 pos;
in vec2 texcoord;

out vec2 v_texcoord;

void main() {
    gl_Position = vec4(proj * vec3(pos, 1.0), 1.0);
    v_texcoord = texcoord;
}
)GLSL";

constexpr auto LIQUID_GLASS_FRAGMENT = R"GLSL(#version 300 es

precision highp float;

in vec2 v_texcoord;

uniform sampler2D tex;
uniform vec2 fullSize;
uniform vec2 windowTopLeft;
uniform vec2 windowBottomRight;
// Existing Hyprland uniform slots are reused by this private shader:
// topLeft=mainCenter, bottomRight=mainHalfSize,
// uvOffset=dialCenter, uvSize=dialHalfSize.
uniform vec2 topLeft;
uniform vec2 bottomRight;
uniform vec2 uvOffset;
uniform vec2 uvSize;
uniform vec4 color;
uniform float radius;
uniform float radiusOuter;
uniform float thick;
uniform float alpha;
uniform float distort;
uniform float contrast;
uniform float brightness;
uniform float vibrancy;
uniform float noise;
uniform float time;
// Reuse one dormant Hyprland pointer slot in this private shader:
// x=shared phase, y=intensity, z=active, w=panel scale.
uniform vec4 pointer_position;
// x=light-line visibility, y=rotation, z=compact widget, w=unified bar.
uniform vec4 pointer_shape;
// Desktop interior in framebuffer coordinates; both frame windows use it.
uniform vec4 frameInterior;
uniform vec4 frameTopPanel; // topbar body, shared in framebuffer coordinates
uniform vec4 frameTopMetrics; // anchor, neck, radius, join
uniform vec4 oppositePanel; // center and half-size in framebuffer pixels
uniform vec4 oppositeLabel;
uniform float oppositeContour;
uniform float oppositeCurve[21];
uniform float sideWaveScale;
uniform float waveDockProgress;
uniform float sideWaveWidth;
uniform float sideCurve[21];
uniform float frameRadius;
uniform vec2 frameFold; // progress, moving bottom in framebuffer coordinates
uniform vec4 sideLabel;
uniform vec2 frost;
uniform vec4 barTint;
uniform vec4 barMaterial; // active, mode, blur, spectrum
uniform float barRefractionStrength;
uniform float opticalScale;
uniform highp sampler2D frameBackdrop;
uniform highp sampler2D frameBlur;
uniform float frameFusion;
float frameBackdropMix = 0.0;
// A separate instance of this exact shader prepares Kitty's backdrop. The
// original client pass still composites the foreground and rounds its corners.
uniform float terminalBackdrop;
uniform float terminalBrightness;
uniform float barBrightness;
uniform highp sampler2D kittyBlur;
uniform vec4 kittyMatch; // enabled, strength, refraction pixels, rim width
uniform vec4 kittyLensBox; // centre and half size in backdrop pixels
uniform float barBands[96];
uniform vec4 statusPanel; // center and half-size, in draw-local pixels
uniform vec4 statusMetrics; // anchor, neck, radius, join
uniform vec4 chargingPanel;
uniform vec4 chargingMetrics;
uniform vec4 chargingLight; // origin in framebuffer pixels, spread, fading intensity
uniform vec4 timerLight;
uniform vec4 musicLights[8];
uniform vec3 musicColors[16];
uniform vec4 timerPanel;
uniform vec4 timerMetrics;
uniform vec4 bottomPanel; // center and half-size in framebuffer pixels
uniform vec2 bottomMetrics; // radius, smooth join

layout(location = 0) out vec4 fragColor;

float roundedBoxSdf(vec2 point, vec2 halfSize, float cornerRadius) {
    vec2 q = abs(point) - halfSize + vec2(cornerRadius);
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - cornerRadius;
}

float smoothUnion(float first, float second, float softness) {
    float blend = clamp(0.5 + 0.5 * (second - first) / softness, 0.0, 1.0);
    return mix(second, first, blend) - softness * blend * (1.0 - blend);
}

float connectPanel(float distance, vec2 point, float barBottom, vec2 center,
                   vec2 halfSize, float anchor, float neckWidth,
                   float panelRadius, float join);

float ellipseSdf(vec2 point, vec2 radii) {
    vec2 safeRadii = max(radii, vec2(0.5));
    float k0 = length(point / safeRadii);
    float k1 = max(length(point / (safeRadii * safeRadii)), 0.0001);
    return k0 * (k0 - 1.0) / k1;
}

float rightMenuSdf(vec2 point) {
    float railRadius = min(bottomRight.x, 3.0);
    float railDistance = roundedBoxSdf(point - topLeft,
        bottomRight, railRadius);

    vec2 relative = point - uvOffset;
    float depth = max(uvSize.x, 0.5);
    float halfHeight = max(uvSize.y, 0.5);
    float straight = min(max(radius, 0.0), halfHeight);
    float shoulderHeight = max(halfHeight - straight, 0.5);

    // One continuous boundary, not a union of body + two caps.  The former
    // construction had zero-distance seams at +/-straight, which the lens
    // correctly (but undesirably) refracted as diamonds inside the menu.
    float vertical = abs(relative.y);
    float shoulderT = clamp((vertical - straight) / shoulderHeight,
                            0.0, 1.0);
    float leftBoundary = -depth
        * sqrt(max(0.0, 1.0 - shoulderT * shoulderT));
    float bulgeDistance = max(
        max(leftBoundary - relative.x, relative.x),
        vertical - halfHeight);
    return smoothUnion(railDistance, bulgeDistance,
                       min(7.0, max(2.0, depth * 0.08)));
}

vec2 mainShapePoint(vec2 point) {
    vec2 relative = point - topLeft;
    float cosine = cos(pointer_shape.y);
    float sine = sin(pointer_shape.y);
    return vec2(cosine * relative.x + sine * relative.y,
                -sine * relative.x + cosine * relative.y);
}

float mainShapeSdf(vec2 point) {
    return roundedBoxSdf(mainShapePoint(point), bottomRight, radius);
}

float balancedBarBand(int index) {
    int band = clamp(index, 0, 95);
    // Low frequencies must lift both sides of the frame. Keep this mapping
    // local to the desktop material; the analyzer's actual spectrum is intact.
    return max(barBands[band], barBands[95 - band]);
}

float curveOffset(float progress, bool sidebar) {
    float p = clamp(progress, 0.0, 1.0) * 20.0;
    int i = min(19, int(floor(p)));
    float t = p - float(i);
    float a = sidebar ? sideCurve[max(0, i - 1)] : oppositeCurve[max(0, i - 1)];
    float b = sidebar ? sideCurve[i] : oppositeCurve[i];
    float c = sidebar ? sideCurve[i + 1] : oppositeCurve[i + 1];
    float d = sidebar ? sideCurve[min(20, i + 2)] : oppositeCurve[min(20, i + 2)];
    float u = 1.0 - t;
    return (u*u*u*a + (3.0*t*t*t-6.0*t*t+4.0)*b
        + (-3.0*t*t*t+3.0*t*t+3.0*t+1.0)*c + t*t*t*d) / 6.0;
}

float oppositeOffset(float progress) {
    return curveOffset(progress, false) * oppositePanel.z * 2.0;
}

float oppositePanelSdf(vec2 pixel) {
    if (oppositePanel.z > 0.01) {
        vec2 relative = pixel - oppositePanel.xy;
        float overshoot = oppositeContour > .01 && oppositePanel.w * 2.0 >= fullSize.y - frameInterior.y - 2.0 ? 32.0 : 0.0;
        float t = clamp((relative.y + oppositePanel.w) / max(1.0, 2.0 * oppositePanel.w), 0.0, 1.0);
        float contour = oppositeOffset(t);
        // Move only the inner edge; the frame side remains continuous.
        relative.x -= contour;
        float panel = roundedBoxSdf(relative, oppositePanel.zw + vec2(0.0, overshoot), min(20.0, oppositePanel.z));
        float distance = panel;
        if (oppositeLabel.z > .01) {
            // Extend the attached shelf into the panel, keeping its outer
            // edge fixed. Merely touching leaves a shallow SDF inside their
            // union and the liquid lens draws an internal optical seam.
            float join = min(48.0, oppositeLabel.w * 1.2);
            float label = roundedBoxSdf(pixel - oppositeLabel.xy - vec2(join * .5, 0.0),
                oppositeLabel.zw + vec2(join * .5, 0.0), min(10.0, oppositeLabel.z));
            distance = smoothUnion(distance, label, min(8.0, oppositeLabel.z));
        }
        return distance;
    }
    return 1e6;
}

float sideWaveSdf(vec2 pixel) {
    if (waveDockProgress <= .001 || sideWaveWidth <= .01) return 1e6;
    float t = (pixel.y - frameInterior.y) / max(1.0, fullSize.y - frameInterior.y);
    float rise = smoothstep(1.0 - waveDockProgress * 1.12,
        1.12 - waveDockProgress * 1.12, t);
    float edge = frameInterior.x + curveOffset(t, true) * sideWaveWidth * waveDockProgress * rise;
    // Extend through the existing top/bottom strips so their joins have no
    // extra antialiased boundary. Frame ownership still partitions the passes.
    return pixel.x - edge;
}

float frameBaseSdf(vec2 pixel) {
    float distance = -roundedBoxSdf(pixel - frameInterior.xy - frameInterior.zw * 0.5,
                         frameInterior.zw * 0.5, frameRadius);
    // Retract the U-shaped frame upward, leaving the existing topbar intact.
    // Clip its outside too: an inverted box otherwise fills below the bottom.
    if (frameFold.x > 0.0) {
        distance = frameFold.x >= .9999 ? pixel.y - frameInterior.y
            : max(distance, pixel.y - frameFold.y);
        // The bottom divides and retracts toward its two corners. Only the
        // corner tails subsequently rise along the sides; no horizontal
        // strip travels across the middle of the desktop.
        float gather = clamp(frameFold.x / .35, 0.0, 1.0);
        float middle = fullSize.x * .5;
        float leftEnd = mix(middle, frameInterior.x + frameRadius, gather);
        float rightStart = mix(middle, frameInterior.x + frameInterior.z - frameRadius, gather);
        if (pixel.y >= frameInterior.y)
            distance = max(distance, min(pixel.x - leftEnd, rightStart - pixel.x));
    }
    if (barMaterial.x > .5 && oppositePanel.z > .01)
        distance = smoothUnion(distance, oppositePanelSdf(pixel), min(24.0, oppositePanel.z));
    if (barMaterial.x > .5) distance = min(distance, sideWaveSdf(pixel));
    if (frameTopPanel.w > .005)
        distance = connectPanel(distance, pixel, frameInterior.y,
            frameTopPanel.xy, frameTopPanel.zw, frameTopMetrics.x,
            frameTopMetrics.y, frameTopMetrics.z, frameTopMetrics.w);
    return distance;
}

float framePanelSdf(vec2 point) {
    vec2 pixel = point + (windowTopLeft + windowBottomRight) * fullSize * 0.5;
    float distance = frameBaseSdf(pixel);
    if (barMaterial.x > 1.5 && bottomPanel.w > 0.0) {
        float panel = roundedBoxSdf(pixel - bottomPanel.xy, bottomPanel.zw, bottomMetrics.x);
        distance = smoothUnion(distance, panel, max(0.01, bottomMetrics.y));
    }
    return distance;
}

float desktopWaveSdf(vec2 pixel) {
    if (barMaterial.w < 1.0 || frameFold.x > 0.0) return 1e6;
    float base = frameInterior.y + frameInterior.w;
    float scale = max(0.1, fullSize.x / barMaterial.w);
    if (pixel.y < base - 182.0 * scale) return 1e6;
    float band = clamp(pixel.x / fullSize.x * 95.0, 0.0, 95.0);
    int index = int(floor(band));
    float t = fract(band);
    float a = balancedBarBand(index - 1);
    float b = balancedBarBand(index);
    float c = balancedBarBand(index + 1);
    float d = balancedBarBand(index + 2);
    // Cubic interpolation gives a continuous tangent between analyzer bands.
    // No quantized height, columns, gaps or grid enter the surface geometry.
    float level = clamp(0.5 * ((2.0*b) + (-a+c)*t
        + (2.0*a-5.0*b+4.0*c-d)*t*t + (-a+3.0*b-3.0*c+d)*t*t*t), 0.0, 1.0);
    float dock = clamp(waveDockProgress, 0.0, 1.0);
    float remaining = (1.0 - dock) * (1.0 - smoothstep(1.0 - dock,
        1.12 - dock, pixel.x / fullSize.x));
    remaining *= 1.0 - frameFold.x;
    level *= remaining;
    float slope = 0.5 * ((-a+c) + 2.0*(2.0*a-5.0*b+4.0*c-d)*t
        + 3.0*(-a+3.0*b-3.0*c+d)*t*t) * 180.0 * 0.9948 * scale * 95.0 / fullSize.x * remaining;
    float wave = (base - level * 180.0 * 0.9948 * scale - pixel.y)
        / sqrt(1.0 + slope*slope);
    return wave;
}

float frameSdf(vec2 point) {
    vec2 pixel = point + (windowTopLeft + windowBottomRight) * fullSize * 0.5;
    return min(framePanelSdf(point), desktopWaveSdf(pixel));
}

vec3 sceneSample(vec2 uv) {
    if (frameBackdropMix <= .001) return texture(tex, uv).rgb;
    if (frameBackdropMix >= .999) return texture(frameBackdrop, uv).rgb;
    return mix(texture(tex, uv).rgb, texture(frameBackdrop, uv).rgb, frameBackdropMix);
}

vec3 blurSample(vec2 uv) {
    if (frameBackdropMix <= .001) return texture(kittyBlur, uv).rgb;
    if (frameBackdropMix >= .999) return texture(frameBlur, uv).rgb;
    return mix(texture(kittyBlur, uv).rgb, texture(frameBlur, uv).rgb, frameBackdropMix);
}

float connectPanel(float distance, vec2 point, float barBottom, vec2 center,
                   vec2 halfSize, float anchor, float neckWidth,
                   float panelRadius, float join) {
    if (halfSize.y <= 0.005)
        return distance;
    float body = roundedBoxSdf(point - center, halfSize, min(panelRadius, halfSize.y));
    float gap = center.y - halfSize.y - barBottom;
    float neck = roundedBoxSdf(
        point - vec2(anchor, barBottom + gap * 0.5),
        vec2(neckWidth, gap * 0.5 + min(panelRadius * 10.0 / 18.0, halfSize.y)),
        min(panelRadius / 3.0, halfSize.y));
    float softness = max(0.01, min(join, halfSize.y * 2.0));
    return smoothUnion(smoothUnion(distance, neck, softness), body, softness);
}

float connectTopbar(float distance, vec2 point) {
    float barBottom = topLeft.y + bottomRight.y;
    // With a frame, the body is already in the common distance field. Adding
    // it again would deepen only the topbar pass and change its optical rim.
    if (frameTopPanel.w <= .005)
        distance = connectPanel(distance, point, barBottom, uvOffset, uvSize,
            pointer_shape.x, pointer_shape.y, radius, radiusOuter);
    distance = connectPanel(distance, point, barBottom, statusPanel.xy, statusPanel.zw,
        statusMetrics.x, statusMetrics.y, statusMetrics.z, statusMetrics.w);
    distance = connectPanel(distance, point, barBottom, chargingPanel.xy, chargingPanel.zw,
        chargingMetrics.x, chargingMetrics.y, chargingMetrics.z, chargingMetrics.w);
    return connectPanel(distance, point, barBottom, timerPanel.xy, timerPanel.zw,
        timerMetrics.x, timerMetrics.y, timerMetrics.z, timerMetrics.w);
}

float connectedTopbarSdf(vec2 point) {
    return connectTopbar(frameRadius > 0.0 || frameFold.x > 0.0
        ? frameSdf(point) : point.y - topLeft.y - bottomRight.y, point);
}

float connectSidebar(float distance, vec2 point) {
    if (uvSize.x > 0.005 && uvSize.y > 0.005) {
        float body = roundedBoxSdf(point - uvOffset, uvSize, radiusOuter);
        distance = smoothUnion(distance, body, max(0.01, radiusOuter));
    }
    if (sideLabel.z > 0.005 && sideLabel.w > 0.005) {
        float label = roundedBoxSdf(point - sideLabel.xy, sideLabel.zw,
                                    min(10.0, sideLabel.z));
        distance = smoothUnion(distance, label, min(8.0, sideLabel.z));
    }
    return distance;
}

float compositionSdf(vec2 point) {
    if (thick > 3.5) {
        float edge = topLeft.x + pointer_shape.x * bottomRight.x;
        float rail = frameRadius > 0.0 || frameFold.x > 0.0 ? frameSdf(point) : (point.x - edge) * pointer_shape.x;
        rail = connectSidebar(rail, point);
        return frameRadius > 0.0 || frameFold.x > 0.0 ? rail : smoothUnion(rail, pointer_shape.z - point.y, max(0.01, radius));
    }
    if (thick > 2.5)
        return connectedTopbarSdf(point);
    if (thick > 1.5)
        return rightMenuSdf(point);
    float mainDistance = mainShapeSdf(point);
    if (thick < 0.5)
        return mainDistance;
    float dialDistance = roundedBoxSdf(point - uvOffset, uvSize, radiusOuter);
    float joinSoftness = min(48.0, max(10.0, radiusOuter * 0.38));
    return smoothUnion(mainDistance, dialDistance, joinSoftness);
}

float luminance(vec3 sampleColor) {
    return dot(sampleColor, vec3(0.2126, 0.7152, 0.0722));
}

float hash21(vec2 point) {
    point = fract(point * vec2(123.34, 456.21));
    point += dot(point, point + 45.32);
    return fract(point.x * point.y);
}

vec2 causticsHash(vec2 cell) {
    return fract(sin(vec2(dot(cell, vec2(127.1, 311.7)),
                          dot(cell, vec2(269.5, 183.3)))) * 43758.5453);
}

vec3 poolCaustics(vec2 designPoint, float phase, float strength) {
    if (strength <= 0.001)
        return vec3(0.0);

    // Slowly moving Voronoi boundaries create the irregular connected light
    // net seen on a pool floor. Domain warping prevents a tiled/cellular look.
    vec2 point = designPoint / 112.0;
    point += vec2(sin(point.y * 1.31 + phase * 0.23),
                  cos(point.x * 1.17 - phase * 0.19)) * 0.16;
    vec2 baseCell = floor(point);
    vec2 localPoint = fract(point);
    float nearest = 16.0;
    float secondNearest = 16.0;
    for (int cellY = -1; cellY <= 1; ++cellY) {
        for (int cellX = -1; cellX <= 1; ++cellX) {
            vec2 cell = vec2(float(cellX), float(cellY));
            vec2 random = causticsHash(baseCell + cell);
            vec2 feature = 0.5 + 0.38 * sin(
                phase * vec2(0.31, -0.27) + random * 6.2831853);
            vec2 delta = cell + feature - localPoint;
            float distanceSquared = dot(delta, delta);
            if (distanceSquared < nearest) {
                secondNearest = nearest;
                nearest = distanceSquared;
            } else if (distanceSquared < secondNearest) {
                secondNearest = distanceSquared;
            }
        }
    }

    float edgeGap = sqrt(secondNearest) - sqrt(nearest);
    float ridge = 1.0 - smoothstep(0.012, 0.068, edgeGap);
    float shimmer = 0.84 + 0.16 * sin(
        designPoint.x * 0.018 - designPoint.y * 0.014 + phase * 0.41);
    float light = pow(clamp(ridge, 0.0, 1.0), 1.55) * shimmer * strength;

    // A low-frequency surface normal bends the wallpaper under the same
    // moving light network without moving foreground QML content.
    vec2 bend = vec2(
        cos(point.x * 2.07 + point.y * 0.71 + phase * 0.29)
            + 0.55 * cos(point.y * 2.41 - phase * 0.21),
        sin(point.y * 1.93 - point.x * 0.63 - phase * 0.25)
            + 0.55 * sin(point.x * 2.27 + phase * 0.18));
    bend *= (1.25 + ridge * 0.75) * strength * 28.0;
    float bendLength = length(bend);
    if (bendLength > 72.0)
        bend *= 72.0 / bendLength;
    return vec3(bend, light);
}

vec3 frostedBackdrop(vec2 uv, float scale) {
    // A small Gaussian diffusion keeps the optical rim crisp while removing
    // high-frequency wallpaper detail underneath text and controls.
    vec2 stride = vec2(4.0 * scale) / fullSize;
    vec3 result = vec3(0.0);
    for (int y = -2; y <= 2; ++y) {
        float wy = y == 0 ? 6.0 : abs(y) == 1 ? 4.0 : 1.0;
        for (int x = -2; x <= 2; ++x) {
            float wx = x == 0 ? 6.0 : abs(x) == 1 ? 4.0 : 1.0;
            result += sceneSample(clamp(uv + vec2(float(x), float(y)) * stride,
                vec2(0.001), vec2(0.999))) * wx * wy;
        }
    }
    return result / 256.0;
}

// TERMINAL_GLASS_OPTICS

vec3 kittyBackdropFor(vec3 material) {
    material = clamp(material * terminalBrightness, 0.0, 1.0);
    float clientAlpha = floor(barTint.a * 255.0 + 0.5) / 255.0;
    vec3 clientColor = floor(barTint.rgb * barTint.a * 255.0 + 0.5) / 255.0;
    return (material - clientColor * clientAlpha) / max(1.0 - clientAlpha, 0.0001);
}

vec3 barMaterialBrightness(vec3 material) {
    return barMaterial.x > 0.5 ? clamp(material * barBrightness, 0.0, 1.0) : material;
}

// Independent optical model for material 3. The distance field is the complete
// connected surface, including joins; window ownership never creates a lens edge.
vec3 opticalRead(vec2 coordinate, float smoothing) {
    vec3 value = vec3(0.0);
    for (int row=-1;row<=1;++row) for (int column=-1;column<=1;++column) {
        float weight = (row==0 ? 2.0 : 1.0)*(column==0 ? 2.0 : 1.0);
        vec2 sampleUv = (coordinate+vec2(float(column),float(row))*smoothing*0.86)/fullSize;
        value += sceneSample(clamp(sampleUv,0.5/fullSize,1.0-0.5/fullSize))*weight;
    }
    return value/16.0;
}

vec3 opticalSurface(vec2 location, float distanceToSurface, vec2 outward) {
    float unit = max(opticalScale, 0.1);
    float interior = max(0.0, -distanceToSurface) / unit;
    float sheetHeight = max(1.0,2.0*bottomRight.y);
    float middle = (windowTopLeft.y+windowBottomRight.y)*fullSize.y*0.5+topLeft.y;
    if (frameInterior.w>0.0) { middle=fullSize.y*0.5; sheetHeight=fullSize.y; }
    float shoulder = 1.45*min(26.0,sheetHeight/unit*0.36);
    float run = 1.0 - clamp(interior / shoulder, 0.0, 1.0);
    // Differentiate y=(1-x^4)^(1/4), then build a 3D surface normal.
    float elevation = pow(max(0.001, 1.0 - run*run*run*run), 0.25);
    float tangent = min(7.0, pow(run / elevation, 3.0));
    vec3 normal3 = normalize(vec3(outward * tangent, 1.0));
    vec3 transmitted = refract(vec3(0.0, 0.0, -1.0), normal3, 2.0/3.0);
    float strength = clamp(barRefractionStrength, 0.0, 10.0);
    vec2 travel = transmitted.xy * (47.52 * unit * strength / max(0.2, -transmitted.z));

    // Shared frame owners use one sheet centre and one vertical lens, so the
    // optical field continues through a join without a second panel lens.
    float vertical = (middle-location.y)*0.128*strength;
    vec2 ray = location + vec2(0.0, vertical) + travel;
    vec2 separation = travel * 0.0468;
    float smoothing = 1.5*unit*mix(0.45,1.0,smoothstep(0.0,shoulder,interior));
    vec3 result;
    result.r = opticalRead(ray+separation,smoothing).r;
    result.g = opticalRead(ray,smoothing).g;
    result.b = opticalRead(ray-separation,smoothing).b;

    float luminanceValue = dot(result,vec3(0.2126,0.7152,0.0722));
    result = mix(vec3(luminanceValue),result,1.25);
    vec3 pigment = mix(vec3(0.09,0.09,0.10),vec3(1.0),frost.y);
    result = mix(result,pigment,clamp(barTint.a * 0.55,0.0,1.0));
    result += mix(0.020,0.055,frost.y);
    float downSheet = clamp((location.y-middle)/sheetHeight+0.5,0.0,1.0);
    result += (1.0-downSheet)*mix(0.030,0.040,frost.y);
    result *= 1.0 - 0.12*exp(-interior/6.0)*max(outward.y,0.0);
    result *= 1.0 - 0.10*exp(-interior/(shoulder*0.45));

    float facingLight = dot(outward,normalize(vec2(-0.55,-0.83)));
    float reflection = pow(max(0.0,facingLight),1.6)
        + 0.55*pow(max(0.0,-facingLight),2.2);
    float contourLight = exp(-interior/1.1)*(0.18+0.78*reflection)
        + exp(-interior/5.0)*(0.030+0.10*reflection);
    float ringDistance = (interior-shoulder*0.5)/(shoulder*0.2+1.0);
    contourLight += 0.07*(0.35+reflection)*exp(-ringDistance*ringDistance);
    result += vec3(0.96,0.98,1.0)*contourLight*0.45*mix(1.0,0.85,frost.y);
    // A fixed, neutral grain never shimmers with the frame timer.
    float grainA = fract(sin(dot(floor(location),vec2(127.1,311.7)))*43758.5453);
    float grainB = fract(sin(dot(floor(location)+19.0,vec2(269.5,183.3)))*41579.2341);
    return clamp(result+(grainA+grainB-1.0)*0.006,0.0,1.0);
}

// Keep this color field aligned with shaders/topbar-connected.frag.
float barLightWeight(vec2 point, vec4 light, float span) {
    if (light.w <= 0.001) return 0.0;
    float t = clamp(light.z, 0.0, 1.0);
    vec2 offset = point - light.xy;
    float distance = length(offset);
    float reach = 36.0 + max(span, 320.0) * 0.82 * t;
    float band = 50.0 + reach * 0.30;
    float wave = exp(-pow((distance - reach) / band, 2.0));
    float wake = exp(-distance / max(55.0, reach * 0.82)) * 0.32;
    float vertical = exp(-abs(offset.y) / (85.0 + reach * 1.10));
    return clamp((wave * 0.78 + wake) * vertical * light.w, 0.0, 0.60);
}
vec4 barLightField(vec2 point, vec4 light, float span, bool alert) {
    float weight = barLightWeight(point, light, span);
    if (weight <= 0.0) return vec4(0.0);
    float t = clamp(light.z, 0.0, 1.0);
    float distance = length(point - light.xy);
    float spectrum = 0.5 + 0.5 * sin((point.x - light.x) * 0.012 - t * 5.0 + point.y * 0.018);
    vec3 hue = mix(vec3(0.25, 0.50, 0.93), vec3(0.84, 0.32, 0.58), spectrum);
    hue = mix(hue, vec3(0.53, 0.36, 0.86), 0.30 + 0.18 * sin(t * 6.0 + distance * 0.008));
    if (alert) hue = vec3(0.84, 0.32, 0.38);
    return vec4(hue, weight);
}
vec3 barLightColor(vec3 base, vec2 point, vec4 light, float span, bool alert) {
    vec4 field = barLightField(point, light, span, alert);
    return mix(base, field.rgb, field.a) + field.rgb * field.a * 0.035;
}
vec3 applyChargingLight(vec3 base, vec2 pixel) {
    if (terminalBackdrop > 0.5 || thick < 2.5) return base;
    base = barLightColor(base, pixel, chargingLight, fullSize.x, false);
    // Let each beat travel to completion. Overlapping waves share a bounded
    // field instead of accumulating eight layers of brightness/opacity.
    vec3 musicHue = vec3(0.0);
    float musicWeight = 0.0, musicIntensity = 0.0;
    for (int i = 0; i < 8; ++i) {
        vec4 light = musicLights[i];
        float weight = barLightWeight(pixel, light, fullSize.x);
        if (weight <= 0.0) continue;
        float blend = .5 + .5 * sin((pixel.x - light.x) * .012 - light.z * 5.0 + pixel.y * .018);
        vec4 field = vec4(mix(musicColors[i * 2], musicColors[i * 2 + 1], blend), weight);
        musicHue += field.rgb * field.a;
        musicWeight += field.a;
        musicIntensity = max(musicIntensity, field.a);
    }
    musicHue /= max(musicWeight, 0.0001);
    base = mix(base, musicHue, musicIntensity) + musicHue * musicIntensity * 0.035;
    return barLightColor(base, pixel, timerLight, fullSize.x, true);
}

void main() {
    vec2 panelUv = clamp(v_texcoord, 0.0, 1.0);
    vec2 panelSpan = windowBottomRight - windowTopLeft;
    vec2 panelPixels = max(panelSpan * fullSize, vec2(1.0));
    vec2 local = (panelUv - 0.5) * panelPixels;
    float mainDistance = thick > 3.5 ? compositionSdf(local)
        : thick > 2.5 ? connectedTopbarSdf(local)
        : thick > 1.5 ? rightMenuSdf(local)
        : mainShapeSdf(local);
    float dialDistance = thick > 0.5 && thick < 1.5
        ? roundedBoxSdf(local - uvOffset, uvSize, radiusOuter) : 1e6;
    float joinSoftness = min(48.0, max(10.0, radiusOuter * 0.38));
    float sdf = thick > 0.5 && thick < 1.5
        ? smoothUnion(mainDistance, dialDistance, joinSoftness)
        : mainDistance;
    if (barMaterial.x > 0.5 && (frameRadius > 0.0 || frameFold.x > 0.0)) {
        bool desktopPass = barMaterial.x > 1.5;
        if (desktopPass && frameFold.x >= .9999) discard;
        vec2 pixel = local + (windowTopLeft + windowBottomRight) * fullSize * 0.5;
        if (!desktopPass && frameTopPanel.w > .005 && pixel.y >= frameInterior.y) {
            float body = roundedBoxSdf(pixel - frameTopPanel.xy, frameTopPanel.zw,
                min(frameTopMetrics.z, frameTopPanel.w));
            if (body <= frameTopMetrics.w + 1.25) {
                // Preserve sidebar controls above their own material. Only
                // ownership changes at the rail; both passes use the complete
                // field before refraction, with no old inner edge underneath.
                bool rail = pixel.x < frameInterior.x
                    || pixel.x > frameInterior.x + frameInterior.z;
                if ((thick > 3.5) != rail) discard;
            }
        }
        if (frameFold.x < .9999) {
            // Partition ownership, never the geometric/optical field. Both
            // passes evaluate the complete frame + wave before taking its
            // normals, so a high peak removes the old rail/menu rim inside it.
            // Include only the 1.25 px antialias fringe, not an empty 32 px
            // exclusion margin beside a right-hand menu.
            float upperShape = frameBaseSdf(pixel);
            upperShape = thick > 3.5 ? connectSidebar(upperShape, local)
                : connectTopbar(upperShape, local);
            float bottomJoin = frameInterior.y + frameInterior.w - frameRadius - 2.0;
            bool upperOwns = pixel.y < bottomJoin && upperShape <= 1.25;
            if (desktopPass == upperOwns) discard;
        }
        // The editor is above sidebar controls; leave their existing rail
        // pixels intact when Settings are connected.
        if (desktopPass && bottomPanel.w > 0.0 && pixel.y < frameInterior.y + frameInterior.w
                && (pixel.x < frameInterior.x || pixel.x > frameInterior.x + frameInterior.z)) discard;
    }
    if (frameFusion > .5 && barMaterial.x > .5) {
        vec2 pixel = local + (windowTopLeft + windowBottomRight) * fullSize * .5;
        float bottomJoin = frameInterior.y + frameInterior.w - frameRadius - 2.0;
        // Use the very same unshaded source on both sides of the join. Blend
        // only above the shared contour; the panel still shows live clients
        // behind the rest of its body. The wave amplitude itself is unchanged.
        float waveJoin = 1.0 - smoothstep(1.25, 33.25, desktopWaveSdf(pixel));
        frameBackdropMix = max(waveJoin, smoothstep(bottomJoin - 36.0, bottomJoin - 2.0, pixel.y));
    }
    float coverage = terminalBackdrop > 0.5 ? 1.0 : 1.0 - smoothstep(-1.25, 1.25, sdf);
    if (coverage <= 0.001)
        discard;

    if (barMaterial.x > 0.5 && kittyMatch.x > 0.5) {
        vec2 basePixels = mix(windowTopLeft, windowBottomRight, panelUv) * fullSize;
        vec4 optics = terminalGlassOptics(basePixels - kittyLensBox.xy,
            kittyLensBox.zw, max(0.0, -sdf), kittyMatch.y, kittyMatch.z, kittyMatch.w);
        vec2 uv = clamp((basePixels - optics.xy) / fullSize,
            0.5 / fullSize, 1.0 - 0.5 / fullSize);
        vec3 material = mix(blurSample(uv), sceneSample(uv), optics.z);
        material = max(material + vec3(optics.w), vec3(0.0));
        // Kitty applies its background colour/alpha in the original client
        // pass. Bars apply that same managed colour/alpha after the lens.
        material = mix(material, barTint.rgb, barTint.a);
        material = applyChargingLight(material, basePixels);
        material = barMaterialBrightness(material);
        float outputAlpha = clamp(alpha * coverage, 0.0, 1.0);
        fragColor = vec4(material * outputAlpha, outputAlpha);
        return;
    }

    if (barMaterial.x > 0.5 && barMaterial.y < 1.5) {
        vec2 uv = mix(windowTopLeft, windowBottomRight, panelUv);
        // tex already contains Hyprland's blur when enabled. Do not replace
        // the compositor's configured passes with a private sampling kernel.
        vec3 background = sceneSample(uv);
        vec3 surface = mix(background, barTint.rgb, barTint.a);
        surface = applyChargingLight(surface, uv * fullSize);
        surface = barMaterialBrightness(surface);
        if (terminalBackdrop > 0.5) surface = kittyBackdropFor(surface);
        fragColor = vec4(surface * coverage, coverage);
        return;
    }

    if (barMaterial.x > 0.5 && barMaterial.y > 2.5) {
        vec2 fieldGradient = vec2(
            compositionSdf(local+vec2(0.5,0.0))-compositionSdf(local-vec2(0.5,0.0)),
            compositionSdf(local+vec2(0.0,0.5))-compositionSdf(local-vec2(0.0,0.5)));
        vec2 surfaceDirection = fieldGradient/max(length(fieldGradient),0.0001);
        vec2 location = mix(windowTopLeft,windowBottomRight,panelUv)*fullSize;
        vec3 material = opticalSurface(location,sdf,surfaceDirection);
        material = applyChargingLight(material,location);
        material = barMaterialBrightness(material);
        if (terminalBackdrop > 0.5) material = kittyBackdropFor(material);
        float outputAlpha = clamp(alpha*coverage,0.0,1.0);
        fragColor = vec4(material*outputAlpha,outputAlpha);
        return;
    }

    float edgeWidth = max(8.0, contrast);
    float edge = 1.0 - smoothstep(0.0, edgeWidth, -sdf);
    float lens = pow(clamp(edge, 0.0, 1.0), 1.38);

    const float gradientStep = 1.0;
    vec2 sdfGradient = vec2(
        compositionSdf(local + vec2(gradientStep, 0.0))
            - compositionSdf(local - vec2(gradientStep, 0.0)),
        compositionSdf(local + vec2(0.0, gradientStep))
            - compositionSdf(local - vec2(0.0, gradientStep))
    );
    float gradientLength = length(sdfGradient);
    vec2 normal = sdfGradient / max(gradientLength, 1.0);
    // Suppress optical cusps where two curved edges meet at a medial axis.
    lens *= smoothstep(0.4, 1.8, gradientLength);
    vec2 baseUv = mix(windowTopLeft, windowBottomRight, panelUv);
    vec2 activeCenter = thick > 1.5 ? uvOffset
        : (dialDistance < mainDistance ? uvOffset : topLeft);
    vec2 shapeLocal = local - activeCenter;

    // The weak centre magnification preserves recognizable backdrop shapes;
    // displacement then rises sharply through the optically thick rim.
    // Compact widget lenses need a much shorter focal distance than the large
    // lock panel. Reusing the panel magnification made straight card bodies
    // look skewed whenever a high-contrast strand crossed their rim.
    float compactLens = step(0.5, pointer_shape.z);
    float barLens = step(0.5, pointer_shape.w);
    float magnificationStrength = mix(0.025, 0.018, compactLens);
    magnificationStrength = mix(magnificationStrength, 0.0, barLens);
    float barGain = barMaterial.x > 0.5 ? clamp(barRefractionStrength, 0.0, 10.0) : 1.0;
    // Keep the established rim profile above 1x. Multiplying its narrow SDF
    // lens by ten would fold the ray map at the centre of a thin bar.
    float rimGain = min(barGain, 1.0);
    vec2 magnification = -shapeLocal * magnificationStrength * rimGain / fullSize;
    vec2 displacement = -normal * distort * lens * rimGain / fullSize;
    // The unified bar inherits the lockscreen lens, but without visible pool
    // waves. Two very slow, non-repeating bends move only the refracted
    // wallpaper and keep the QML icons perfectly still.
    vec2 flowPoint = (baseUv * fullSize) / max(0.55, pointer_position.w);
    vec2 flow = vec2(
        sin(flowPoint.y * 0.020 + time * 0.42)
            + 0.48 * sin(flowPoint.x * 0.009 - time * 0.27),
        cos(flowPoint.x * 0.014 - time * 0.34)
            + 0.42 * cos(flowPoint.y * 0.011 + time * 0.23));
    vec2 animatedBend = flow * distort * (0.20 + lens * 0.24)
        * mix(0.60, 0.16, barLens) * rimGain / fullSize;
    float panelScale = max(0.55, pointer_position.w);
    vec2 designPoint = (local - topLeft) / panelScale + vec2(800.0, 408.0);
    vec3 caustics = pointer_position.z > 0.5
        ? poolCaustics(designPoint, pointer_position.x,
                       pointer_position.y) : vec3(0.0);
    vec2 refractedUv = baseUv + magnification + displacement
        + animatedBend
        + caustics.xy * panelScale / fullSize;
    // Strong settings add a continuous lens across the output. Both frame
    // passes and every connected menu use the same coordinates, so a join
    // cannot acquire two different optical fields. Each axis is independent:
    // even the thin strip at the physical screen edge refracts visibly.
    // At 10x the added map still has positive slopes (at least 0.73).
    vec2 sceneQ = clamp(refractedUv * 2.0 - 1.0, vec2(-1.0), vec2(1.0));
    refractedUv -= (refractedUv - 0.5) * (1.0 - sceneQ * sceneQ)
        * (0.03 * max(barGain - 1.0, 0.0));
    refractedUv = clamp(refractedUv, vec2(0.001), vec2(0.999));

    // The backdrop is copied with a straight framebuffer blit, so its texture
    // uses the same UV orientation as the window bounds above. Do not flip Y.
    // Clear glass keeps fine wallpaper details without a diffusion kernel.
    vec3 glass = sceneSample(refractedUv);

    // Subtle wavelength separation is visible only at the curved rim.
    vec2 spectral = normal * noise * lens * rimGain / fullSize;
    glass.r = sceneSample(clamp(refractedUv + spectral, 0.001, 0.999)).r;
    glass.b = sceneSample(clamp(refractedUv - spectral, 0.001, 0.999)).b;

    if (frost.x > 0.5) {
        float bodyDiffusion = 0.96 - 0.50 * lens;
        glass = mix(glass, frostedBackdrop(refractedUv, panelScale), bodyDiffusion);
        vec3 readableTint = mix(vec3(0.055, 0.065, 0.08), vec3(0.91, 0.925, 0.945), frost.y);
        glass = mix(glass, readableTint, bodyDiffusion * 0.30);
    }
    float gray = luminance(glass);
    // Retain the source chroma, with a small optical vibrancy lift.
    float chromaLift = 1.0 + vibrancy * 0.16;
    glass = mix(vec3(gray), glass, chromaLift);
    glass = (glass - 0.5) * 1.035 + 0.5;
    glass *= brightness;

    // The tint responds to the backdrop instead of covering it with a fixed
    // opaque film. Dark areas catch slightly more milky light.
    float adaptiveTint = color.a * mix(1.62, 0.44, smoothstep(0.16, 0.80, gray))
        * mix(1.0, 0.30, barLens);
    glass = mix(glass, color.rgb, adaptiveTint);

    // Neutral pool light: bright ridges and a very soft trough retain the
    // wallpaper palette instead of borrowing the current Pywal accent.
    float causticsLines = pointer_shape.x * pointer_position.z;
    glass *= 1.0 - pointer_position.y * causticsLines
        * (1.0 - min(caustics.z, 1.0)) * 0.018;
    glass += vec3(0.90, 0.97, 1.0) * caustics.z
        * causticsLines * 0.115;

    float rim = exp(-abs(sdf) / 2.25);
    float innerRim = exp(-abs(sdf + 10.0) / 8.5) * lens;
    float directional = 0.42 + 0.58 * clamp(dot(normal, normalize(vec2(-0.62, -0.78))) * 0.5 + 0.5, 0.0, 1.0);
    float adaptiveLight = mix(1.12, 0.54, smoothstep(0.18, 0.82, gray));
    glass += vec3(1.0, 1.0, 1.03) * rim * directional * adaptiveLight
        * mix(0.46, 0.25, barLens);
    glass -= glass * innerRim * (1.0 - directional) * 0.13;

    float grain = 0.0;
    glass += vec3(grain);
    glass = clamp(glass, 0.0, 1.0);
    if (barMaterial.x > 0.5)
        glass = mix(glass, barTint.rgb, barTint.a);
    glass = applyChargingLight(glass, baseUv * fullSize);
    glass = barMaterialBrightness(glass);
    if (terminalBackdrop > 0.5) glass = kittyBackdropFor(glass);

    float outputAlpha = clamp(alpha * coverage, 0.0, 1.0);
    fragColor = vec4(glass * outputAlpha, outputAlpha);
}
)GLSL";

constexpr auto DESKTOP_BLUR_FRAGMENT = R"GLSL(#version 300 es

precision highp float;

in vec2 v_texcoord;

uniform sampler2D tex;
uniform vec2 fullSize;
uniform float alpha;
uniform float distort;
uniform float brightness;
uniform float vibrancy;

layout(location = 0) out vec4 fragColor;

float luminance(vec3 sampleColor) {
    return dot(sampleColor, vec3(0.2126, 0.7152, 0.0722));
}

void main() {
    vec2 uv = clamp(v_texcoord, vec2(0.001), vec2(0.999));
    vec2 stride = vec2(max(1.5, distort * 0.52)) / max(fullSize, vec2(1.0));
    vec3 blurred = vec3(0.0);

    // A private 7x7 pass restores the lock backdrop independently of the
    // user's global Hyprland blur radius. Constant bounds keep this smooth on
    // GLES while preserving 60 Hz motion on an integrated GPU.
    for (int row = -3; row <= 3; ++row) {
        for (int column = -3; column <= 3; ++column) {
            vec2 offset = vec2(float(column), float(row)) * stride;
            blurred += texture(tex, clamp(uv + offset, vec2(0.001), vec2(0.999))).rgb;
        }
    }
    blurred /= 49.0;
    float gray = luminance(blurred);
    blurred = mix(vec3(gray), blurred, 1.0 + vibrancy * 0.10);
    blurred *= brightness;
    float outputAlpha = clamp(alpha, 0.0, 1.0);
    fragColor = vec4(clamp(blurred, 0.0, 1.0) * outputAlpha, outputAlpha);
}
)GLSL";

// Source-space Gaussian filtering: two perpendicular passes prepare a texture
// before any optical displacement. Adjacent taps share one bilinear fetch.
constexpr auto OPTICAL_BLUR_FRAGMENT = R"GLSL(#version 300 es
precision highp float;
in vec2 v_texcoord;
uniform sampler2D tex;
uniform vec2 fullSize;
uniform vec2 uvOffset;
uniform float radius;
layout(location=0) out vec4 fragColor;
void main() {
    vec2 uv = vec2(v_texcoord.x,gl_FragCoord.y/fullSize.y);
    vec2 minimumUv = 0.5/fullSize;
    vec2 maximumUv = 1.0-minimumUv;
    float sigmaSquared = max(0.01,radius*radius);
    float limit = min(24.0,ceil(3.0*radius));
    vec4 filtered = texture(tex,clamp(uv,minimumUv,maximumUv));
    float normalization = 1.0;
    for (int index=1;index<25;index+=2) {
        float first = float(index);
        if (first>limit) break;
        float second = first+1.0;
        float firstWeight = exp(-0.5*first*first/sigmaSquared);
        float secondWeight = second<=limit ? exp(-0.5*second*second/sigmaSquared) : 0.0;
        float combined = firstWeight+secondWeight;
        vec2 stepUv = uvOffset*(first*firstWeight+second*secondWeight)/combined;
        filtered += combined*(texture(tex,clamp(uv+stepUv,minimumUv,maximumUv))
            + texture(tex,clamp(uv-stepUv,minimumUv,maximumUv)));
        normalization += 2.0*combined;
    }
    fragColor = filtered/normalization;
}
)GLSL";

class CScopedBlurConfig {
  public:
    CScopedBlurConfig(const Config::INTEGER size, const Config::INTEGER passes) {
        m_sizePtr   = g_globalSize.ptr();
        m_passesPtr = g_globalPasses.ptr();
        m_oldSize   = *m_sizePtr;
        m_oldPasses = *m_passesPtr;
        *m_sizePtr  = std::clamp<Config::INTEGER>(size, 1, 40);
        *m_passesPtr = std::clamp<Config::INTEGER>(passes, 1, 8);
    }

    ~CScopedBlurConfig() {
        *m_sizePtr   = m_oldSize;
        *m_passesPtr = m_oldPasses;
    }

    CScopedBlurConfig(const CScopedBlurConfig&)            = delete;
    CScopedBlurConfig& operator=(const CScopedBlurConfig&) = delete;

  private:
    Config::INTEGER* m_sizePtr   = nullptr;
    Config::INTEGER* m_passesPtr = nullptr;
    Config::INTEGER  m_oldSize   = 0;
    Config::INTEGER  m_oldPasses = 0;
};

class CScopedOptics {
  public:
    CScopedOptics(const Config::FLOAT noise, const Config::FLOAT contrast,
                  const Config::FLOAT brightness, const Config::FLOAT vibrancy,
                  const Config::FLOAT vibrancyDarkness) {
        m_noisePtr = g_globalNoise.ptr();
        m_contrastPtr = g_globalContrast.ptr();
        m_brightnessPtr = g_globalBrightness.ptr();
        m_vibrancyPtr = g_globalVibrancy.ptr();
        m_vibrancyDarknessPtr = g_globalVibrancyDarkness.ptr();

        m_oldNoise = *m_noisePtr;
        m_oldContrast = *m_contrastPtr;
        m_oldBrightness = *m_brightnessPtr;
        m_oldVibrancy = *m_vibrancyPtr;
        m_oldVibrancyDarkness = *m_vibrancyDarknessPtr;

        *m_noisePtr = std::clamp<Config::FLOAT>(noise, 0.F, 1.F);
        *m_contrastPtr = std::clamp<Config::FLOAT>(contrast, 0.F, 2.F);
        *m_brightnessPtr = std::clamp<Config::FLOAT>(brightness, 0.F, 2.F);
        *m_vibrancyPtr = std::clamp<Config::FLOAT>(vibrancy, 0.F, 1.F);
        *m_vibrancyDarknessPtr = std::clamp<Config::FLOAT>(vibrancyDarkness, 0.F, 1.F);
    }

    ~CScopedOptics() {
        *m_noisePtr = m_oldNoise;
        *m_contrastPtr = m_oldContrast;
        *m_brightnessPtr = m_oldBrightness;
        *m_vibrancyPtr = m_oldVibrancy;
        *m_vibrancyDarknessPtr = m_oldVibrancyDarkness;
    }

    CScopedOptics(const CScopedOptics&) = delete;
    CScopedOptics& operator=(const CScopedOptics&) = delete;

  private:
    Config::FLOAT* m_noisePtr = nullptr;
    Config::FLOAT* m_contrastPtr = nullptr;
    Config::FLOAT* m_brightnessPtr = nullptr;
    Config::FLOAT* m_vibrancyPtr = nullptr;
    Config::FLOAT* m_vibrancyDarknessPtr = nullptr;
    Config::FLOAT m_oldNoise = 0.F;
    Config::FLOAT m_oldContrast = 1.F;
    Config::FLOAT m_oldBrightness = 1.F;
    Config::FLOAT m_oldVibrancy = 0.F;
    Config::FLOAT m_oldVibrancyDarkness = 0.F;
};

void* findDrawTex() {
    for (const auto& match : HyprlandAPI::findFunctionsByName(g_handle, "drawTex")) {
        if (match.demangled.contains("IElementRenderer::drawTex("))
            return match.address;
    }
    return nullptr;
}

void* findGLDrawTex() {
    for (const auto& match : HyprlandAPI::findFunctionsByName(g_handle, "draw")) {
        if (match.demangled.contains("CGLElementRenderer::draw(") &&
            match.demangled.contains("CTexPassElement"))
            return match.address;
    }
    return nullptr;
}

bool ensureLiquidShader() {
    if (g_liquidShader)
        return true;
    if (g_liquidShaderFailed || !Render::GL::g_pHyprOpenGL)
        return false;

    auto shader = makeShared<CShader>();
    if (!shader->createProgram(LIQUID_GLASS_VERTEX, withTerminalGlassOptics(LIQUID_GLASS_FRAGMENT), true, true)) {
        g_liquidShaderFailed = true;
        return false;
    }

    g_liquidShader = std::move(shader);
    return true;
}

bool ensureDesktopShader() {
    if (g_desktopShader)
        return true;
    if (g_desktopShaderFailed || !Render::GL::g_pHyprOpenGL)
        return false;

    auto shader = makeShared<CShader>();
    if (!shader->createProgram(LIQUID_GLASS_VERTEX, DESKTOP_BLUR_FRAGMENT,
                               true, true)) {
        g_desktopShaderFailed = true;
        return false;
    }
    g_desktopShader = std::move(shader);
    return true;
}

CBox liquidPanelBox(const CBox& surfaceBox) {
    const double scale = std::min(surfaceBox.width / 1600.0, surfaceBox.height / 900.0);
    const double originX = (surfaceBox.width - 1600.0 * scale) * 0.5;
    const double originY = (surfaceBox.height - 900.0 * scale) * 0.5;
    return {
        surfaceBox.x + originX + 161.5 * scale,
        surfaceBox.y + originY + 103.0 * scale,
        1277.0 * scale,
        610.0 * scale,
    };
}

CRegion roundedPanelRegion(const CBox& box, const double radius) {
    CRegion region;
    const double safeRadius = std::clamp(
        radius, 0.0, std::min(box.width, box.height) * 0.5);
    if (safeRadius <= 0.5) {
        region.add(box);
        return region;
    }

    region.add(box.x, box.y + safeRadius,
               box.width, box.height - safeRadius * 2.0);
    constexpr int SEGMENTS = 16;
    const double slice = safeRadius / SEGMENTS;
    for (int index = 0; index < SEGMENTS; ++index) {
        const double localY = (index + 0.5) * slice;
        const double circleY = safeRadius - localY;
        const double inset = safeRadius - std::sqrt(std::max(
            0.0, safeRadius * safeRadius - circleY * circleY));
        const double sliceWidth = std::max(0.0, box.width - inset * 2.0);
        region.add(box.x + inset, box.y + index * slice,
                   sliceWidth, slice + 1.0);
        region.add(box.x + inset,
                   box.y + box.height - (index + 1) * slice,
                   sliceWidth, slice + 1.0);
    }
    return region;
}

CBox liquidTopbarBox(const CBox& surfaceBox, const STopbarMorph& shape) {
    return {
        surfaceBox.x + shape.x * surfaceBox.width,
        surfaceBox.y + shape.y * surfaceBox.height,
        shape.width * surfaceBox.width,
        shape.height * surfaceBox.height,
    };
}

CBox connectedTopbarMaterialBox(const CBox& surface, const STopbarMorph& shape,
                               const STopbarMorph& frame) {
    CBox body = liquidTopbarBox(surface, shape);
    if (frame.active && frame.x <= .5F && shape.height > .000001F) {
        const double rail = frame.width * surface.width * .5;
        const double gap = (shape.y - shape.barHeight) * surface.height;
        // A corner expansion grows out of the entire rail, rather than a
        // shallow overlap whose medial axis would refract as an internal line.
        const double attachment = std::clamp(1.0 - gap / 14.0, 0.0, 1.0)
            * std::clamp((rail + 12.0 - (body.x - surface.x)) / 12.0, 0.0, 1.0);
        const double extension = (body.x - surface.x) * attachment;
        body.x -= extension;
        body.width += extension;
    }
    return body;
}

CBox liquidSettingsBox(const CBox& surfaceBox) {
    return {
        surfaceBox.x + g_settingsMorph.x * surfaceBox.width,
        surfaceBox.y + g_settingsMorph.y * surfaceBox.height,
        g_settingsMorph.width * surfaceBox.width,
        g_settingsMorph.height * surfaceBox.height,
    };
}

CBox liquidRightMenuBox(const CBox& surfaceBox) {
    const double depth = std::max(
        g_rightMenuMorph.depth * surfaceBox.width,
        g_rightMenuMorph.railWidth * surfaceBox.width);
    const double halfHeight = g_rightMenuMorph.halfHeight * surfaceBox.height;
    const double centerY = surfaceBox.y
        + g_rightMenuMorph.centerY * surfaceBox.height;
    return {
        surfaceBox.x + surfaceBox.width - depth,
        centerY - halfHeight,
        depth,
        halfHeight * 2.0,
    };
}

CBox liquidRightMenuRailBox(const CBox& surfaceBox) {
    const double railWidth = g_rightMenuMorph.railWidth * surfaceBox.width;
    return {
        surfaceBox.x + surfaceBox.width - railWidth,
        surfaceBox.y,
        railWidth,
        surfaceBox.height,
    };
}

bool renderDesktopBackdrop(WP<CTexPassElement> element, const CRegion& damage) {
    if (!element || !g_clearBackdrop || !g_clearBackdrop->getTexture() || !ensureDesktopShader() ||
        !g_pHyprRenderer || !Render::GL::g_pHyprOpenGL)
        return false;

    const CBox surfaceBox = element->m_data.box;
    if (surfaceBox.width <= 0 || surfaceBox.height <= 0)
        return false;

    CRegion desktopDamage{surfaceBox};
    if (!damage.empty())
        desktopDamage.intersect(damage);
    if (desktopDamage.empty())
        return true;

    const auto& matrix = g_pHyprRenderer->projectBoxToTarget(surfaceBox);
    auto shader = Render::GL::g_pHyprOpenGL->useShader(g_desktopShader);
    if (!shader)
        return false;

    shader->setUniformMatrix3fv(SHADER_PROJ, 1, GL_TRUE, matrix.getMatrix());
    shader->setUniformInt(SHADER_TEX, 0);
    shader->setUniformFloat2(
        SHADER_FULL_SIZE,
        std::max(1.F, sc<float>(g_clearBackdrop->getTexture()->m_size.x)),
        std::max(1.F, sc<float>(g_clearBackdrop->getTexture()->m_size.y)));
    shader->setUniformFloat(SHADER_ALPHA,
                            1.F);
    shader->setUniformFloat(SHADER_DISTORT,
                            g_wallpaperBlur * 32.F);
    shader->setUniformFloat(SHADER_BRIGHTNESS,
                            1.F);
    shader->setUniformFloat(SHADER_VIBRANCY,
                            0.F);

    glActiveTexture(GL_TEXTURE0);
    g_clearBackdrop->getTexture()->bind();
    g_clearBackdrop->getTexture()->setTexParameter(GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    g_clearBackdrop->getTexture()->setTexParameter(GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    Render::GL::g_pHyprOpenGL->blend(true);
    glBindVertexArray(shader->getUniformLocation(SHADER_SHADER_VAO));
    desktopDamage.forEachRect([](const auto& rect) {
        Render::GL::g_pHyprOpenGL->scissor(
            &rect, g_pHyprRenderer->m_renderData.transformDamage);
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    });
    glBindVertexArray(0);
    g_clearBackdrop->getTexture()->unbind();
    Render::GL::g_pHyprOpenGL->scissor(nullptr);
    return true;
}

bool captureClearBackdrop(SP<Render::GL::CGLFramebuffer>& destination = g_clearBackdrop) {
    if (!g_pHyprRenderer || !Render::GL::g_pHyprOpenGL)
        return false;
    const auto source = g_pHyprRenderer->m_renderData.currentFB;
    if (!source || source->m_size.x <= 0 || source->m_size.y <= 0)
        return false;
    GLint readFB = 0, drawFB = 0, viewport[4];
    glGetIntegerv(GL_READ_FRAMEBUFFER_BINDING, &readFB);
    glGetIntegerv(GL_DRAW_FRAMEBUFFER_BINDING, &drawFB);
    glGetIntegerv(GL_VIEWPORT, viewport);
    const GLboolean scissorEnabled = glIsEnabled(GL_SCISSOR_TEST);
    if (!destination)
        destination = makeShared<Render::GL::CGLFramebuffer>("velora-clear-glass");
    const int width = sc<int>(source->m_size.x);
    const int height = sc<int>(source->m_size.y);
    const bool allocated = destination->alloc(width, height, source->m_drmFormat);
    if (allocated) {
        glDisable(GL_SCISSOR_TEST);
        glBindFramebuffer(GL_READ_FRAMEBUFFER, drawFB);
        glBindFramebuffer(GL_DRAW_FRAMEBUFFER, destination->getFBID());
        glBlitFramebuffer(0, 0, width, height, 0, 0, width, height,
                          GL_COLOR_BUFFER_BIT, GL_NEAREST);
        ++g_clearBackdropCopies;
    }
    glBindFramebuffer(GL_READ_FRAMEBUFFER, readFB);
    glBindFramebuffer(GL_DRAW_FRAMEBUFFER, drawFB);
    glViewport(viewport[0], viewport[1], viewport[2], viewport[3]);
    if (scissorEnabled)
        glEnable(GL_SCISSOR_TEST);
    return allocated;
}

SP<Render::ITexture> opticalBlurTexture(const SP<Render::ITexture>& source,
    const std::string& monitor, CRegion region, float scale,
    SP<Render::GL::CGLFramebuffer>* retained = nullptr) {
    if (!source || !g_pHyprRenderer || !Render::GL::g_pHyprOpenGL) return nullptr;
    if (!g_opticalBlurShader) {
        auto shader = makeShared<CShader>();
        if (!shader->createProgram(LIQUID_GLASS_VERTEX,OPTICAL_BLUR_FRAGMENT,true,true)) return nullptr;
        g_opticalBlurShader = std::move(shader);
    }
    auto& buffers = g_opticalBlurBuffers[monitor];
    if (!buffers.horizontal) buffers.horizontal = makeShared<Render::GL::CGLFramebuffer>("velora-optical-x");
    if (!buffers.vertical) buffers.vertical = makeShared<Render::GL::CGLFramebuffer>("velora-optical-y");
    const int width = sc<int>(source->m_size.x), height = sc<int>(source->m_size.y);
    if (!buffers.horizontal->alloc(width,height,DRM_FORMAT_ABGR16161616F)
            || !buffers.vertical->alloc(width,height,DRM_FORMAT_ABGR16161616F)) return nullptr;
    const auto target = g_pHyprRenderer->m_renderData.currentFB;
    GLint viewport[4]; glGetIntegerv(GL_VIEWPORT,viewport);
    const bool blend = glIsEnabled(GL_BLEND);
    Hyprutils::Utils::CScopeGuard restore{[target,viewport,blend]() {
        g_pHyprRenderer->bindFB(target);
        g_pHyprRenderer->setViewport(viewport[0],viewport[1],viewport[2],viewport[3]);
        Render::GL::g_pHyprOpenGL->blend(blend);
        Render::GL::g_pHyprOpenGL->scissor(nullptr);
    }};
    const float sigma = 3.5F*scale;
    CRegion verticalRegion{region};
    verticalRegion.intersect(CBox{0,0,sc<double>(width),sc<double>(height)});
    // The second pass reads neighbouring rows of the first pass. Its halo
    // must be valid too, especially after a tiny compositor damage update.
    CRegion horizontalRegion{verticalRegion};
    horizontalRegion.expand(static_cast<int>(std::ceil(3.F*sigma))+1);
    horizontalRegion.intersect(CBox{0,0,sc<double>(width),sc<double>(height)});
    const auto matrix = Mat3x3::outputProjection({width,height},HYPRUTILS_TRANSFORM_NORMAL)
        .projectBox(CBox{0,0,sc<double>(width),sc<double>(height)},HYPRUTILS_TRANSFORM_NORMAL);
    auto shader = Render::GL::g_pHyprOpenGL->useShader(g_opticalBlurShader);
    if (!shader) return nullptr;
    shader->setUniformMatrix3fv(SHADER_PROJ,1,GL_TRUE,matrix.getMatrix());
    shader->setUniformInt(SHADER_TEX,0);
    shader->setUniformFloat2(SHADER_FULL_SIZE,width,height);
    shader->setUniformFloat(SHADER_RADIUS,sigma);
    g_pHyprRenderer->setViewport(0,0,width,height);
    Render::GL::g_pHyprOpenGL->blend(false);
    glActiveTexture(GL_TEXTURE0);
    auto pass = [&](const SP<Render::ITexture>& input,
                    const SP<Render::GL::CGLFramebuffer>& output,
                    const CRegion& damage, float dx, float dy) {
        g_pHyprRenderer->bindFB(output);
        shader->setUniformFloat2(SHADER_UV_OFFSET,dx,dy);
        input->bind();
        input->setTexParameter(GL_TEXTURE_MIN_FILTER,GL_LINEAR);
        input->setTexParameter(GL_TEXTURE_MAG_FILTER,GL_LINEAR);
        glBindVertexArray(shader->getUniformLocation(SHADER_SHADER_VAO));
        damage.forEachRect([](const auto& rect) {
            Render::GL::g_pHyprOpenGL->scissor(&rect,false);
            glDrawArrays(GL_TRIANGLE_STRIP,0,4);
        });
        glBindVertexArray(0);
        input->unbind();
    };
    pass(source,buffers.horizontal,horizontalRegion,1.F/width,0.F);
    pass(buffers.horizontal->getTexture(),buffers.vertical,verticalRegion,0.F,1.F/height);
    auto texture = buffers.vertical->getTexture();
    if (retained) {
        if (!*retained) *retained = makeShared<Render::GL::CGLFramebuffer>("velora-optical-frame");
        if (!(*retained)->alloc(width,height,DRM_FORMAT_ABGR16161616F)) return nullptr;
        glDisable(GL_SCISSOR_TEST);
        glBindFramebuffer(GL_READ_FRAMEBUFFER,buffers.vertical->getFBID());
        glBindFramebuffer(GL_DRAW_FRAMEBUFFER,(*retained)->getFBID());
        glBlitFramebuffer(0,0,width,height,0,0,width,height,GL_COLOR_BUFFER_BIT,GL_NEAREST);
        texture = (*retained)->getTexture();
    }
    return texture;
}

SP<Render::ITexture> barBackdropTexture(const SP<Render::GL::CGLFramebuffer>& backdrop,
                                       CRegion damage, const bool blur,
                                       SP<Render::GL::CGLFramebuffer>* retained = nullptr) {
    if (!blur)
        return backdrop->getTexture();

    // Use the compositor's own dual-Kawase passes and decoration:blur
    // settings. Restore the render target before shading our alpha geometry;
    // blurFramebuffer leaves its last work buffer bound.
    const auto target = g_pHyprRenderer->m_renderData.currentFB;
    GLint viewport[4];
    glGetIntegerv(GL_VIEWPORT, viewport);
    auto texture = g_pHyprRenderer->blurFramebuffer(backdrop, 1.F, &damage);
    if (retained && captureClearBackdrop(*retained))
        texture = (*retained)->getTexture();
    g_pHyprRenderer->bindFB(target);
    g_pHyprRenderer->setViewport(viewport[0], viewport[1], viewport[2], viewport[3]);
    Render::GL::g_pHyprOpenGL->scissor(nullptr);
    return texture;
}

struct SBarLensParameters { float refraction, edgeWidth, dispersion; };
SBarLensParameters barLensParameters(float scale, float halfThickness) {
    const float reflection = std::sqrt(appearanceReflection());
    return {
        std::min(g_panelRefraction->value() * scale * 0.38F * reflection, halfThickness * 0.62F),
        std::min(g_panelEdgeWidth->value() * scale * 0.48F * reflection, std::max(8.F, halfThickness * 0.88F)),
        std::min(g_panelDispersion->value() * scale * reflection * 0.35F, std::max(0.45F, halfThickness * 0.07F)),
    };
}

bool renderLiquidBackdrop(WP<CTexPassElement> element, const CRegion& damage,
                          const bool topbar = false,
                          const bool rightMenu = false,
                          const bool settings = false,
                          const STopbarMorph* independentShape = nullptr,
                          const bool editor = false) {
    const auto layer = element ? element->m_data.currentLS.lock() : nullptr;
    const auto cachedFrame = layer && layer->m_monitor
        ? g_frameBackdrops.find(layer->m_monitor->m_name) : g_frameBackdrops.end();
    const std::string monitorName = layer && layer->m_monitor ? layer->m_monitor->m_name : "";
    const bool attachedSettings = layer && layer->m_namespace == EDITOR_NAMESPACE
        && topbar && hasBottomSettings(monitorName);
    const bool desktopWave = layer && (layer->m_namespace == SHARED_WIDGETS_NAMESPACE || attachedSettings);
    const auto fusedSource = g_frameFusionBackdrops.find(monitorName);
    const auto backdrop = desktopWave && !attachedSettings && fusedSource != g_frameFusionBackdrops.end()
        ? fusedSource->second.sharp
        : topbar && !desktopWave && cachedFrame != g_frameBackdrops.end()
            ? cachedFrame->second : g_clearBackdrop;
    if (!element || !backdrop || !backdrop->getTexture() || !ensureLiquidShader() ||
        !g_pHyprRenderer || !Render::GL::g_pHyprOpenGL)
        return false;

    const CBox surfaceBox = element->m_data.box;
    if ((topbar && (!independentShape || !independentShape->active)) ||
        (editor && (!independentShape || !independentShape->active)) ||
        (rightMenu && !g_rightMenuMorph.active) ||
        (settings && !g_settingsMorph.active))
        return false;

    const bool connectedTopbar = topbar && independentShape && independentShape->connected;
    const bool connectedSidebar = topbar && independentShape
        && (independentShape->bottomHeight > 0.F || independentShape->sideBodyWidth > 0.F);
    const auto& frameShape = unifiedBarShape(monitorName);
    const CBox panelBox = connectedTopbar
        ? connectedTopbarMaterialBox(surfaceBox, *independentShape, frameShape)
        : rightMenu ? liquidRightMenuBox(surfaceBox)
        : (settings ? liquidSettingsBox(surfaceBox)
                    : ((topbar || editor)
                        ? liquidTopbarBox(surfaceBox, *independentShape)
                              : liquidPanelBox(surfaceBox)));
    if ((!connectedTopbar && (panelBox.width <= 0 || panelBox.height <= 0)) || surfaceBox.width <= 0 || surfaceBox.height <= 0)
        return false;

    const double designScale = std::min(surfaceBox.width / 1600.0,
                                        surfaceBox.height / 900.0);
    const double designOriginY = (surfaceBox.height - 900.0 * designScale) * 0.5;
    const bool hasDial = !topbar && !rightMenu && !settings && !editor
        && g_dialMorph.active
        && g_dialMorph.depth > 0.5F
        && g_dialMorph.halfHeight > 0.5F;
    CBox dialBox = panelBox;
    CBox railBox = panelBox;
    CBox drawBox = panelBox;
    CBox sideLabelBox = {0, 0, 0, 0};
    CBox statusBox = {0, 0, 0, 0};
    CBox chargingBox = {0, 0, 0, 0};
    CBox timerBox = {0, 0, 0, 0};
    if (connectedTopbar) {
        const auto& status = independentShape->statusPanel;
        statusBox = {surfaceBox.x + status[0] * surfaceBox.width,
            surfaceBox.y + status[1] * surfaceBox.height,
            status[2] * surfaceBox.width, status[3] * surfaceBox.height};
        const auto& charging = independentShape->chargingPanel;
        chargingBox = {surfaceBox.x + charging[0] * surfaceBox.width,
            surfaceBox.y + charging[1] * surfaceBox.height,
            charging[2] * surfaceBox.width, charging[3] * surfaceBox.height};
        const auto& timer = independentShape->timerPanel;
        timerBox = {surfaceBox.x + timer[0] * surfaceBox.width,
            surfaceBox.y + timer[1] * surfaceBox.height,
            timer[2] * surfaceBox.width, timer[3] * surfaceBox.height};
        railBox = {surfaceBox.x, surfaceBox.y, surfaceBox.width,
                   std::round(independentShape->barHeight * surfaceBox.height)};
        drawBox = {surfaceBox.x, surfaceBox.y, surfaceBox.width,
                   std::max({railBox.height, panelBox.y + panelBox.height - surfaceBox.y,
                       statusBox.y + statusBox.height - surfaceBox.y,
                       chargingBox.y + chargingBox.height - surfaceBox.y,
                       timerBox.y + timerBox.height - surfaceBox.y})
                       + independentShape->joinSize * surfaceBox.width};
    }
    if (hasDial) {
        const double dialDepth = g_dialMorph.depth * designScale;
        const double dialHalfHeight = g_dialMorph.halfHeight * designScale;
        const double dialCenterY = surfaceBox.y + designOriginY
            + g_dialMorph.centerY * designScale;
        dialBox = {
            panelBox.x - dialDepth,
            dialCenterY - dialHalfHeight,
            dialDepth * 2.0,
            dialHalfHeight * 2.0,
        };
        const double left = std::min(panelBox.x, dialBox.x);
        const double top = std::min(panelBox.y, dialBox.y);
        const double right = std::max(panelBox.x + panelBox.width,
                                      dialBox.x + dialBox.width);
        const double bottom = std::max(panelBox.y + panelBox.height,
                                       dialBox.y + dialBox.height);
        drawBox = {left, top, right - left, bottom - top};
    }
    if (rightMenu) {
        railBox = liquidRightMenuRailBox(surfaceBox);
        const double left = std::min(panelBox.x, railBox.x);
        const double top = std::min(panelBox.y, railBox.y);
        const double right = std::max(panelBox.x + panelBox.width,
                                      railBox.x + railBox.width);
        const double bottom = std::max(panelBox.y + panelBox.height,
                                       railBox.y + railBox.height);
        drawBox = {left, top, right - left, bottom - top};
    }

    if (connectedSidebar) {
        const bool right = independentShape->x > 0.5F;
        const double edge = right ? panelBox.x : panelBox.x + panelBox.width;
        const double reach = independentShape->sideBodyWidth * surfaceBox.width;
        const double overlap = std::min(12.0 * surfaceBox.width / 1920.0, reach * 0.5);
        dialBox = {right ? edge - reach : edge - overlap,
            surfaceBox.y + independentShape->sideBodyY * surfaceBox.height,
            reach + overlap, independentShape->sideBodyHeight * surfaceBox.height};
        const double labelWidth = independentShape->sideLabelWidth * surfaceBox.width;
        sideLabelBox = {right ? edge - reach - labelWidth : edge + reach - overlap,
            surfaceBox.y + independentShape->sideLabelY * surfaceBox.height,
            labelWidth > 0 ? labelWidth + overlap : 0,
            independentShape->sideLabelHeight * surfaceBox.height};
        const double left = std::min(panelBox.x, labelWidth > 0 ? sideLabelBox.x : dialBox.x);
        const double rightEdge = std::max(panelBox.x + panelBox.width,
            labelWidth > 0 ? sideLabelBox.x + sideLabelBox.width : dialBox.x + dialBox.width);
        drawBox = {left, panelBox.y, rightEdge - left, panelBox.height};
        if (independentShape->bottomHeight > 0.F)
            drawBox = {surfaceBox.x, panelBox.y, surfaceBox.width, panelBox.height};
    }
    // The desktop host spans the physical output. Reconstructing its bottom
    // from the sidebar's rounded normalized y/height can stop a pixel short.
    // Use the host rectangle so the merged material reaches the last row.
    if (desktopWave && connectedSidebar) {
        drawBox = surfaceBox;
        drawBox.height += 2.0;
    }
    // The normalized layer rectangle can round down before the last physical
    // column. Extend only the drawing/scissor bounds, not the frame geometry.
    if (connectedSidebar && independentShape->oppositeWidth > 0.F)
        drawBox.width += 2.0;
    if (connectedSidebar && !desktopWave) {
        drawBox.x -= 2.0; drawBox.width += 4.0;
        drawBox.y -= 2.0; drawBox.height += 4.0;
    }
    CRegion liquidDamage{connectedTopbar ? railBox : panelBox};
    if (connectedSidebar)
        // Ownership includes the SDF antialias fringe. Keep that fringe inside
        // the draw/scissor as well, including a fractional rail edge at x=63.
        liquidDamage.add(CBox{panelBox.x - 2.0, panelBox.y - 2.0,
            panelBox.width + 4.0, panelBox.height + 4.0});
    if (connectedSidebar && independentShape->desktopFold > 0.F)
        liquidDamage.add(surfaceBox);
    if (connectedTopbar && panelBox.height > 0.01) {
        const double neck = independentShape->neckHalfWidth * surfaceBox.width;
        const double anchor = surfaceBox.x + independentShape->anchorX * surfaceBox.width;
        const double left = std::min(panelBox.x, anchor - neck) - 12;
        const double right = std::max(panelBox.x + panelBox.width, anchor + neck) + 12;
        liquidDamage.add(CBox{left, railBox.y + railBox.height, right - left,
            panelBox.y + panelBox.height - railBox.y - railBox.height + 12});
    }
    if (connectedTopbar && statusBox.height > 0.01) {
        const auto& status = independentShape->statusPanel;
        const double neck = status[5] * surfaceBox.width;
        const double anchor = surfaceBox.x + status[4] * surfaceBox.width;
        const double left = std::min(statusBox.x, anchor - neck) - 12;
        const double right = std::max(statusBox.x + statusBox.width, anchor + neck) + 12;
        liquidDamage.add(CBox{left, railBox.y + railBox.height, right - left,
            statusBox.y + statusBox.height - railBox.y - railBox.height + 12});
    }
    if (connectedTopbar && chargingBox.height > 0.01) {
        const auto& charging = independentShape->chargingPanel;
        const double neck = charging[5] * surfaceBox.width;
        const double anchor = surfaceBox.x + charging[4] * surfaceBox.width;
        const double left = std::min(chargingBox.x, anchor - neck) - 12;
        const double right = std::max(chargingBox.x + chargingBox.width, anchor + neck) + 12;
        liquidDamage.add(CBox{left, railBox.y + railBox.height, right - left,
            chargingBox.y + chargingBox.height - railBox.y - railBox.height + 12});
    }
    if (connectedTopbar && timerBox.height > 0.01) {
        const auto& timer = independentShape->timerPanel;
        const double neck = timer[5] * surfaceBox.width;
        const double anchor = surfaceBox.x + timer[4] * surfaceBox.width;
        const double left = std::min(timerBox.x, anchor - neck) - 12;
        const double right = std::max(timerBox.x + timerBox.width, anchor + neck) + 12;
        liquidDamage.add(CBox{left, railBox.y + railBox.height, right - left,
            timerBox.y + timerBox.height - railBox.y - railBox.height + 12});
    }
    if (connectedSidebar) {
        if (independentShape->waveDockProgress > .001 && independentShape->x <= .5F) {
            // Include the displaced edge in the actual render scissor, not
            // only in monitor damage; otherwise the new wave is clipped away.
            const double reach = (independentShape->width * .5F + independentShape->sideWaveWidth * .5F
                + independentShape->radius) * surfaceBox.width + 4;
            liquidDamage.add(CBox{surfaceBox.x, surfaceBox.y, reach, surfaceBox.height});
        }
        liquidDamage.add(CBox{dialBox.x - 12, dialBox.y - 12, dialBox.width + 24, dialBox.height + 24});
        if (sideLabelBox.width > 0)
            liquidDamage.add(CBox{sideLabelBox.x - 12, sideLabelBox.y - 12,
                sideLabelBox.width + 24, sideLabelBox.height + 24});
        const double bottom = independentShape->bottomHeight * surfaceBox.height;
        const auto material = layer && layer->m_monitor
            ? g_desktopBarMaterials.find(layer->m_monitor->m_name) : g_desktopBarMaterials.end();
        const double bottomCorners = independentShape->radius * surfaceBox.width + 2.0;
        const double peaks = desktopWave && material != g_desktopBarMaterials.end() && material->second.spectrum
            ? std::max(bottomCorners, 182.0 * layer->m_monitor->m_scale) : bottomCorners;
        liquidDamage.add(CBox{surfaceBox.x, surfaceBox.y + surfaceBox.height - bottom - peaks,
                             surfaceBox.width, bottom + peaks});
        liquidDamage.add(CBox{surfaceBox.x + (independentShape->x > 0.5F
            ? surfaceBox.width - panelBox.width * 0.5 - 28 : 0), surfaceBox.y,
            panelBox.width * 0.5 + 28, 28});
        if (independentShape->oppositeWidth > 0.F) {
            const double edgeWidth = (independentShape->oppositeWidth + independentShape->oppositePanel[1] + independentShape->oppositeLabel[1]) * surfaceBox.width + bottomCorners;
            liquidDamage.add(CBox{surfaceBox.x + (independentShape->x > 0.5F ? 0 : surfaceBox.width - edgeWidth),
                surfaceBox.y, edgeWidth, surfaceBox.height});
        }
        CBox clipBox = surfaceBox;
        if (independentShape->oppositeWidth > 0.F) {
            liquidDamage.add(CBox{surfaceBox.x + surfaceBox.width - 2.0,
                surfaceBox.y, 4.0, surfaceBox.height});
            clipBox.width += 2.0;
        }
        if (desktopWave) {
            // Cover the physical edge despite fractional pass/scissor bounds.
            liquidDamage.add(CBox{surfaceBox.x, surfaceBox.y + surfaceBox.height - 2.0,
                surfaceBox.width, 4.0});
            clipBox.height += 2.0;
        }
        liquidDamage.intersect(clipBox);
    }
    if (attachedSettings) {
        const auto& panel = g_bottomSettings.at(monitorName);
        const double join = panel.joinSize * surfaceBox.width + 2.0;
        liquidDamage.add(CBox{surfaceBox.x + panel.x * surfaceBox.width - join,
            surfaceBox.y + panel.y * surfaceBox.height - 2.0,
            panel.width * surfaceBox.width + 2.0 * join,
            (1.0 - panel.y) * surfaceBox.height + 4.0});
    }
    if (hasDial)
        liquidDamage.add(dialBox);
    if (rightMenu)
        liquidDamage.add(railBox);
    if (!damage.empty())
        liquidDamage.intersect(damage);
    if (liquidDamage.empty())
        return true;

    const std::string frameMonitor = layer && layer->m_monitor ? layer->m_monitor->m_name : "";
    const auto material = g_desktopBarMaterials.find(frameMonitor);
    const bool sharedMaterial = (connectedTopbar || connectedSidebar)
        && material != g_desktopBarMaterials.end();
    static auto compositorBlur = CConfigValue<Config::INTEGER>("decoration:blur:enabled");
    const bool matchingKitty = sharedMaterial && g_terminalBarMatch;
    const bool optical = sharedMaterial && material->second.mode == 3 && !matchingKitty;
    const bool clearBar = sharedMaterial && material->second.mode > 1.5F
        && !matchingKitty && !g_liquidFrosted;
    const bool nativeBlur = sharedMaterial && !clearBar && (matchingKitty || material->second.blur)
        && g_barBlurEnabled && (optical || *compositorBlur);
    auto* fusion = fusedSource != g_frameFusionBackdrops.end() ? &fusedSource->second : nullptr;
    CRegion samplingDamage{liquidDamage};
    if (nativeBlur && (matchingKitty || material->second.mode > 1.5F)) {
        const float width = backdrop->m_size.x;
        const float height = backdrop->m_size.y;
        const float scale = surfaceBox.width / 1600.F;
        const float reflection = std::sqrt(appearanceReflection());
        // blurFramebuffer expands for its own kernel, not for our refracted
        // rays. Otherwise a strong lens samples cleared/stale work-buffer
        // pixels beside a menu, especially during partial damage updates.
        const float localPixels = (g_panelRefraction->value() * .38F * 1.11F
            + g_panelDispersion->value() * .35F) * scale * reflection;
        const float kittyStrength = terminalGlassStrength();
        const float kittyOptical = 1.4F * kittyStrength / (1.F + .4F * kittyStrength);
        const float kittyPixels = kittyOptical * (.14F * std::min(width, height)
            / (3.F * std::sqrt(3.F)) + TERMINAL_REFRACTION_PIXELS
                * (layer && layer->m_monitor ? layer->m_monitor->m_scale : 1.F));
        samplingDamage.expand(barRefractionSamplePadding(matchingKitty ? 1.F : barRefractionStrength(),
            std::max(width, height), matchingKitty ? kittyPixels : localPixels));
        if (optical) samplingDamage.expand(opticalGlassSamplePadding(barRefractionStrength(),
            layer && layer->m_monitor ? layer->m_monitor->m_scale : 1.F,std::max(width,height)));
        samplingDamage.intersect(CBox{0, 0, width, height});
    }
    auto* retainedBlur = desktopWave && !attachedSettings && fusion ? &fusion->blurred : nullptr;
    const auto backdropTexture = optical && nativeBlur
        ? opticalBlurTexture(backdrop->getTexture(),frameMonitor,samplingDamage,
            layer && layer->m_monitor ? layer->m_monitor->m_scale : 1.F,retainedBlur)
        : barBackdropTexture(backdrop,samplingDamage,nativeBlur,retainedBlur);
    if (!backdropTexture)
        return false;

    const auto& matrix = g_pHyprRenderer->projectBoxToTarget(drawBox);
    auto shader = Render::GL::g_pHyprOpenGL->useShader(g_liquidShader);
    if (!shader)
        return false;

    const float panelScale = (topbar || rightMenu)
        ? sc<float>(surfaceBox.width / 1600.0)
        : sc<float>(std::min(surfaceBox.width / 1600.0, surfaceBox.height / 900.0));
    const float transitionAlpha = editor ? independentShape->opacity
        : (topbar || rightMenu || settings) ? 1.F
        : std::clamp((g_transition.current - 0.10F) / 0.90F, 0.F, 1.F);
    const float textureWidth = std::max(1.F, sc<float>(backdrop->getTexture()->m_size.x));
    const float textureHeight = std::max(1.F, sc<float>(backdrop->getTexture()->m_size.y));
    const float drawCenterX = sc<float>(drawBox.x + drawBox.width * 0.5);
    const float drawCenterY = sc<float>(drawBox.y + drawBox.height * 0.5);

    shader->setUniformMatrix3fv(SHADER_PROJ, 1, GL_TRUE, matrix.getMatrix());
    shader->setUniformInt(SHADER_TEX, 0);
    const bool useFusion = connectedSidebar && !desktopWave && fusion && fusion->sharp
        && (!nativeBlur || fusion->blurred) && !hasBottomSettings(monitorName);
    glUniform1f(glGetUniformLocation(shader->program(), "frameFusion"), useFusion ? 1.F : 0.F);
    glUniform1i(glGetUniformLocation(shader->program(), "frameBackdrop"), 2);
    glUniform1i(glGetUniformLocation(shader->program(), "frameBlur"), 3);
    float commonFrameRadius = 0.F;
    glUniform4f(glGetUniformLocation(shader->program(), "frameTopPanel"), 0, 0, 0, 0);
    glUniform4f(glGetUniformLocation(shader->program(), "frameTopMetrics"), 0, 0, 0, 0);
    glUniform2f(glGetUniformLocation(shader->program(), "frameFold"), 0.F, 0.F);
    glUniform1f(glGetUniformLocation(shader->program(), "barRefractionStrength"), barRefractionStrength());
    glUniform1f(glGetUniformLocation(shader->program(), "opticalScale"), layer && layer->m_monitor ? layer->m_monitor->m_scale : 1.F);
    glUniform1f(glGetUniformLocation(shader->program(), "barBrightness"), g_barBrightness);
    glUniform4f(glGetUniformLocation(shader->program(), "barMaterial"),
        sharedMaterial ? (desktopWave ? 2.F : 1.F) : 0.F,
        sharedMaterial ? material->second.mode : 0.F,
        nativeBlur ? 1.F : 0.F,
        sharedMaterial && material->second.spectrum && layer && layer->m_monitor
            ? sc<float>(layer->m_monitor->m_size.x / layer->m_monitor->m_scale) : 0.F);
    if (attachedSettings) {
        const auto& panel = g_bottomSettings.at(monitorName);
        const float x = surfaceBox.x + panel.x * surfaceBox.width;
        const float y = surfaceBox.y + panel.y * surfaceBox.height;
        const float radius = panel.radius * surfaceBox.width;
        const float bottom = surfaceBox.y + surfaceBox.height + radius;
        glUniform4f(glGetUniformLocation(shader->program(), "bottomPanel"),
            x + panel.width * surfaceBox.width * .5F, (y + bottom) * .5F,
            panel.width * surfaceBox.width * .5F, (bottom - y) * .5F);
        glUniform2f(glGetUniformLocation(shader->program(), "bottomMetrics"),
            radius, panel.joinSize * surfaceBox.width);
    } else {
        glUniform4f(glGetUniformLocation(shader->program(), "bottomPanel"), 0, 0, 0, 0);
        glUniform2f(glGetUniformLocation(shader->program(), "bottomMetrics"), 0, 0);
    }
    if (sharedMaterial) {
        glUniform4fv(glGetUniformLocation(shader->program(), "barTint"), 1, material->second.tint.data());
        glUniform1fv(glGetUniformLocation(shader->program(), "barBands"), 96, material->second.bands.data());
    }
    const float kittyScale = layer && layer->m_monitor ? sc<float>(layer->m_monitor->m_scale) : 1.F;
    // One lens field across connected bars/frame passes; changing the draw
    // rectangle must not introduce an optical seam at their junctions.
    const CBox kittyBox{0, 0, textureWidth, textureHeight};
    glUniform4f(glGetUniformLocation(shader->program(), "kittyLensBox"),
        sc<float>(kittyBox.x + kittyBox.width * .5), sc<float>(kittyBox.y + kittyBox.height * .5),
        sc<float>(kittyBox.width * .5), sc<float>(kittyBox.height * .5));
    glUniform4f(glGetUniformLocation(shader->program(), "kittyMatch"), matchingKitty ? 1.F : 0.F,
        *compositorBlur ? terminalGlassStrength() : 0.F, TERMINAL_REFRACTION_PIXELS * kittyScale, TERMINAL_RIM_WIDTH * kittyScale);
    glUniform1i(glGetUniformLocation(shader->program(), "kittyBlur"), 1);
    glUniform4f(glGetUniformLocation(shader->program(), "oppositePanel"), 0, 0, 0, 0);
    glUniform4f(glGetUniformLocation(shader->program(), "oppositeLabel"), 0, 0, 0, 0);
    glUniform1f(glGetUniformLocation(shader->program(), "oppositeContour"), 0);
    glUniform1f(glGetUniformLocation(shader->program(), "sideWaveScale"), 0);
    glUniform1f(glGetUniformLocation(shader->program(), "waveDockProgress"), 0);
    glUniform1f(glGetUniformLocation(shader->program(), "sideWaveWidth"), 0);
    if ((connectedTopbar || connectedSidebar) && frameShape.active) {
        const auto layer = element->m_data.currentLS.lock();
        const auto found = layer && layer->m_monitor
            ? g_connectedTopbars.find(layer->m_monitor->m_name) : g_connectedTopbars.end();
        const float top = found != g_connectedTopbars.end()
            ? found->second.barHeight * textureHeight : sc<float>(surfaceBox.y);
        const float remaining = 1.F - frameShape.desktopFold;
        const float rise = std::clamp((frameShape.desktopFold - .35F) / .65F, 0.F, 1.F);
        const float railRemaining = std::min(1.F, remaining / .22F);
        const float side = frameShape.width * textureWidth * 0.5F * railRemaining;
        commonFrameRadius = frameShape.radius * textureWidth * (1.F - rise);
        const float farEdge = commonFrameRadius * 2.F;
        const float opposite = frameShape.oppositeWidth > 0.F
            ? frameShape.oppositeWidth * textureWidth * railRemaining : -farEdge;
        const float left = frameShape.x > 0.5F ? opposite : side;
        const float interiorWidth = textureWidth - side - opposite;
        const float extent = (textureHeight - top) * (1.F - rise);
        const float bottom = std::min(extent * .5F, frameShape.bottomHeight * (textureHeight - top) * railRemaining);
        glUniform2f(glGetUniformLocation(shader->program(), "frameFold"),
            frameShape.desktopFold, top + extent);
        glUniform4f(glGetUniformLocation(shader->program(), "frameInterior"),
                    left, top, interiorWidth, std::max(0.01F, extent - bottom));
        if (found != g_connectedTopbars.end() && found->second.height > .000001F) {
            const auto& source = found->second;
            const CBox body = connectedTopbarMaterialBox(
                CBox{0, 0, textureWidth, textureHeight}, source, frameShape);
            glUniform4f(glGetUniformLocation(shader->program(), "frameTopPanel"),
                body.x + body.width * .5, body.y + body.height * .5,
                body.width * .5, body.height * .5);
            glUniform4f(glGetUniformLocation(shader->program(), "frameTopMetrics"),
                source.anchorX * textureWidth, source.neckHalfWidth * textureWidth,
                source.radius * textureWidth, source.joinSize * textureWidth);
        }
        if (frameShape.x <= .5F) {
            glUniform1f(glGetUniformLocation(shader->program(), "waveDockProgress"), frameShape.waveDockProgress);
            glUniform1f(glGetUniformLocation(shader->program(), "sideWaveWidth"), frameShape.sideWaveWidth * textureWidth);
            glUniform1fv(glGetUniformLocation(shader->program(), "sideCurve"), 21, frameShape.sideCurve.data());
        }
        if (frameShape.oppositePanel[1] > 0.F) {
            const float reach = frameShape.oppositePanel[1] * textureWidth;
            const float bodyHeight = frameShape.oppositePanel[2] * (textureHeight - top);
            const float edge = frameShape.x > 0.5F ? opposite : textureWidth - opposite;
            glUniform4f(glGetUniformLocation(shader->program(), "oppositePanel"),
                edge + (frameShape.x > 0.5F ? reach * .5F : -reach * .5F),
                top + frameShape.oppositePanel[0] * (textureHeight - top) + bodyHeight * .5F,
                reach * .5F, bodyHeight * .5F);
            glUniform1f(glGetUniformLocation(shader->program(), "oppositeContour"), frameShape.oppositeContour);
            glUniform1fv(glGetUniformLocation(shader->program(), "oppositeCurve"), 21, frameShape.oppositeCurve.data());
            glUniform1f(glGetUniformLocation(shader->program(), "sideWaveScale"),
                frameShape.x <= .5F ? frameShape.sideWaveScale : 0.F);
            const float labelWidth = frameShape.oppositeLabel[1] * textureWidth;
            const float labelHeight = frameShape.oppositeLabel[2] * (textureHeight - top);
            glUniform4f(glGetUniformLocation(shader->program(), "oppositeLabel"),
                edge - reach - labelWidth * .5F,
                top + frameShape.oppositeLabel[0] * (textureHeight - top) + labelHeight * .5F,
                labelWidth * .5F, labelHeight * .5F);
        }
    }
    glUniform4f(glGetUniformLocation(shader->program(), "sideLabel"),
        sc<float>(sideLabelBox.x + sideLabelBox.width * 0.5) - drawCenterX,
        sc<float>(sideLabelBox.y + sideLabelBox.height * 0.5) - drawCenterY,
        sc<float>(sideLabelBox.width * 0.5), sc<float>(sideLabelBox.height * 0.5));
    glUniform4f(glGetUniformLocation(shader->program(), "statusPanel"),
        sc<float>(statusBox.x + statusBox.width * 0.5) - drawCenterX,
        sc<float>(statusBox.y + statusBox.height * 0.5) - drawCenterY,
        sc<float>(statusBox.width * 0.5), sc<float>(statusBox.height * 0.5));
    glUniform4f(glGetUniformLocation(shader->program(), "chargingPanel"),
        sc<float>(chargingBox.x + chargingBox.width * 0.5) - drawCenterX,
        sc<float>(chargingBox.y + chargingBox.height * 0.5) - drawCenterY,
        sc<float>(chargingBox.width * 0.5), sc<float>(chargingBox.height * 0.5));
    glUniform4f(glGetUniformLocation(shader->program(), "timerPanel"),
        sc<float>(timerBox.x + timerBox.width * 0.5) - drawCenterX,
        sc<float>(timerBox.y + timerBox.height * 0.5) - drawCenterY,
        sc<float>(timerBox.width * 0.5), sc<float>(timerBox.height * 0.5));
    glUniform4f(glGetUniformLocation(shader->program(), "chargingLight"), 0, 0, 1, 0);
    glUniform4f(glGetUniformLocation(shader->program(), "timerLight"), 0, 0, 0, 0);
    std::array<float, LYRICS_BEAT_SLOTS * 4> musicLights{};
    std::array<float, LYRICS_BEAT_SLOTS * 6> musicColors{};
    if (connectedTopbar || connectedSidebar) {
        const auto found = g_lyricsBeats.find(frameMonitor);
        if (found != g_lyricsBeats.end()) {
            const auto now = std::chrono::steady_clock::now();
            for (size_t i = 0; i < found->second.size(); ++i) {
                const auto& beat = found->second[i];
                const float phase = std::clamp(std::chrono::duration<float>(now - beat.started).count()
                    / LYRICS_BEAT_SECONDS, 0.F, 1.F);
                musicLights[i * 4] = beat.x * textureWidth;
                musicLights[i * 4 + 1] = beat.y * textureHeight;
                musicLights[i * 4 + 2] = phase;
                musicLights[i * 4 + 3] = std::min(1.F, phase * 10.F)
                    * std::pow(1.F - phase, 1.4F) * .62F * beat.strength;
                std::copy(beat.colors.begin(), beat.colors.end(), musicColors.begin() + i * 6);
            }
        }
    }
    glUniform4fv(glGetUniformLocation(shader->program(), "musicLights"), LYRICS_BEAT_SLOTS, musicLights.data());
    glUniform3fv(glGetUniformLocation(shader->program(), "musicColors"), LYRICS_BEAT_SLOTS * 2, musicColors.data());
    // All owners of this monitor's bar/frame use one color field in framebuffer
    // coordinates. The sidebar starts below the topbar; its local surface box
    // must not shift the origin or reset the wave at that physical join.
    const auto chargingSource = g_connectedTopbars.find(frameMonitor);
    if ((connectedTopbar || connectedSidebar) && chargingSource != g_connectedTopbars.end()) {
        const auto& source = chargingSource->second;
        glUniform4f(glGetUniformLocation(shader->program(), "chargingLight"),
            source.chargingPanel[4] * textureWidth, source.barHeight * textureHeight,
            source.chargingProgress, source.chargingStrength);
        glUniform4f(glGetUniformLocation(shader->program(), "timerLight"),
            source.timerLight[0] * textureWidth, source.barHeight * textureHeight,
            source.timerLight[1], source.timerLight[2]);
    }
    if (connectedTopbar) {
        const auto& status = independentShape->statusPanel;
        glUniform4f(glGetUniformLocation(shader->program(), "statusMetrics"),
            sc<float>(surfaceBox.x + status[4] * surfaceBox.width) - drawCenterX,
            status[5] * sc<float>(surfaceBox.width), status[6] * sc<float>(surfaceBox.width),
            status[7] * sc<float>(surfaceBox.width));
        const auto& charging = independentShape->chargingPanel;
        glUniform4f(glGetUniformLocation(shader->program(), "chargingMetrics"),
            sc<float>(surfaceBox.x + charging[4] * surfaceBox.width) - drawCenterX,
            charging[5] * sc<float>(surfaceBox.width), charging[6] * sc<float>(surfaceBox.width),
            charging[7] * sc<float>(surfaceBox.width));
        const auto& timer = independentShape->timerPanel;
        glUniform4f(glGetUniformLocation(shader->program(), "timerMetrics"),
            sc<float>(surfaceBox.x + timer[4] * surfaceBox.width) - drawCenterX,
            timer[5] * sc<float>(surfaceBox.width), timer[6] * sc<float>(surfaceBox.width),
            timer[7] * sc<float>(surfaceBox.width));
    }
    glUniform1f(glGetUniformLocation(shader->program(), "frameRadius"), commonFrameRadius);
    glUniform2f(glGetUniformLocation(shader->program(), "frost"),
        topbar && !sharedMaterial && g_liquidFrosted ? 1.F : 0.F, g_liquidLight ? 1.F : 0.F);
    shader->setUniformFloat2(SHADER_FULL_SIZE, textureWidth, textureHeight);
    shader->setUniformFloat2(SHADER_WINDOW_TOP_LEFT,
                             sc<float>(drawBox.x / textureWidth),
                             sc<float>(drawBox.y / textureHeight));
    shader->setUniformFloat2(SHADER_WINDOW_BOTTOM_RIGHT,
                             sc<float>((drawBox.x + drawBox.width) / textureWidth),
                             sc<float>((drawBox.y + drawBox.height) / textureHeight));
    if (connectedTopbar) {
        shader->setUniformFloat2(SHADER_TOP_LEFT,
            sc<float>(railBox.x + railBox.width * 0.5) - drawCenterX,
            sc<float>(railBox.y + railBox.height * 0.5) - drawCenterY);
        shader->setUniformFloat2(SHADER_BOTTOM_RIGHT,
            sc<float>(railBox.width * 0.5), sc<float>(railBox.height * 0.5));
        shader->setUniformFloat2(SHADER_UV_OFFSET,
            sc<float>(panelBox.x + panelBox.width * 0.5) - drawCenterX,
            sc<float>(panelBox.y + panelBox.height * 0.5) - drawCenterY);
        shader->setUniformFloat2(SHADER_UV_SIZE,
            sc<float>(panelBox.width * 0.5), sc<float>(panelBox.height * 0.5));
    } else if (rightMenu) {
        const float joinX = sc<float>(railBox.x) - drawCenterX;
        const float menuCenterY = sc<float>(panelBox.y + panelBox.height * 0.5)
            - drawCenterY;
        shader->setUniformFloat2(SHADER_TOP_LEFT,
                                 sc<float>(railBox.x + railBox.width * 0.5) - drawCenterX,
                                 sc<float>(railBox.y + railBox.height * 0.5) - drawCenterY);
        shader->setUniformFloat2(SHADER_BOTTOM_RIGHT,
                                 sc<float>(railBox.width * 0.5),
                                 sc<float>(railBox.height * 0.5));
        shader->setUniformFloat2(SHADER_UV_OFFSET, joinX, menuCenterY);
        shader->setUniformFloat2(SHADER_UV_SIZE,
                                 g_rightMenuMorph.depth * sc<float>(surfaceBox.width),
                                 g_rightMenuMorph.halfHeight * sc<float>(surfaceBox.height));
    } else {
        shader->setUniformFloat2(SHADER_TOP_LEFT,
                                 sc<float>(panelBox.x + panelBox.width * 0.5) - drawCenterX,
                                 sc<float>(panelBox.y + panelBox.height * 0.5) - drawCenterY);
        shader->setUniformFloat2(SHADER_BOTTOM_RIGHT,
                                 sc<float>(panelBox.width * 0.5),
                                 sc<float>(panelBox.height * 0.5));
        shader->setUniformFloat2(SHADER_UV_OFFSET,
                                 sc<float>(dialBox.x + dialBox.width * 0.5) - drawCenterX,
                                 sc<float>(dialBox.y + dialBox.height * 0.5) - drawCenterY);
        shader->setUniformFloat2(SHADER_UV_SIZE,
                                 sc<float>(dialBox.width * 0.5),
                                 sc<float>(dialBox.height * 0.5));
    }
    shader->setUniformFloat(SHADER_RADIUS, rightMenu
        ? g_rightMenuMorph.straightHalfHeight * sc<float>(surfaceBox.height)
        : (settings ? g_settingsMorph.radius * sc<float>(surfaceBox.width)
                    : ((topbar || editor)
                        ? independentShape->radius * sc<float>(surfaceBox.width)
                              : 54.F * panelScale)));
    shader->setUniformFloat(SHADER_RADIUS_OUTER,
                            connectedSidebar ? std::min(12.F, sc<float>(dialBox.width * 0.5))
                            : connectedTopbar ? independentShape->joinSize * sc<float>(surfaceBox.width)
                            : hasDial ? sc<float>(std::min(dialBox.width * 0.5,
                                                        dialBox.height * 0.5)) : 0.F);
    shader->setUniformFloat(SHADER_THICK, connectedSidebar ? 4.F : connectedTopbar ? 3.F : rightMenu ? 2.F : (hasDial ? 1.F : 0.F));
    shader->setUniformFloat(SHADER_ALPHA,
                            rightMenu ? transitionAlpha * 0.94F : transitionAlpha);
    // Thin surfaces must finish their optical rim before the signed-distance
    // medial axis. Otherwise the normal flips while the lens is still active,
    // producing a straight seam through the middle of the 52 px idle bar.
    // The expanded Nook grows the limits naturally with its real thickness.
    const float reflectionFactor = appearanceReflection();
    float localRefraction = g_panelRefraction->value() * panelScale
        * reflectionFactor;
    float localEdgeWidth = g_panelEdgeWidth->value() * panelScale
        * std::sqrt(reflectionFactor);
    float localDispersion = g_panelDispersion->value() * panelScale
        * std::sqrt(reflectionFactor);
    if (topbar) {
        // A shallow lens remains readable even at maximum reflection.
        localRefraction = g_panelRefraction->value() * panelScale * 0.38F * std::sqrt(reflectionFactor);
        localEdgeWidth = g_panelEdgeWidth->value() * panelScale * 0.48F * std::sqrt(reflectionFactor);
        localDispersion *= 0.35F;
    }
    if (rightMenu) {
        localRefraction *= 0.42F;
        localEdgeWidth *= 0.31F;
        localDispersion *= 0.55F;
    } else if (topbar || (editor && panelBox.height < 110.F * panelScale)) {
        const float topbarHalfThickness = std::max(
            1.F, commonFrameRadius > 0.F ? frameShape.width * textureWidth * 0.5F
                : connectedTopbar ? std::max(sc<float>(railBox.height),
                sc<float>(std::min(panelBox.width, panelBox.height) * 0.5))
                : sc<float>(std::min(panelBox.width, panelBox.height) * 0.5));
        if (topbar) {
            const auto lens = barLensParameters(panelScale, topbarHalfThickness);
            localRefraction = lens.refraction;
            localEdgeWidth = lens.edgeWidth;
            localDispersion = lens.dispersion;
        } else {
            localRefraction = std::min(localRefraction, topbarHalfThickness * 0.62F);
            localEdgeWidth = std::min(localEdgeWidth, std::max(8.F, topbarHalfThickness * 0.88F));
            localDispersion = std::min(localDispersion, std::max(0.45F, topbarHalfThickness * 0.07F));
        }
    }
    shader->setUniformFloat(SHADER_DISTORT, localRefraction);
    shader->setUniformFloat(SHADER_CONTRAST, localEdgeWidth);
    shader->setUniformFloat(SHADER_BRIGHTNESS, 1.025F);
    shader->setUniformFloat(SHADER_VIBRANCY, 1.12F);
    shader->setUniformFloat(SHADER_NOISE, localDispersion);
    shader->setUniformFloat(SHADER_TIME, g_pHyprRenderer->m_globalTimer.getSeconds());
    const bool renderCaustics = !topbar && !rightMenu && !settings && !editor
        && g_caustics.enabled;
    shader->setUniformFloat4(SHADER_POINTER,
                             g_caustics.phase,
                             renderCaustics ? g_caustics.intensity : 0.F,
                             renderCaustics ? 1.F : 0.F,
                             panelScale);
    shader->setUniformFloat4(SHADER_POINTER_SHAPE,
                             connectedSidebar ? (independentShape->x > 0.5F ? -1.F : 1.F) : connectedTopbar
                                ? sc<float>(surfaceBox.x) + independentShape->anchorX * sc<float>(surfaceBox.width) - drawCenterX
                                : renderCaustics && g_caustics.lines ? 1.F : 0.F,
                             connectedTopbar ? independentShape->neckHalfWidth * sc<float>(surfaceBox.width) : 0.F,
                             connectedSidebar ? sc<float>(surfaceBox.y + surfaceBox.height
                                * (1.F - independentShape->bottomHeight)) - drawCenterY : 0.F,
                             topbar ? 1.F : 0.F);
    if (rightMenu)
        shader->setUniformFloat4(SHADER_COLOR, 0.23F, 0.07F, 0.52F,
                                 g_panelTint->value() * 2.25F);
    else if (topbar)
        shader->setUniformFloat4(SHADER_COLOR, 0.94F, 0.97F, 1.0F,
                                 g_panelTint->value() * 0.32F);
    else
        shader->setUniformFloat4(SHADER_COLOR, 0.87F, 0.93F, 1.0F,
                                 g_panelTint->value());

    glActiveTexture(GL_TEXTURE0);
    const auto sceneTexture = matchingKitty ? backdrop->getTexture() : backdropTexture;
    sceneTexture->bind();
    sceneTexture->setTexParameter(GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    sceneTexture->setTexParameter(GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    if (matchingKitty) {
        glActiveTexture(GL_TEXTURE1);
        backdropTexture->bind();
        backdropTexture->setTexParameter(GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        backdropTexture->setTexParameter(GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        ++g_terminalBarMatchDraws;
        glActiveTexture(GL_TEXTURE0);
    }
    const auto fusionScene = useFusion ? (matchingKitty || !nativeBlur
        ? fusion->sharp->getTexture() : fusion->blurred->getTexture()) : nullptr;
    const auto fusionBlur = useFusion && matchingKitty
        ? (nativeBlur ? fusion->blurred->getTexture() : fusion->sharp->getTexture()) : nullptr;
    if (fusionScene) { glActiveTexture(GL_TEXTURE2); fusionScene->bind(); }
    if (fusionBlur) { glActiveTexture(GL_TEXTURE3); fusionBlur->bind(); }
    glActiveTexture(GL_TEXTURE0);
    Render::GL::g_pHyprOpenGL->blend(true);
    glBindVertexArray(shader->getUniformLocation(SHADER_SHADER_VAO));

    liquidDamage.forEachRect([](const auto& rect) {
        Render::GL::g_pHyprOpenGL->scissor(&rect, g_pHyprRenderer->m_renderData.transformDamage);
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    });

    glBindVertexArray(0);
    if (matchingKitty) {
        glActiveTexture(GL_TEXTURE1);
        backdropTexture->unbind();
        glActiveTexture(GL_TEXTURE0);
    }
    if (fusionScene) { glActiveTexture(GL_TEXTURE2); fusionScene->unbind(); }
    if (fusionBlur) { glActiveTexture(GL_TEXTURE3); fusionBlur->unbind(); }
    glActiveTexture(GL_TEXTURE0);
    sceneTexture->unbind();
    Render::GL::g_pHyprOpenGL->scissor(nullptr);
    if (nativeBlur) {
        if (desktopWave) ++g_waveBlurDraws;
        else if (connectedSidebar) ++g_sidebarBlurDraws;
        else ++g_topbarBlurDraws;
    }
    if (rightMenu)
        ++g_rightMenuRefractionDraws;
    else if (settings)
        ++g_settingsRefractionDraws;
    else if (editor)
        ++g_editorRefractionDraws;
    else if (topbar && (!sharedMaterial || material->second.mode >= 2))
        ++g_topbarRefractionDraws;
    else if (!topbar)
        ++g_refractionDraws;
    return true;
}

bool renderSharedWidgetsBackdrop(WP<CTexPassElement> element,
                                 const CRegion& damage,
                                 const SP<Render::GL::CGLFramebuffer>& backdrop = g_clearBackdrop) {
    if (!element || !backdrop || !backdrop->getTexture() || !ensureLiquidShader() ||
        !g_pHyprRenderer || !Render::GL::g_pHyprOpenGL ||
        !g_sharedWidgetShapesActive)
        return false;

    const CBox surfaceBox = element->m_data.box;
    if (surfaceBox.width <= 0 || surfaceBox.height <= 0)
        return false;

    const auto layer = element->m_data.currentLS.lock();
    const std::string monitorName = layer && layer->m_monitor ? layer->m_monitor->m_name : "";
    const auto material = g_desktopBarMaterials.find(monitorName);
    const bool optical = material != g_desktopBarMaterials.end() && material->second.mode == 3;
    const float outputScale = layer && layer->m_monitor ? layer->m_monitor->m_scale : 1.F;
    SP<Render::ITexture> widgetSource = backdrop->getTexture();
    if (optical && g_widgetBlurEnabled && g_liquidFrosted) {
        CRegion sampling{damage.empty() ? CRegion{surfaceBox} : damage};
        sampling.expand(opticalGlassSamplePadding(barRefractionStrength(),outputScale,
            std::max(backdrop->m_size.x,backdrop->m_size.y)));
        widgetSource = opticalBlurTexture(widgetSource,monitorName,sampling,outputScale);
        if (!widgetSource) return false;
    }
    auto shader = Render::GL::g_pHyprOpenGL->useShader(g_liquidShader);
    if (!shader)
        return false;

    const float textureWidth = std::max(
        1.F, sc<float>(backdrop->getTexture()->m_size.x));
    const float textureHeight = std::max(
        1.F, sc<float>(backdrop->getTexture()->m_size.y));
    const float panelScale = sc<float>(std::min(
        surfaceBox.width / 1600.0, surfaceBox.height / 900.0));

    glUniform1f(glGetUniformLocation(shader->program(), "frameRadius"), 0.F);
    glUniform2f(glGetUniformLocation(shader->program(), "frameFold"), 0.F, 0.F);
    glUniform4f(glGetUniformLocation(shader->program(), "barMaterial"), optical ? 1.F : 0.F, optical ? 3.F : 0.F, 0.F, 0.F);
    if (optical) {
        glUniform4fv(glGetUniformLocation(shader->program(), "barTint"),1,material->second.tint.data());
        glUniform1f(glGetUniformLocation(shader->program(), "opticalScale"),outputScale);
        glUniform1f(glGetUniformLocation(shader->program(), "barBrightness"),g_barBrightness);
        glUniform1f(glGetUniformLocation(shader->program(), "barRefractionStrength"),barRefractionStrength());
        for (const auto name : {"frameInterior","frameTopPanel","oppositePanel","oppositeLabel",
                "chargingLight","timerLight","musicLights[0]","musicLights[1]"})
            glUniform4f(glGetUniformLocation(shader->program(),name),0,0,0,0);
    }
    glUniform1f(glGetUniformLocation(shader->program(), "frameFusion"), 0.F);
    glUniform2f(glGetUniformLocation(shader->program(), "frost"), g_liquidFrosted ? 1.F : 0.F, g_liquidLight ? 1.F : 0.F);
    shader->setUniformInt(SHADER_TEX, 0);
    shader->setUniformFloat2(SHADER_FULL_SIZE, textureWidth, textureHeight);
    shader->setUniformFloat(SHADER_RADIUS_OUTER, 0.F);
    shader->setUniformFloat(SHADER_THICK, 0.F);
    shader->setUniformFloat(SHADER_BRIGHTNESS, 1.025F);
    shader->setUniformFloat(SHADER_VIBRANCY, 1.12F);
    shader->setUniformFloat(SHADER_TIME,
                            g_pHyprRenderer->m_globalTimer.getSeconds());
    shader->setUniformFloat4(SHADER_COLOR, 0.94F, 0.97F, 1.0F,
                             g_panelTint->value() * 0.32F);

    const bool renderCaustics = g_sharedWidgetCaustics && g_caustics.enabled;
    shader->setUniformFloat4(SHADER_POINTER,
                             g_caustics.phase,
                             renderCaustics ? g_caustics.intensity : 0.F,
                             renderCaustics ? 1.F : 0.F,
                             panelScale);

    glActiveTexture(GL_TEXTURE0);
    widgetSource->bind();
    widgetSource->setTexParameter(GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    widgetSource->setTexParameter(GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    Render::GL::g_pHyprOpenGL->blend(true);
    glBindVertexArray(shader->getUniformLocation(SHADER_SHADER_VAO));

    bool drewShape = false;
    constexpr float PI = 3.14159265358979323846F;
    for (const auto& shape : g_sharedWidgetShapes) {
        if (!shape.active || shape.width <= 0.0001F ||
            shape.height <= 0.0001F || shape.opacity <= 0.001F)
            continue;

        const double shapeWidth = shape.width * surfaceBox.width;
        const double shapeHeight = shape.height * surfaceBox.height;
        const double centerX = surfaceBox.x
            + (shape.x + shape.width * 0.5F) * surfaceBox.width;
        const double centerY = surfaceBox.y
            + (shape.y + shape.height * 0.5F) * surfaceBox.height;
        const float radians = shape.rotation * PI / 180.F;
        const double cosine = std::abs(std::cos(radians));
        const double sine = std::abs(std::sin(radians));
        const double aabbWidth = shapeWidth * cosine + shapeHeight * sine;
        const double aabbHeight = shapeWidth * sine + shapeHeight * cosine;
        const CBox drawBox{centerX - aabbWidth * 0.5,
                           centerY - aabbHeight * 0.5,
                           aabbWidth, aabbHeight};

        CRegion liquidDamage{drawBox};
        if (!damage.empty())
            liquidDamage.intersect(damage);
        if (liquidDamage.empty())
            continue;

        const auto& matrix = g_pHyprRenderer->projectBoxToTarget(drawBox);
        shader->setUniformMatrix3fv(SHADER_PROJ, 1, GL_TRUE,
                                    matrix.getMatrix());
        shader->setUniformFloat2(
            SHADER_WINDOW_TOP_LEFT,
            sc<float>(drawBox.x / textureWidth),
            sc<float>(drawBox.y / textureHeight));
        shader->setUniformFloat2(
            SHADER_WINDOW_BOTTOM_RIGHT,
            sc<float>((drawBox.x + drawBox.width) / textureWidth),
            sc<float>((drawBox.y + drawBox.height) / textureHeight));
        shader->setUniformFloat2(SHADER_TOP_LEFT, 0.F, 0.F);
        shader->setUniformFloat2(SHADER_BOTTOM_RIGHT,
                                 sc<float>(shapeWidth * 0.5),
                                 sc<float>(shapeHeight * 0.5));
        shader->setUniformFloat2(SHADER_UV_OFFSET, 0.F, 0.F);
        shader->setUniformFloat2(SHADER_UV_SIZE, 0.F, 0.F);
        shader->setUniformFloat(
            SHADER_RADIUS, shape.radius * sc<float>(surfaceBox.width));
        shader->setUniformFloat(SHADER_ALPHA,
                                std::clamp(shape.opacity, 0.F, 1.F));

        const float halfThickness = sc<float>(
            std::min(shapeWidth, shapeHeight) * 0.5);
        // Shared cards are small independent lenses. The large panel optics
        // (about 38 px of displacement and a 74 px rim at 1920x1200) stretch
        // wallpaper details into diagonal prisms across these cards. Preserve
        // real native refraction, but shorten its focal depth and rim so the
        // module silhouette stays visually straight.
        const float reflectionFactor = appearanceReflection();
        const float localRefraction = std::min(
            g_panelRefraction->value() * panelScale * 0.38F
                * std::sqrt(reflectionFactor),
            std::max(2.5F, halfThickness * 0.62F));
        const float localEdgeWidth = std::min(
            g_panelEdgeWidth->value() * panelScale * 0.48F
                * std::sqrt(reflectionFactor),
            std::max(8.F, halfThickness * 0.88F));
        const float localDispersion = std::min(
            g_panelDispersion->value() * panelScale * 0.35F
                * std::sqrt(reflectionFactor),
            std::max(0.45F, halfThickness * 0.07F));
        shader->setUniformFloat(SHADER_DISTORT, localRefraction);
        shader->setUniformFloat(SHADER_CONTRAST, localEdgeWidth);
        shader->setUniformFloat(SHADER_NOISE, localDispersion);
        shader->setUniformFloat4(SHADER_POINTER_SHAPE,
                                 renderCaustics && g_caustics.lines ? 1.F : 0.F,
                                 radians, 1.F, 1.F);

        liquidDamage.forEachRect([](const auto& rect) {
            Render::GL::g_pHyprOpenGL->scissor(
                &rect, g_pHyprRenderer->m_renderData.transformDamage);
            glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        });
        drewShape = true;
    }

    glBindVertexArray(0);
    widgetSource->unbind();
    Render::GL::g_pHyprOpenGL->scissor(nullptr);
    if (drewShape)
        ++g_sharedWidgetRefractionDraws;
    return true;
}

void damageAllMonitors() {
    if (!State::monitorState() || !g_pHyprRenderer)
        return;

    for (const auto& monitor : State::monitorState()->monitors()) {
        if (monitor)
            g_pHyprRenderer->damageMonitor(monitor);
    }
}

CBox unionBoxes(const CBox& first, const CBox& second, const double margin = 0.0) {
    const double left = std::min(first.x, second.x) - margin;
    const double top = std::min(first.y, second.y) - margin;
    const double right = std::max(first.x + first.width,
                                  second.x + second.width) + margin;
    const double bottom = std::max(first.y + first.height,
                                   second.y + second.height) + margin;
    return {left, top, right - left, bottom - top};
}

CBox monitorSharedWidgetBox(const PHLMONITOR& monitor,
                            const SSharedWidgetShape& shape) {
    constexpr double PI = 3.14159265358979323846;
    const double shapeWidth = shape.width * monitor->m_size.x;
    const double shapeHeight = shape.height * monitor->m_size.y;
    const double centerX = monitor->m_position.x
        + (shape.x + shape.width * 0.5) * monitor->m_size.x;
    const double centerY = monitor->m_position.y
        + (shape.y + shape.height * 0.5) * monitor->m_size.y;
    const double radians = shape.rotation * PI / 180.0;
    const double cosine = std::abs(std::cos(radians));
    const double sine = std::abs(std::sin(radians));
    const double aabbWidth = shapeWidth * cosine + shapeHeight * sine;
    const double aabbHeight = shapeWidth * sine + shapeHeight * cosine;
    return {centerX - aabbWidth * 0.5, centerY - aabbHeight * 0.5,
            aabbWidth, aabbHeight};
}

bool visibleSharedWidgetShape(const SSharedWidgetShape& shape) {
    return shape.active && shape.width > 0.0001F
        && shape.height > 0.0001F && shape.opacity > 0.001F;
}

void damageSharedWidgetShapes(
        const std::array<SSharedWidgetShape, SHARED_WIDGET_COUNT>& previous,
        const std::array<SSharedWidgetShape, SHARED_WIDGET_COUNT>& current) {
    if (!State::monitorState() || !g_pHyprRenderer)
        return;

    // The refracted pixels are drawn by the plugin rather than the Qt item.
    // Damage both silhouettes whenever QML moves a card; otherwise the old
    // native pixels survive outside the new blurRegion and build diagonal
    // wedges/trails during Desktop <-> Lock and profile morphs.
    for (const auto& monitor : State::monitorState()->monitors()) {
        if (!monitor)
            continue;
        for (size_t index = 0; index < SHARED_WIDGET_COUNT; ++index) {
            if (visibleSharedWidgetShape(previous[index])) {
                const auto box = monitorSharedWidgetBox(
                    monitor, previous[index]);
                g_pHyprRenderer->damageBox(unionBoxes(box, box, 4.0));
            }
            if (visibleSharedWidgetShape(current[index])) {
                const auto box = monitorSharedWidgetBox(
                    monitor, current[index]);
                g_pHyprRenderer->damageBox(unionBoxes(box, box, 4.0));
            }
        }
    }
}

CBox monitorTopbarBox(const PHLMONITOR& monitor, const STopbarMorph& morph) {
    return {
        monitor->m_position.x + morph.x * monitor->m_size.x,
        monitor->m_position.y + morph.y * monitor->m_size.y,
        morph.width * monitor->m_size.x,
        morph.height * monitor->m_size.y,
    };
}

void damageTopbarMorph(const STopbarMorph& previous,
                       const STopbarMorph& current, const std::string& monitorName = "") {
    if (!State::monitorState() || !g_pHyprRenderer)
        return;
    for (const auto& monitor : State::monitorState()->monitors()) {
        if (!monitor || (!monitorName.empty() && monitor->m_name != monitorName))
            continue;
        if (previous.bottomHeight > 0.F || current.bottomHeight > 0.F) {
            for (const auto& shape : {previous, current}) {
                if (!shape.active) continue;
                g_pHyprRenderer->damageBox(monitorTopbarBox(monitor, shape));
                if (shape.sideWaveScale > 0.F && shape.x <= .5F) {
                    const float peak = *std::max_element(shape.sideCurve.begin(), shape.sideCurve.end());
                    const double waveWidth = (shape.width * .5F + shape.sideWaveWidth
                        * peak + shape.radius) * monitor->m_size.x + 4;
                    g_pHyprRenderer->damageBox(CBox{monitor->m_position.x, monitor->m_position.y,
                        waveWidth, monitor->m_size.y});
                }
                const double edge = (shape.x > 0.5F ? shape.x : shape.x + shape.width) * monitor->m_size.x;
                const double reach = shape.sideBodyWidth * monitor->m_size.x;
                if (reach > 0)
                    g_pHyprRenderer->damageBox(CBox{monitor->m_position.x + edge - (shape.x > 0.5F ? reach : 0) - 16,
                        monitor->m_position.y + shape.sideBodyY * monitor->m_size.y - 16,
                        reach + 32, shape.sideBodyHeight * monitor->m_size.y + 80});
                if (shape.oppositeWidth > 0.F) {
                    const double edgeWidth = (shape.oppositeWidth + shape.oppositePanel[1] + shape.oppositeLabel[1] + shape.radius) * monitor->m_size.x + 2;
                    g_pHyprRenderer->damageBox(CBox{monitor->m_position.x
                        + (shape.x > 0.5F ? 0 : monitor->m_size.x - edgeWidth),
                        monitor->m_position.y, edgeWidth, monitor->m_size.y});
                }
                const double bottom = shape.bottomHeight * monitor->m_size.y;
                g_pHyprRenderer->damageBox(CBox{monitor->m_position.x,
                    monitor->m_position.y + monitor->m_size.y - bottom - 28,
                    monitor->m_size.x, bottom + 28});
            }
            continue;
        }
        if (previous.active && current.active)
            g_pHyprRenderer->damageBox(unionBoxes(
                monitorTopbarBox(monitor, previous),
                monitorTopbarBox(monitor, current), 8.0));
        else if (previous.active)
            g_pHyprRenderer->damageBox(monitorTopbarBox(monitor, previous));
        else if (current.active)
            g_pHyprRenderer->damageBox(monitorTopbarBox(monitor, current));
    }
}

CBox monitorRightMenuBox(const PHLMONITOR& monitor,
                         const SRightMenuMorph& morph) {
    const double depth = morph.depth * monitor->m_size.x;
    const double halfHeight = morph.halfHeight * monitor->m_size.y;
    const double centerY = monitor->m_position.y
        + morph.centerY * monitor->m_size.y;
    const double joinX = monitor->m_position.x + monitor->m_size.x
        - morph.railWidth * monitor->m_size.x;
    return {joinX - depth, centerY - halfHeight,
            depth + morph.railWidth * monitor->m_size.x,
            halfHeight * 2.0};
}

void damageRightMenuMorph(const SRightMenuMorph& previous,
                          const SRightMenuMorph& current) {
    if (!State::monitorState() || !g_pHyprRenderer)
        return;
    for (const auto& monitor : State::monitorState()->monitors()) {
        if (!monitor)
            continue;
        if (previous.active && current.active)
            g_pHyprRenderer->damageBox(unionBoxes(
                monitorRightMenuBox(monitor, previous),
                monitorRightMenuBox(monitor, current), 8.0));
        else if (previous.active)
            g_pHyprRenderer->damageBox(monitorRightMenuBox(monitor, previous));
        else if (current.active)
            g_pHyprRenderer->damageBox(monitorRightMenuBox(monitor, current));
    }
}

CBox monitorLockGlassBox(const PHLMONITOR& monitor) {
    const CBox surfaceBox{monitor->m_position.x, monitor->m_position.y,
                          monitor->m_size.x, monitor->m_size.y};
    const CBox panelBox = liquidPanelBox(surfaceBox);
    if (!g_dialMorph.active || g_dialMorph.depth <= 0.5F
            || g_dialMorph.halfHeight <= 0.5F)
        return panelBox;

    const double designScale = std::min(surfaceBox.width / 1600.0,
                                        surfaceBox.height / 900.0);
    const double designOriginY = (surfaceBox.height
        - 900.0 * designScale) * 0.5;
    const double dialDepth = g_dialMorph.depth * designScale;
    const double dialHalfHeight = g_dialMorph.halfHeight * designScale;
    const double dialCenterY = surfaceBox.y + designOriginY
        + g_dialMorph.centerY * designScale;
    const CBox dialBox{panelBox.x - dialDepth,
                       dialCenterY - dialHalfHeight,
                       dialDepth * 2.0, dialHalfHeight * 2.0};
    return unionBoxes(panelBox, dialBox, 3.0);
}

void damageCausticsRegion() {
    if (!State::monitorState() || !g_pHyprRenderer)
        return;
    for (const auto& monitor : State::monitorState()->monitors()) {
        if (monitor)
            g_pHyprRenderer->damageBox(monitorLockGlassBox(monitor));
    }
}

SDispatchResult dialDispatcher(std::string arguments) {
    std::istringstream input{arguments};
    int active = 0;
    float depth = 0.F;
    float halfHeight = 0.F;
    float centerY = 408.F;
    if (!(input >> active >> depth >> halfHeight >> centerY))
        return {.success = false, .error = "expected active depth halfHeight centerY"};

    g_dialMorph.active = active != 0;
    g_dialMorph.depth = std::clamp(depth, 0.F, 220.F);
    g_dialMorph.halfHeight = std::clamp(halfHeight, 0.F, 220.F);
    g_dialMorph.centerY = std::clamp(centerY, 0.F, 900.F);
    // The QML morph committing this geometry already schedules the affected
    // layer damage. Invalidating every monitor here doubled the work and made
    // otherwise 60 Hz motion feel uneven.
    return {};
}

SDispatchResult lyricsBeatDispatcher(std::string arguments) {
    const auto command = parseLyricsBeat(arguments);
    if (!command) return {.success = false, .error = "expected monitor x y strength in 0..1 or monitor reset"};
    const auto& monitor = command->monitor;
    if (command->reset) g_lyricsBeats.erase(monitor);
    else {
        // Only a known bar output may own a pulse queue.
        if (!g_connectedTopbars.contains(monitor) || !g_connectedTopbars.at(monitor).active)
            return {};
        const auto now = std::chrono::steady_clock::now();
        auto& beats = g_lyricsBeats[monitor];
        std::erase_if(beats, [&](const auto& beat) {
            return std::chrono::duration<float>(now - beat.started).count() >= LYRICS_BEAT_SECONDS;
        });
        if (!beats.empty() && std::chrono::duration<float>(now - beats.back().started).count() < .2F)
            return {};
        if (beats.size() == LYRICS_BEAT_SLOTS) beats.erase(beats.begin());
        beats.push_back({command->x, command->y, command->strength, command->colors, now});
        ++g_lyricsBeatCount;
    }
    damageTopbarMorph({}, unifiedBarShape(monitor), monitor);
    return {};
}

SDispatchResult connectedTopbarDispatcher(std::string arguments) {
    std::istringstream input{arguments};
    std::string monitor;
    int material = 0;
    if (!(input >> monitor >> material))
        return {.success = false, .error = "expected monitor material and connected surface geometry"};
    if (material < 0) { g_connectedTopbars.erase(monitor); return {}; }
    STopbarMorph shape;
    shape.connected = true;
    shape.active = material == 1;
    if (!(input >> shape.barHeight >> shape.x >> shape.y >> shape.width >> shape.height
                >> shape.anchorX >> shape.neckHalfWidth >> shape.radius >> shape.joinSize))
        return {.success = false, .error = "expected barHeight x y width height anchor neck radius join"};
    for (const float value : {shape.barHeight, shape.x, shape.y, shape.width, shape.height,
             shape.anchorX, shape.neckHalfWidth, shape.radius, shape.joinSize}) {
        if (!std::isfinite(value) || value < 0.F || value > 1.1F)
            return {.success = false, .error = "invalid normalized topbar geometry"};
    }
    shape.height = std::max(0.000001F, shape.height);
    input >> std::ws;
    if (!input.eof()) {
        for (auto& value : shape.statusPanel) {
            if (!(input >> value) || !std::isfinite(value) || value < 0.F || value > 1.1F)
                return {.success = false, .error = "invalid normalized status panel geometry"};
        }
    }
    input >> std::ws;
    if (!input.eof()) {
        for (auto& value : shape.chargingPanel) {
            if (!(input >> value) || !std::isfinite(value) || value < 0.F || value > 1.1F)
                return {.success = false, .error = "invalid normalized charging panel geometry"};
        }
    }
    input >> std::ws;
    if (!input.eof()) {
        if (!(input >> shape.chargingProgress >> shape.chargingStrength)
                || !std::isfinite(shape.chargingProgress) || !std::isfinite(shape.chargingStrength)
                || shape.chargingProgress < 0.F || shape.chargingProgress > 1.F
                || shape.chargingStrength < 0.F || shape.chargingStrength > 1.F)
            return {.success = false, .error = "invalid charging light progress/intensity"};
    }
    input >> std::ws;
    if (!input.eof()) {
        for (auto& value : shape.timerPanel) {
            if (!(input >> value) || !std::isfinite(value) || value < 0.F || value > 1.1F)
                return {.success = false, .error = "invalid normalized timer panel geometry"};
        }
        for (auto& value : shape.timerLight) {
            if (!(input >> value) || !std::isfinite(value) || value < 0.F || value > 1.F)
                return {.success = false, .error = "invalid timer light anchor/progress/intensity"};
        }
    }
    g_connectedTopbars[monitor] = shape;
    // QML damages only the changing surface; never start an idle render timer.
    return {};
}

SDispatchResult topbarShapeDispatcher(std::string arguments) {
    std::istringstream input{arguments};
    int count = 0;
    if (!(input >> count) || count < 0
            || count > static_cast<int>(TOPBAR_SHAPE_COUNT))
        return {.success = false, .error = "expected shape count from 0 to 3"};

    std::array<STopbarMorph, TOPBAR_SHAPE_COUNT> next{};
    for (int index = 0; index < count; ++index) {
        float x = 0.F;
        float y = 0.F;
        float width = 0.F;
        float height = 0.F;
        float radius = 0.F;
        if (!(input >> x >> y >> width >> height >> radius))
            return {.success = false,
                    .error = "expected x y width height radius for every shape"};
        auto& shape = next[index];
        shape.active = true;
        // Edge islands extend just outside the monitor so compositor clipping
        // produces a straight screen edge without sacrificing the rounded
        // inner corner.
        shape.x = std::clamp(x, -0.1F, 1.1F);
        shape.y = std::clamp(y, -1.1F, 1.1F);
        shape.width = std::clamp(width, 0.001F, 1.2F);
        shape.height = std::clamp(height, 0.001F, 2.2F);
        shape.radius = std::clamp(radius, 0.F, 0.5F);
    }

    const auto previous = g_topbarShapes;
    g_topbarShapes = next;
    for (size_t index = 0; index < TOPBAR_SHAPE_COUNT; ++index)
        damageTopbarMorph(previous[index], g_topbarShapes[index]);
    return {};
}

SDispatchResult desktopBarMaterialDispatcher(std::string arguments) {
    std::istringstream input{arguments};
    std::string name;
    int mode;
    if (!(input >> name >> mode) || mode < -1 || mode > 3)
        return {.success = false, .error = "expected monitor mode tint blur spectrum and 96 bands"};
    if (mode == -1) { g_desktopBarMaterials.erase(name); damageAllMonitors(); return {}; }
    SDesktopBarMaterial next;
    next.mode = mode;
    for (auto& value : next.tint) {
        if (!(input >> value) || !std::isfinite(value) || value < 0.F || value > 1.F)
            return {.success = false, .error = "invalid bar tint"};
    }
    int blur, spectrum;
    if (!(input >> blur >> spectrum) || (blur != 0 && blur != 1) || (spectrum != 0 && spectrum != 1))
        return {.success = false, .error = "invalid bar flags"};
    next.blur = blur && mode != 0;
    next.spectrum = spectrum;
    for (auto& value : next.bands) {
        if (!(input >> value) || !std::isfinite(value) || value < 0.F || value > 1.F)
            return {.success = false, .error = "invalid spectrum frame"};
    }
    const auto old = g_desktopBarMaterials.find(name);
    const bool styleChanged = old == g_desktopBarMaterials.end() || old->second.mode != next.mode
        || old->second.tint != next.tint || old->second.blur != next.blur;
    g_desktopBarMaterials[name] = next;
    if (State::monitorState() && g_pHyprRenderer) {
        for (const auto& monitor : State::monitorState()->monitors()) {
            if (!monitor || monitor->m_name != name) continue;
            if (styleChanged) g_pHyprRenderer->damageMonitor(monitor);
            else g_pHyprRenderer->damageBox(CBox{monitor->m_position.x,
                monitor->m_position.y + monitor->m_size.y - 205 * monitor->m_scale,
                monitor->m_size.x, 205 * monitor->m_scale});
        }
    }
    return {};
}

SDispatchResult unifiedBarShapeDispatcher(std::string arguments) {
    std::istringstream input{arguments};
    std::string monitor;
    int active = 0;
    if (!(input >> monitor >> active))
        return {.success = false, .error = "expected monitor active [x y width height radius]"};

    const STopbarMorph previous = unifiedBarShape(monitor);
    auto& shape = g_unifiedBarShapes[monitor];
    if (active == 0) {
        shape = {};
        damageTopbarMorph(previous, shape, monitor);
        g_unifiedBarShapes.erase(monitor);
        return {};
    }

    float x = 0.F;
    float y = 0.F;
    float width = 0.F;
    float height = 0.F;
    float radius = 0.F;
    if (!(input >> x >> y >> width >> height >> radius))
        return {.success = false, .error = "expected active x y width height radius"};

    shape.active = true;
    shape.x = std::clamp(x, -0.1F, 1.1F);
    shape.y = std::clamp(y, -0.1F, 1.F);
    shape.width = std::clamp(width, 0.001F, 1.2F);
    shape.height = std::clamp(height, 0.001F, 1.2F);
    shape.radius = std::clamp(radius, 0.F, 0.5F);
    float bodyY = 0.F, bodyWidth = 0.F, bodyHeight = 0.F, bottomHeight = 0.F;
    input >> bodyY >> bodyWidth >> bodyHeight;
    input >> bottomHeight;
    float labelY = 0.F, labelWidth = 0.F, labelHeight = 0.F;
    input >> labelY >> labelWidth >> labelHeight;
    float oppositeWidth = 0.F;
    input >> oppositeWidth;
    shape.oppositeWidth = std::clamp(oppositeWidth, 0.F, 0.05F);
    std::array<float, 3> oppositePanel{};
    input >> oppositePanel[0] >> oppositePanel[1] >> oppositePanel[2];
    shape.oppositePanel = {std::clamp(oppositePanel[0], 0.F, 1.F),
        std::clamp(oppositePanel[1], 0.F, 0.5F), std::clamp(oppositePanel[2], 0.F, 1.F)};
    float oppositeContour = 0.F;
    std::array<float, 3> oppositeLabel{};
    input >> oppositeContour >> oppositeLabel[0] >> oppositeLabel[1] >> oppositeLabel[2];
    shape.oppositeContour = std::clamp(oppositeContour, 0.F, 2.F);
    for (auto& value : shape.oppositeCurve) { float sample = 0.F; input >> sample; value = std::clamp(sample, 0.F, .5F); }
    float sideWaveScale = 0.F;
    input >> sideWaveScale;
    shape.sideWaveScale = std::isfinite(sideWaveScale) ? std::clamp(sideWaveScale, 0.F, 1.F) : 0.F;
    float dock = 0.F, sideWaveWidth = 0.F;
    input >> dock >> sideWaveWidth;
    shape.waveDockProgress = std::isfinite(dock) ? std::clamp(dock, 0.F, 1.F) : 0.F;
    shape.sideWaveWidth = std::isfinite(sideWaveWidth) ? std::clamp(sideWaveWidth, 0.F, .25F) : 0.F;
    for (auto& value : shape.sideCurve) { float sample = 0.F; input >> sample; value = std::isfinite(sample) ? std::clamp(sample, 0.F, .5F) : 0.F; }
    float fold = 0.F;
    if (input >> fold) {
        if (!std::isfinite(fold) || fold < 0.F || fold > 1.F)
            return {.success = false, .error = "invalid desktop fold progress"};
    }
    shape.desktopFold = fold;
    shape.oppositeLabel = {std::clamp(oppositeLabel[0], 0.F, 1.F),
        std::clamp(oppositeLabel[1], 0.F, 0.25F), std::clamp(oppositeLabel[2], 0.F, 1.F)};
    shape.sideLabelY = std::clamp(labelY, 0.F, 1.F);
    shape.sideLabelWidth = std::clamp(labelWidth, 0.F, 0.5F);
    shape.sideLabelHeight = std::clamp(labelHeight, 0.F, 1.F);
    shape.sideBodyY = std::clamp(bodyY, 0.F, 1.F);
    shape.sideBodyWidth = std::clamp(bodyWidth, 0.F, 0.5F);
    shape.sideBodyHeight = std::clamp(bodyHeight, 0.F, 1.F);
    shape.bottomHeight = std::clamp(bottomHeight, 0.F, 0.1F);
    damageTopbarMorph(previous, shape, monitor);
    if (previous.desktopFold != shape.desktopFold)
        damageAllMonitors();
    return {};
}

SDispatchResult settingsShapeDispatcher(std::string arguments) {
    std::istringstream input{arguments};
    int active = 0;
    float x = 0.F;
    float y = 0.F;
    float width = 1.F;
    float height = 1.F;
    float radius = 0.F;
    if (!(input >> active >> x >> y >> width >> height >> radius))
        return {.success = false,
                .error = "expected active x y width height radius"};

    const STopbarMorph previous = g_settingsMorph;
    g_settingsMorph.active = active != 0;
    g_settingsMorph.x = std::clamp(x, 0.F, 1.F);
    g_settingsMorph.y = std::clamp(y, 0.F, 1.F);
    g_settingsMorph.width = std::clamp(width, 0.001F, 1.F);
    g_settingsMorph.height = std::clamp(height, 0.001F, 1.F);
    g_settingsMorph.radius = std::clamp(radius, 0.F, 0.5F);
    damageTopbarMorph(previous, g_settingsMorph);
    return {};
}

SDispatchResult selectorShapeDispatcher(std::string arguments) {
    std::istringstream input{arguments};
    std::string monitor;
    int active = 0;
    STopbarMorph next;
    if (!(input >> monitor >> active >> next.x >> next.y >> next.width
                >> next.height >> next.radius >> next.opacity))
        return {.success = false, .error = "expected monitor active x y width height radius opacity"};
    for (const float value : {next.x, next.y, next.width, next.height, next.radius, next.opacity})
        if (!std::isfinite(value))
            return {.success = false, .error = "selector geometry must be finite"};
    next.active = active != 0;
    next.x = std::clamp(next.x, 0.F, 1.F);
    next.y = std::clamp(next.y, 0.F, 1.F);
    next.width = std::clamp(next.width, 0.F, 1.F);
    next.height = std::clamp(next.height, 0.F, 1.F);
    next.radius = std::clamp(next.radius, 0.F, 0.5F);
    next.opacity = std::clamp(next.opacity, 0.F, 1.F);
    const auto previous = g_selectorShapes[monitor];
    if (next.active) g_selectorShapes[monitor] = next;
    else g_selectorShapes.erase(monitor);
    damageTopbarMorph(previous, next);
    return {};
}

SDispatchResult settingsConnectedDispatcher(std::string arguments) {
    std::istringstream input{arguments};
    std::string monitor;
    int active = 0;
    STopbarMorph next;
    if (!(input >> monitor >> active) || (active != 0 && active != 1))
        return {.success = false, .error = "expected monitor and active 0 or 1"};
    if (active) {
        if (!(input >> next.x >> next.y >> next.width >> next.height >> next.radius >> next.joinSize))
            return {.success = false, .error = "expected normalized x y width height radius join"};
        for (const float value : {next.x, next.y, next.width, next.height, next.radius, next.joinSize})
            if (!std::isfinite(value) || value < 0.F || value > 1.F)
                return {.success = false, .error = "settings geometry must be finite and within 0..1"};
        if (next.width <= 0.F || next.height <= 0.F)
            return {.success = false, .error = "settings dimensions must be positive"};
        next.active = true;
        g_bottomSettings[monitor] = next;
    } else g_bottomSettings.erase(monitor);
    // Ownership changes include the complete bottom strip, not just the panel.
    // Called only during geometry/lifecycle changes, never at rest.
    damageAllMonitors();
    return {};
}

SDispatchResult editorShapeDispatcher(std::string arguments) {
    std::istringstream input{arguments};
    int count = 0;
    if (!(input >> count) || count < 0
            || count > static_cast<int>(EDITOR_SHAPE_COUNT))
        return {.success = false, .error = "expected shape count from 0 to 6"};

    std::array<STopbarMorph, EDITOR_SHAPE_COUNT> next{};
    for (int index = 0; index < count; ++index) {
        float x = 0.F;
        float y = 0.F;
        float width = 0.F;
        float height = 0.F;
        float radius = 0.F;
        if (!(input >> x >> y >> width >> height >> radius))
            return {.success = false,
                    .error = "expected x y width height radius for every editor shape"};
        auto& shape = next[index];
        shape.active = true;
        shape.x = std::clamp(x, 0.F, 1.F);
        shape.y = std::clamp(y, 0.F, 1.F);
        shape.width = std::clamp(width, 0.001F, 1.F);
        shape.height = std::clamp(height, 0.001F, 1.F);
        shape.radius = std::clamp(radius, 0.F, 0.5F);
    }

    const auto previous = g_editorShapes;
    g_editorShapes = next;
    for (size_t index = 0; index < EDITOR_SHAPE_COUNT; ++index)
        damageTopbarMorph(previous[index], g_editorShapes[index]);
    return {};
}

SDispatchResult appearanceDispatcher(std::string arguments) {
    std::istringstream input{arguments};
    std::string operation;
    if (!(input >> operation))
        return {.success = false,
                .error = "expected preview, commit or reset"};

    if (operation == "reset") {
        g_activeAppearance = g_committedAppearance;
        g_activeAppearance.preview = false;
        damageAllMonitors();
        return {};
    }
    if (operation != "preview" && operation != "commit")
        return {.success = false,
                .error = "expected preview, commit or reset"};

    SAppearanceOptics next;
    if (!(input >> next.blur >> next.contrast >> next.reflection))
        return {.success = false,
                .error = "expected operation blur contrast reflection"};
    next.blur = std::clamp(next.blur, 0.F, 1.F);
    next.contrast = std::clamp(next.contrast, 0.8F, 1.35F);
    next.reflection = std::clamp(next.reflection, 0.F, 1.F);
    next.preview = operation == "preview";
    g_activeAppearance = next;
    if (operation == "commit") {
        g_committedAppearance = next;
        g_committedAppearance.preview = false;
        g_activeAppearance.preview = false;
    }
    damageAllMonitors();
    return {};
}

SDispatchResult lockLayoutDispatcher(std::string arguments) {
    std::istringstream input{arguments};
    std::string layout;
    if (!(input >> layout) || (layout != "editorial" && layout != "panel"))
        return {.success = false, .error = "expected editorial or panel"};

    const bool next = layout == "editorial";
    if (g_editorialLock == next)
        return {};
    g_editorialLock = next;
    damageAllMonitors();
    return {};
}

SDispatchResult sharedWidgetsShapeDispatcher(std::string arguments) {
    std::istringstream input{arguments};
    int enabled = 0;
    if (!(input >> enabled))
        return {.success = false, .error = "expected enabled flag"};

    if (enabled == 0) {
        const auto previous = g_sharedWidgetShapes;
        g_sharedWidgetShapes = {};
        g_sharedWidgetShapesActive = false;
        g_sharedWidgetCaustics = false;
        damageSharedWidgetShapes(previous, g_sharedWidgetShapes);
        return {};
    }

    int caustics = 0;
    if (!(input >> caustics))
        return {.success = false,
                .error = "expected caustics flag and nine widget shapes"};

    std::array<SSharedWidgetShape, SHARED_WIDGET_COUNT> next;
    bool anyActive = false;
    for (auto& shape : next) {
        int active = 0;
        if (!(input >> active >> shape.x >> shape.y >> shape.width
                    >> shape.height >> shape.radius >> shape.rotation
                    >> shape.opacity))
            return {.success = false,
                    .error = "expected active x y width height radius rotation opacity for nine widgets"};
        shape.active = active != 0;
        shape.x = std::clamp(shape.x, -1.F, 2.F);
        shape.y = std::clamp(shape.y, -1.F, 2.F);
        shape.width = std::clamp(shape.width, 0.F, 2.F);
        shape.height = std::clamp(shape.height, 0.F, 2.F);
        shape.radius = std::clamp(shape.radius, 0.F, 0.5F);
        shape.rotation = std::clamp(shape.rotation, -360.F, 360.F);
        shape.opacity = std::clamp(shape.opacity, 0.F, 1.F);
        anyActive = anyActive || (shape.active && shape.opacity > 0.001F
                                  && shape.width > 0.0001F
                                  && shape.height > 0.0001F);
    }

    const auto previous = g_sharedWidgetShapes;
    g_sharedWidgetShapes = next;
    g_sharedWidgetShapesActive = anyActive;
    g_sharedWidgetCaustics = caustics != 0;
    damageSharedWidgetShapes(previous, g_sharedWidgetShapes);
    return {};
}

SDispatchResult topbarSettleDispatcher(std::string) {
    // Static islands only need their own silhouettes refreshed after a
    // configuration change. Never repaint the complete monitor for the bar.
    for (const auto& shape : g_topbarShapes)
        damageTopbarMorph({}, shape);
    return {};
}

SDispatchResult rightMenuShapeDispatcher(std::string arguments) {
    std::istringstream input{arguments};
    int active = 0;
    float depth = 0.F;
    float halfHeight = 0.F;
    float straightHalfHeight = 0.F;
    float railWidth = 0.F;
    float centerY = 0.5F;
    if (!(input >> active >> depth >> halfHeight >> straightHalfHeight
                >> railWidth >> centerY))
        return {.success = false,
                .error = "expected active depth halfHeight straightHalfHeight railWidth centerY"};

    const SRightMenuMorph previous = g_rightMenuMorph;
    g_rightMenuMorph.active = active != 0;
    g_rightMenuMorph.depth = std::clamp(depth, 0.F, 0.25F);
    g_rightMenuMorph.halfHeight = std::clamp(halfHeight, 0.F, 0.5F);
    g_rightMenuMorph.straightHalfHeight = std::clamp(
        straightHalfHeight, 0.F, 0.5F);
    g_rightMenuMorph.railWidth = std::clamp(railWidth, 0.001F, 0.05F);
    g_rightMenuMorph.centerY = std::clamp(centerY, 0.F, 1.F);
    damageRightMenuMorph(previous, g_rightMenuMorph);
    return {};
}

Time::steady_dur causticsFrameInterval() {
    float refreshRate = 60.F;
    if (State::monitorState()) {
        for (const auto& monitor : State::monitorState()->monitors()) {
            if (monitor)
                refreshRate = std::max(refreshRate, monitor->m_refreshRate);
        }
    }
    refreshRate = std::clamp(refreshRate, 30.F, 240.F);
    return std::chrono::duration_cast<Time::steady_dur>(
        std::chrono::duration<double>(1.0 / static_cast<double>(refreshRate)));
}

void updateCaustics() {
    if (!g_caustics.enabled || !g_caustics.animating)
        return;

    const auto now = std::chrono::steady_clock::now();
    const float elapsed = std::clamp(
        std::chrono::duration<float>(now - g_caustics.lastTick).count(),
        0.F, 0.05F);
    g_caustics.lastTick = now;
    if (elapsed <= 0.F)
        return;

    g_caustics.phase = std::fmod(g_caustics.phase + elapsed, 4096.F);
    ++g_causticsFrames;
    damageCausticsRegion();
}

void syncCausticsTimer(bool immediate = false) {
    if (!g_causticsTimer)
        return;
    if (!g_caustics.enabled || !g_caustics.animating) {
        g_causticsTimer->updateTimeout(std::nullopt);
        return;
    }
    g_causticsTimer->updateTimeout(immediate
        ? Time::steady_dur::zero() : causticsFrameInterval());
}

void onCausticsTimer(SP<CEventLoopTimer> self, void*) {
    if (g_unloading)
        return;
    updateCaustics();
    if (g_caustics.enabled && g_caustics.animating)
        self->updateTimeout(causticsFrameInterval());
}

SDispatchResult causticsDispatcher(std::string arguments) {
    std::istringstream input{arguments};
    std::string mode;
    if (!(input >> mode))
        return {.success = false,
                .error = "expected state enabled intensity lines phase animating or reset"};

    if (mode == "reset") {
        const bool wasEnabled = g_caustics.enabled;
        g_caustics = {};
        syncCausticsTimer();
        if (wasEnabled)
            damageCausticsRegion();
        return {};
    }

    int enabled = 0;
    int lines = 1;
    int animating = 1;
    float intensity = 0.F;
    float phase = 0.F;
    if (mode != "state" || !(input >> enabled >> intensity >> lines >> phase))
        return {.success = false,
                .error = "expected state enabled intensity lines phase animating or reset"};
    input >> animating;

    g_caustics.enabled = enabled != 0;
    g_caustics.lines = lines != 0;
    g_caustics.animating = g_caustics.enabled && animating != 0;
    g_caustics.intensity = std::clamp(intensity, 0.F, 1.F);
    g_caustics.phase = std::fmod(std::max(0.F, phase), 4096.F);
    g_caustics.lastTick = std::chrono::steady_clock::now();
    syncCausticsTimer(true);
    damageCausticsRegion();
    return {};
}

void updateTransition() {
    if (!g_transition.animating)
        return;

    const auto elapsed = std::chrono::duration<float>(
        std::chrono::steady_clock::now() - g_transition.started).count();
    const float linear = std::clamp(elapsed / g_transition.durationSeconds, 0.F, 1.F);
    const float eased = g_transition.target > g_transition.start
        ? 1.F - std::pow(1.F - linear, 3.F)
        : std::pow(linear, 3.F);

    g_transition.current = g_transition.start
        + (g_transition.target - g_transition.start) * eased;

    if (linear >= 1.F) {
        g_transition.current = g_transition.target;
        g_transition.animating = false;
    }
}

void onTick() {
    const auto now = std::chrono::steady_clock::now();
    for (auto it = g_lyricsBeats.begin(); it != g_lyricsBeats.end();) {
        std::erase_if(it->second, [&](const auto& beat) {
            return std::chrono::duration<float>(now - beat.started).count() >= LYRICS_BEAT_SECONDS;
        });
        if (it->second.empty() || !g_connectedTopbars.contains(it->first)) it = g_lyricsBeats.erase(it);
        else ++it;
    }
    updateTransition();
    if (g_transition.animating)
        damageAllMonitors();
    // Active bar shapes exist only while Liquid Glass is selected. Damage
    // those narrow regions so the shader's time-based refraction can move;
    // never repaint the complete desktop for this subtle animation.
    for (const auto& shape : g_topbarShapes) {
        if (shape.active)
            damageTopbarMorph({}, shape);
    }
    for (const auto& [monitor, shape] : g_unifiedBarShapes) {
        if (shape.active)
            damageTopbarMorph({}, shape, monitor);
    }
    if (State::monitorState() && g_pHyprRenderer) {
        for (const auto& monitor : State::monitorState()->monitors()) {
            if (!monitor) continue;
            const auto found = g_connectedTopbars.find(monitor->m_name);
            if (found != g_connectedTopbars.end() && found->second.active)
                g_pHyprRenderer->damageBox(CBox{monitor->m_position.x, monitor->m_position.y,
                    monitor->m_size.x, found->second.barHeight * monitor->m_size.y + 1});
        }
    }
}

SDispatchResult transitionDispatcher(std::string arguments) {
    updateTransition();

    std::istringstream input{arguments};
    std::string mode;
    float requestedMilliseconds = 0.F;
    if (!(input >> mode))
        return {.success = false, .error = "expected open, close, or reset"};
    input >> requestedMilliseconds;

    if (mode == "reset") {
        g_transition.current = 0.F;
        g_transition.start = 0.F;
        g_transition.target = 0.F;
        g_transition.animating = false;
        damageAllMonitors();
        return {};
    }

    if (mode != "open" && mode != "close")
        return {.success = false, .error = "expected open, close, or reset"};

    g_transition.start = g_transition.current;
    g_transition.target = mode == "open" ? 1.F : 0.F;
    const float fallback = mode == "open" ? 0.52F : 0.42F;
    const float requested = requestedMilliseconds > 0.F
        ? std::clamp(requestedMilliseconds / 1000.F, 0.05F, 2.F) : fallback;
    g_transition.durationSeconds = requested
        * std::max(0.001F, std::abs(g_transition.target - g_transition.start));
    g_transition.started = std::chrono::steady_clock::now();
    g_transition.animating = std::abs(g_transition.target - g_transition.start) > 0.001F;
    damageAllMonitors();
    return {};
}

SDispatchResult barBlurDispatcher(std::string arguments) {
    if (arguments != "0" && arguments != "1")
        return {.success = false, .error = "expected 0 or 1"};
    g_barBlurEnabled = arguments == "1";
    damageAllMonitors();
    return {};
}

SDispatchResult widgetBlurDispatcher(std::string arguments) {
    if (arguments != "0" && arguments != "1")
        return {.success = false, .error = "expected 0 or 1"};
    g_widgetBlurEnabled = arguments == "1";
    damageAllMonitors();
    return {};
}

SDispatchResult liquidStyleDispatcher(std::string arguments) {
    std::istringstream input{arguments};
    std::string style;
    int light = 0;
    if (!(input >> style >> light) || (style != "clear" && style != "frosted"))
        return {.success = false, .error = "expected clear or frosted followed by light flag"};
    g_liquidFrosted = style == "frosted";
    g_liquidLight = light != 0;
    damageAllMonitors();
    return {};
}

SDispatchResult barRefractionDispatcher(std::string arguments) {
    const auto strength = parseBarRefraction(arguments);
    if (!strength)
        return {.success = false, .error = "expected finite bar refraction strength from 0 to 10"};
    g_barRefractionOverride = *strength;
    damageAllMonitors();
    return {};
}

SDispatchResult wallpaperDispatcher(std::string arguments) {
    std::istringstream input{arguments};
    float amount = 0.F;
    if (!(input >> amount) || !std::isfinite(amount))
        return {.success = false, .error = "expected wallpaper blur strength from 0 to 1"};
    g_wallpaperBlur = std::clamp(amount, 0.F, 1.F);
    damageAllMonitors();
    return {};
}

SDispatchResult terminalBarMatchDispatcher(std::string arguments) {
    if (arguments != "0" && arguments != "1")
        return {.success = false, .error = "expected 0 or 1"};
    g_terminalBarMatch = arguments == "1";
    if (g_terminalBarMatch) g_terminalFollowBar = false;
    damageAllMonitors();
    return {};
}

SDispatchResult terminalBrightnessDispatcher(std::string arguments) {
    std::istringstream input{arguments};
    float brightness = 1.F;
    std::string trailing;
    if (!(input >> brightness) || (input >> trailing) || !std::isfinite(brightness)
            || brightness < .8F || brightness > 1.2F)
        return {.success = false, .error = "expected brightness from 0.8 to 1.2"};
    g_terminalBarBrightness = brightness;
    damageAllMonitors();
    return {};
}

SDispatchResult barBrightnessDispatcher(std::string arguments) {
    std::istringstream input{arguments};
    float brightness = 1.F;
    std::string trailing;
    if (!(input >> brightness) || (input >> trailing) || !std::isfinite(brightness)
            || brightness < .2F || brightness > 1.2F)
        return {.success = false, .error = "expected bar brightness from 0.2 to 1.2"};
    g_barBrightness = brightness;
    for (const auto& monitor : State::monitorState()->monitors()) {
        monitor->m_blurFBDirty = true;
        monitor->m_blurFBShouldRender = true;
    }
    damageAllMonitors();
    return {};
}

SDispatchResult terminalFollowBarDispatcher(std::string arguments) {
    if (arguments != "0" && arguments != "1")
        return {.success = false, .error = "expected 0 or 1"};
    g_terminalFollowBar = arguments == "1";
    if (g_terminalFollowBar) g_terminalBarMatch = false;
    for (const auto& monitor : State::monitorState()->monitors()) {
        monitor->m_blurFBDirty = true;
        monitor->m_blurFBShouldRender = true;
    }
    damageAllMonitors();
    return {};
}

SDispatchResult terminalGlassDispatcher(std::string arguments) {
    const auto next = parseTerminalGlassControl(arguments);
    if (!next) return {.success = false, .error = "expected 0 or 1 followed by strength from 0 to 3"};
    const bool wasActive = terminalOpticsActive();
    g_terminalControl = next;
    if (!terminalOpticsActive()) {
        Render::GL::g_pHyprOpenGL->makeEGLCurrent();
        g_terminalBackdrops.clear();
    } else if (!wasActive) {
        for (const auto& monitor : State::monitorState()->monitors()) {
            monitor->m_blurFBDirty = true;
            monitor->m_blurFBShouldRender = true;
        }
    }
    damageAllMonitors();
    return {};
}

void hkDrawTex(Render::IElementRenderer* renderer, WP<CTexPassElement> element, const CRegion& damage) {
    const auto original = reinterpret_cast<DrawTexFn>(g_drawTex->m_original);
    const auto layer = element ? element->m_data.currentLS.lock() : nullptr;
    if (g_unloading || !layer || (!layer->m_namespace.starts_with("velora-shell-")
            && layer->m_namespace != SELECTOR_NAMESPACE)) {
        original(renderer, element, damage);
        return;
    }
    // Hyprland's shader blur blend otherwise fills transparent texels with
    // an opaque backdrop. Our layers can span a monitor, while only their
    // QML material pixels are visible. Request the alpha-mask shader variant
    // for the regular QML pass, including the glass/fallback branches below.
    const bool oldForceBlurBlend = element->m_data.forceBlurBlend;
    element->m_data.forceBlurBlend = true;
    Hyprutils::Utils::CScopeGuard restoreBlurMask{[element, oldForceBlurBlend]() {
        element->m_data.forceBlurBlend = oldForceBlurBlend;
    }};
    const auto material = layer->m_monitor
        ? g_desktopBarMaterials.find(layer->m_monitor->m_name) : g_desktopBarMaterials.end();
    if (layer->m_namespace == EDITOR_NAMESPACE
            && !hasBottomSettings(layer->m_monitor ? layer->m_monitor->m_name : "")
            && std::none_of(g_editorShapes.begin(), g_editorShapes.end(),
                            [](const auto& shape) { return shape.active; })) {
        // Settings without a liquid shape use the QML compositor blur region.
        original(renderer, element, damage);
        return;
    }
    if (layer->m_namespace == UNIFIED_BAR_NAMESPACE && g_barBlurEnabled
            && material != g_desktopBarMaterials.end() && material->second.mode == 1) {
        // Prepare the normal compositor blur for QML panels outside the native
        // rail outline (search, agenda and the existing system popup).
        original(renderer, element, damage);
        return;
    }
    if (layer->m_namespace == TOPBAR_NAMESPACE && layer->m_monitor) {
        const auto found = g_connectedTopbars.find(layer->m_monitor->m_name);
        if (g_barBlurEnabled && found != g_connectedTopbars.end() && !found->second.active) {
            // Glass uses the compositor blur through the exact QML alpha shape.
            if (element->m_data.blur) ++g_topbarBlurDraws;
            original(renderer, element, damage);
            return;
        }
    }
    if (g_barBlurEnabled && layer->m_namespace == UNIFIED_BAR_NAMESPACE
            && !unifiedBarShape(layer->m_monitor ? layer->m_monitor->m_name : "").active) {
        // The same compositor blur serves both glass bars. Liquid retains
        // its native refraction path, and transparent pixels stay untouched.
        if (element->m_data.blur) ++g_sidebarBlurDraws;
        original(renderer, element, damage);
        return;
    }
    if (g_widgetBlurEnabled && layer->m_namespace == SHARED_WIDGETS_NAMESPACE
            && !g_sharedWidgetShapesActive) {
        // Glass cards use the compositor's blur clipped to their alpha and
        // individual regions. Liquid cards keep their native lens rendering.
        if (element->m_data.blur) ++g_widgetBlurDraws;
        original(renderer, element, damage);
        return;
    }
    // Intercept before IElementRenderer prepares any regular blur passes.
    // The GL hook below snapshots the sharp scene instead.
    const bool oldBlur = element->m_data.blur;
    element->m_data.blur = false;
    original(renderer, element, damage);
    element->m_data.blur = oldBlur;
}

bool isWallpaperLayer(const PHLLS& layer) {
    return layer && layer->m_layer == 0 && layer->m_mapped
        && (layer->m_namespace == "mpvpaper" || layer->m_namespace == "awww-daemon"
            || layer->m_namespace == "swww-daemon");
}

void clearWallpaperTransition() {
    if (Render::GL::g_pHyprOpenGL)
        Render::GL::g_pHyprOpenGL->makeEGLCurrent();
    g_wallpaperTransition = {};
    if (g_wallpaperTimer) g_wallpaperTimer->updateTimeout(std::nullopt);
}

void onWallpaperTimer(SP<CEventLoopTimer>, void*) {
    if (g_wallpaperTransition.timing.expired()) {
        clearWallpaperTransition();
        damageAllMonitors();
        return;
    }
    if (g_wallpaperTransition.timing.revealing) {
        damageAllMonitors();
        g_wallpaperTimer->updateTimeout(std::chrono::milliseconds(16));
    } else {
        g_wallpaperTimer->updateTimeout(std::chrono::seconds(5));
    }
}

SDispatchResult wallpaperTransitionDispatcher(std::string arguments) {
    std::istringstream input(arguments);
    std::string action, token, mode;
    int duration = 420;
    input >> action >> token;
    if (token.empty() || token.size() > 80 || token.find_first_not_of("0123456789-") != std::string::npos)
        return {.success = false, .error = "invalid wallpaper transition token"};
    if (action == "cancel") {
        if (g_wallpaperTransition.timing.matches(token)) {
            clearWallpaperTransition();
            damageAllMonitors();
        }
        return {};
    }
    if (action == "reveal") {
        if (!g_wallpaperTransition.timing.matches(token))
            return {.success = false, .error = "stale wallpaper transition"};
        g_wallpaperTransition.timing.started = SWallpaperTransitionTiming::Clock::now();
        g_wallpaperTransition.timing.revealing = true;
        g_wallpaperTimer->updateTimeout(std::chrono::milliseconds(1));
        damageAllMonitors();
        return {};
    }
    if (action != "prepare" || !(input >> mode >> duration))
        return {.success = false, .error = "expected prepare TOKEN MODE DURATION_MS"};
    const std::unordered_map<std::string, float> modes{{"wave",0},{"grow",1},{"outer",2},{"fade",3},{"wipe",4}};
    const auto effect = modes.find(mode);
    if (effect == modes.end() || !g_pHyprRenderer || !Render::GL::g_pHyprOpenGL || !State::monitorState())
        return {.success = false, .error = "wallpaper transition renderer unavailable"};
    Render::GL::g_pHyprOpenGL->makeEGLCurrent();
    if (!g_wallpaperShader) {
        auto shader = makeShared<CShader>();
        if (!shader->createProgram(LIQUID_GLASS_VERTEX, WALLPAPER_TRANSITION_FRAGMENT, true, true))
            return {.success = false, .error = "wallpaper transition shader failed"};
        g_wallpaperShader = std::move(shader);
    }
    SWallpaperTransition next;
    next.timing.token = token;
    next.timing.duration = std::clamp(duration / 1000.F, .15F, 3.F);
    next.mode = effect->second;
    // The compositor renders its existing wallpaper buffer into GPU memory.
    // No readback, PNG, CPU decode, QML surface or readiness polling.
    for (const auto& monitor : State::monitorState()->monitors()) {
        if (!monitor) continue;
        const auto& backgrounds = monitor->m_layerSurfaceLayers[0];
        for (auto it = backgrounds.rbegin(); it != backgrounds.rend(); ++it) {
            const auto layer = it->lock();
            if (!isWallpaperLayer(layer)) continue;
            const auto frame = g_pHyprRenderer->makeSnapshotFB(layer);
            if (frame && frame->getTexture())
                next.frames.emplace(monitor->m_name, frame);
            break;
        }
    }
    if (next.frames.empty())
        return {.success = false, .error = "no mapped wallpaper background"};
    constexpr std::array<std::array<float,2>,8> directions{{
        {1,0},{-1,0},{0,1},{0,-1},{1,1},{1,-1},{-1,1},{-1,-1}}};
    const auto now = SWallpaperTransitionTiming::Clock::now();
    int direction = std::chrono::duration_cast<std::chrono::microseconds>(now.time_since_epoch()).count() % 8;
    if (direction == g_wallpaperLastDirection) direction = (direction + 1) % 8;
    g_wallpaperLastDirection = direction;
    next.direction = directions[direction];
    next.phase = std::fmod(std::chrono::duration<float>(now.time_since_epoch()).count(), 6.2831853F);
    next.timing.prepared = now;
    g_wallpaperTransition = std::move(next);
    g_wallpaperTimer->updateTimeout(std::chrono::seconds(5));
    return {};
}

void renderWallpaperTransition(const PHLLS& layer, const CRegion& damage) {
    if (!isWallpaperLayer(layer) || !layer->m_monitor || !g_wallpaperShader
        || g_wallpaperTransition.timing.token.empty() || g_wallpaperTransition.timing.expired())
        return;
    const auto found = g_wallpaperTransition.frames.find(layer->m_monitor->m_name);
    if (found == g_wallpaperTransition.frames.end() || !found->second || !found->second->getTexture())
        return;
    const auto frame = found->second;
    const CBox box{0,0,layer->m_monitor->m_transformedSize.x,layer->m_monitor->m_transformedSize.y};
    CRegion region{box};
    if (!damage.empty()) region.intersect(damage);
    if (region.empty()) return;
    const auto shader = Render::GL::g_pHyprOpenGL->useShader(g_wallpaperShader);
    if (!shader) return;
    shader->setUniformMatrix3fv(SHADER_PROJ,1,GL_TRUE,g_pHyprRenderer->projectBoxToTarget(box).getMatrix());
    shader->setUniformInt(SHADER_TEX,0);
    shader->setUniformFloat2(SHADER_FULL_SIZE,frame->m_size.x,frame->m_size.y);
    glUniform1f(glGetUniformLocation(shader->program(),"progress"),g_wallpaperTransition.timing.progress());
    glUniform1f(glGetUniformLocation(shader->program(),"mode"),g_wallpaperTransition.mode);
    glUniform1f(glGetUniformLocation(shader->program(),"phase"),g_wallpaperTransition.phase);
    glUniform2f(glGetUniformLocation(shader->program(),"direction"),
        g_wallpaperTransition.direction[0],g_wallpaperTransition.direction[1]);
    glActiveTexture(GL_TEXTURE0);
    frame->getTexture()->bind();
    frame->getTexture()->setTexParameter(GL_TEXTURE_MIN_FILTER,GL_LINEAR);
    frame->getTexture()->setTexParameter(GL_TEXTURE_MAG_FILTER,GL_LINEAR);
    Render::GL::g_pHyprOpenGL->blend(true);
    glBindVertexArray(shader->getUniformLocation(SHADER_SHADER_VAO));
    region.forEachRect([](const auto& rect) {
        Render::GL::g_pHyprOpenGL->scissor(&rect,g_pHyprRenderer->m_renderData.transformDamage);
        glDrawArrays(GL_TRIANGLE_STRIP,0,4);
    });
    glBindVertexArray(0);
    frame->getTexture()->unbind();
    Render::GL::g_pHyprOpenGL->scissor(nullptr);
}

STerminalBackdrop& terminalBackdrop(const PHLMONITOR& monitor) {
    std::erase_if(g_terminalBackdrops, [](const auto& entry) { return !entry.second.monitor; });
    auto& cached = g_terminalBackdrops[monitor->m_name];
    if (cached.monitor.lock() != monitor)
        cached = {.monitor = monitor, .material = nullptr, .desktop = nullptr};
    return cached;
}

void hkGLDrawPreBlur(Render::GL::CGLElementRenderer* renderer, WP<CPreBlurElement> element, const CRegion& damage) {
    const auto original = reinterpret_cast<DrawGLPreBlurFn>(g_drawGLPreBlur->m_original);
    const auto monitor = g_pHyprRenderer->m_renderData.pMonitor.lock();
    if (!g_unloading && monitor && terminalOpticsActive()) {
        auto& cached = terminalBackdrop(monitor);
        if (captureClearBackdrop(cached.desktop)) {
            const auto source = g_pHyprRenderer->m_renderData.currentFB;
            cached.desktop->setImageDescription(source->imageDescription());
            if (source->getTexture())
                cached.desktop->getTexture()->m_transform = source->getTexture()->m_transform;
            ++g_terminalDesktopCopies;
        } else
            cached.desktop.reset();
    }
    original(renderer, element, damage);
}

bool isKittySurface(WP<CTexPassElement> element) {
    if (!element || !element->m_data.surface || element->m_data.currentLS)
        return false;
    const auto surface = Desktop::View::CWLSurface::fromResource(element->m_data.surface);
    const auto view = surface ? surface->view() : nullptr;
    if (!view || view->type() != Desktop::View::VIEW_TYPE_WINDOW)
        return false;
    const auto window = Desktop::View::CWindow::fromView(view);
    if (!window || window->resource() != element->m_data.surface)
        return false;
    if (kittyClass(window->m_class) || kittyClass(window->m_initialClass))
        return true;
    const auto found = g_kittyIdentities.find(window.get());
    if (found != g_kittyIdentities.end() && found->second.window.lock() == window)
        return found->second.kitty;
    if (g_kittyIdentities.size() >= 128)
        std::erase_if(g_kittyIdentities, [](const auto& entry) { return !entry.second.window; });
    std::error_code error;
    const auto executable = std::filesystem::read_symlink(
        std::filesystem::path("/proc") / std::to_string(window->getPID()) / "exe", error);
    const bool kitty = !error && kittyExecutable(executable.string());
    g_kittyIdentities[window.get()] = {window, kitty};
    return kitty;
}

SP<Render::ITexture> terminalGlassBackdrop(WP<CTexPassElement> element, const CRegion& damage) {
    if (!terminalOpticsActive() || !element->m_data.blur
            || !element->m_data.blurredBG || !g_pHyprRenderer
            || !Render::GL::g_pHyprOpenGL || !isKittySurface(element))
        return nullptr;
    const auto target = g_pHyprRenderer->m_renderData.currentFB;
    if (!target || target->m_size.x <= 0 || target->m_size.y <= 0)
        return nullptr;
    auto& program = g_terminalFollowBar ? g_terminalBarShader : g_terminalShader;
    if (!program) {
        if (g_terminalShaderFailed) return nullptr;
        auto shader = makeShared<CShader>();
        if (!shader->createProgram(LIQUID_GLASS_VERTEX, withTerminalGlassOptics(g_terminalFollowBar ? LIQUID_GLASS_FRAGMENT : TERMINAL_GLASS_FRAGMENT), true, true)) {
            g_terminalShaderFailed = true;
            return nullptr;
        }
        program = std::move(shader);
    }
    CRegion drawDamage = element->m_data.damage.empty() ? damage : element->m_data.damage;
    CBox drawBox = element->m_data.box;
    g_pHyprRenderer->m_renderData.renderModif.applyToBox(drawBox);
    // Native renderTextureInternal may draw the whole explicit clip instead
    // of intersecting damage. Its backdrop must be valid throughout that draw,
    // even when this reusable target last belonged to a different window.
    if (!element->m_data.clipRegion.empty() || !g_pHyprRenderer->m_renderData.clipBox.empty())
        drawDamage.add(drawBox);
    drawDamage.intersect(drawBox);
    if (drawDamage.empty()) return nullptr;
    const auto monitor = g_pHyprRenderer->m_renderData.pMonitor.lock();
    if (!monitor) return nullptr;
    const auto material = g_desktopBarMaterials.find(monitor->m_name);
    const bool follows = g_terminalFollowBar && !g_terminalBarMatch;
    if (follows && (material == g_desktopBarMaterials.end() || material->second.mode == 0
            || material->second.tint[3] >= .999F)) return nullptr;
    auto& cached = terminalBackdrop(monitor);
    if (!cached.material)
        cached.material = makeShared<Render::GL::CGLFramebuffer>("velora-kitty-glass");
    const auto backdrop = cached.material;
    const auto background = element->m_data.blurredBG;
    // Precomputed blur may skip repainting behind opaque client glyphs. Keep
    // its sharp desktop at the same pre-window stage, so refraction cannot
    // pick up this window's pixels from a previous frame. Live blur already
    // tracks the scene damage and can sample the current render target safely.
    const auto scene = element->m_data.blockBlurOptimization.value_or(false)
        ? target->getTexture() : cached.desktop ? cached.desktop->getTexture() : nullptr;
    const bool sharp = scene && scene->m_size == background->m_size
        && scene->m_transform == background->m_transform
        && monitor->m_transform == WL_OUTPUT_TRANSFORM_NORMAL
        && (!scene->m_imageDescription || !background->m_imageDescription
            || !scene->m_imageDescription->needsCM(background->m_imageDescription));
    const auto opticalSource = sharp ? scene : background;
    SP<Render::ITexture> preparedOptical;
    if (follows && material->second.mode == 3 && material->second.blur
            && g_barBlurEnabled && g_liquidFrosted) {
        CRegion sampling{drawDamage};
        sampling.expand(opticalGlassSamplePadding(barRefractionStrength(),monitor->m_scale,
            std::max(opticalSource->m_size.x,opticalSource->m_size.y)));
        preparedOptical = opticalBlurTexture(opticalSource,monitor->m_name,sampling,monitor->m_scale);
        if (!preparedOptical) return nullptr;
    }
    if (!backdrop->alloc(sc<int>(background->m_size.x), sc<int>(background->m_size.y),
                follows ? DRM_FORMAT_ABGR16161616F : target->m_drmFormat)
            || !backdrop->getTexture())
        return nullptr;
    backdrop->setImageDescription(background->m_imageDescription);
    backdrop->getTexture()->m_transform = background->m_transform;

    // Reuse the blur already prepared by IElementRenderer. One reusable GPU
    // target per output avoids reallocating between monitors of different
    // sizes; no scene snapshot/readback or second blur per Kitty window.
    GLint viewport[4];
    glGetIntegerv(GL_VIEWPORT, viewport);
    g_pHyprRenderer->bindFB(backdrop);
    g_pHyprRenderer->setViewport(0, 0, sc<int>(background->m_size.x), sc<int>(background->m_size.y));
    Hyprutils::Utils::CScopeGuard restoreTarget{[target, viewport]() {
        g_pHyprRenderer->bindFB(target);
        g_pHyprRenderer->setViewport(viewport[0], viewport[1], viewport[2], viewport[3]);
        Render::GL::g_pHyprOpenGL->scissor(nullptr);
    }};
    // Render in the prepared blur texture's coordinate system. The original
    // client shader applies monitor rotation/mirroring when it samples this
    // texture; applying the output projection here would rotate it twice.
    const auto matrix = Mat3x3::outputProjection(background->m_size, HYPRUTILS_TRANSFORM_NORMAL)
        .projectBox(drawBox, HYPRUTILS_TRANSFORM_NORMAL);
    auto shader = Render::GL::g_pHyprOpenGL->useShader(program);
    if (!shader) return nullptr;
    const float scale = monitor->m_scale;
    shader->setUniformMatrix3fv(SHADER_PROJ, 1, GL_TRUE, matrix.getMatrix());
    shader->setUniformInt(SHADER_TEX, 0);
    shader->setUniformFloat2(SHADER_FULL_SIZE, background->m_size.x, background->m_size.y);
    if (follows) {
        const float width = background->m_size.x, height = background->m_size.y;
        const float panelScale = width / 1600.F;
        const auto& frame = unifiedBarShape(monitor->m_name);
        const auto lens = barLensParameters(panelScale, std::max(1.F,
            frame.active ? frame.width * width * .5F : 20.F * scale));
        shader->setUniformFloat2(SHADER_TOP_LEFT, 0, 0);
        shader->setUniformFloat2(SHADER_BOTTOM_RIGHT, drawBox.width * .5F, drawBox.height * .5F);
        shader->setUniformFloat(SHADER_RADIUS, element->m_data.round);
        shader->setUniformFloat(SHADER_ALPHA, 1.F);
        shader->setUniformFloat(SHADER_DISTORT, lens.refraction);
        shader->setUniformFloat(SHADER_CONTRAST, lens.edgeWidth);
        shader->setUniformFloat(SHADER_NOISE, lens.dispersion);
        shader->setUniformFloat(SHADER_BRIGHTNESS, 1.025F);
        shader->setUniformFloat(SHADER_VIBRANCY, 1.12F);
        shader->setUniformFloat(SHADER_TIME, g_pHyprRenderer->m_globalTimer.getSeconds());
        shader->setUniformFloat4(SHADER_POINTER, 0, 0, 0, panelScale);
        shader->setUniformFloat4(SHADER_POINTER_SHAPE, 0, 0, 0, 1);
        shader->setUniformFloat4(SHADER_COLOR, .94F, .97F, 1.F, g_panelTint->value() * .32F);
        glUniform2f(glGetUniformLocation(shader->program(), "windowTopLeft"), drawBox.x / width, drawBox.y / height);
        glUniform2f(glGetUniformLocation(shader->program(), "windowBottomRight"),
            (drawBox.x + drawBox.width) / width, (drawBox.y + drawBox.height) / height);
        glUniform1f(glGetUniformLocation(shader->program(), "barRefractionStrength"), barRefractionStrength());
        glUniform1f(glGetUniformLocation(shader->program(), "opticalScale"), scale);
        glUniform2f(glGetUniformLocation(shader->program(), "frost"), g_liquidFrosted ? 1.F : 0.F,g_liquidLight ? 1.F : 0.F);
        glUniform1f(glGetUniformLocation(shader->program(), "terminalBackdrop"), 1.F);
        glUniform1f(glGetUniformLocation(shader->program(), "terminalBrightness"), g_terminalBarBrightness);
        glUniform1f(glGetUniformLocation(shader->program(), "barBrightness"), g_barBrightness);
        glUniform4f(glGetUniformLocation(shader->program(), "barMaterial"), 1, material->second.mode, 1, 0);
        glUniform4fv(glGetUniformLocation(shader->program(), "barTint"), 1, material->second.tint.data());
    } else {
    shader->setUniformInt(SHADER_BLURRED_BG, 1);
    shader->setUniformFloat2(SHADER_BOTTOM_RIGHT, drawBox.width, drawBox.height);
    shader->setUniformFloat(SHADER_RADIUS, element->m_data.round);
    shader->setUniformFloat(SHADER_ROUNDING_POWER, element->m_data.roundingPower);
    shader->setUniformFloat(SHADER_DISTORT, TERMINAL_REFRACTION_PIXELS * scale);
    shader->setUniformFloat(SHADER_CONTRAST, TERMINAL_RIM_WIDTH * scale);
    shader->setUniformFloat(SHADER_ALPHA, terminalGlassStrength());
    shader->setUniformFloat(SHADER_VIBRANCY, sharp ? 1.F : 0.F);
    }
    const bool clearBar = follows && material->second.mode > 1 && !g_liquidFrosted;
    const auto source = preparedOptical ? preparedOptical
        : follows && !clearBar && material->second.blur && g_barBlurEnabled ? background : opticalSource;
    glActiveTexture(GL_TEXTURE0);
    source->bind();
    glActiveTexture(GL_TEXTURE1);
    background->bind();
    Render::GL::g_pHyprOpenGL->blend(false);
    glBindVertexArray(shader->getUniformLocation(SHADER_SHADER_VAO));
    drawDamage.forEachRect([](const auto& rect) {
        Render::GL::g_pHyprOpenGL->scissor(&rect, false);
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    });
    glBindVertexArray(0);
    background->unbind();
    glActiveTexture(GL_TEXTURE0);
    source->unbind();
    Render::GL::g_pHyprOpenGL->blend(true);
    ++g_terminalGlassDraws;
    if (follows) ++g_terminalFollowBarDraws;
    if (sharp) ++g_terminalSharpDraws;
    return backdrop->getTexture();
}

void hkGLDrawTex(Render::GL::CGLElementRenderer* renderer, WP<CTexPassElement> element, const CRegion& damage) {
    const auto original = reinterpret_cast<DrawGLTexFn>(g_drawGLTex->m_original);
    if (g_unloading || !element) {
        original(renderer, element, damage);
        return;
    }

    if (const auto backdrop = terminalGlassBackdrop(element, damage)) {
        const auto previous = element->m_data.blurredBG;
        element->m_data.blurredBG = backdrop;
        Hyprutils::Utils::CScopeGuard restoreBackdrop{[element, previous]() {
            element->m_data.blurredBG = previous;
        }};
        // Preserve the compositor's client shader: glyphs, Kitty images,
        // opacity, fade animations and rounded corners follow their normal path.
        original(renderer, element, damage);
        return;
    }

    const auto layer = element->m_data.currentLS.lock();
    if (isWallpaperLayer(layer)) {
        original(renderer, element, damage);
        renderWallpaperTransition(layer, damage);
        return;
    }
    if (layer && layer->m_namespace == WALLPAPER_EFFECTS_NAMESPACE) {
        if (g_wallpaperBlur > 0.F && captureClearBackdrop())
            renderDesktopBackdrop(element, damage);
        const bool oldBlur = element->m_data.blur;
        element->m_data.blur = false;
        original(renderer, element, damage);
        element->m_data.blur = oldBlur;
        return;
    }
    const bool panel = layer && layer->m_namespace == PANEL_NAMESPACE;
    const bool topbar = layer && layer->m_namespace == TOPBAR_NAMESPACE;
    const bool unifiedBar = layer
        && layer->m_namespace == UNIFIED_BAR_NAMESPACE;
    const bool rightMenu = layer && layer->m_namespace == RIGHT_MENU_NAMESPACE;
    const bool settings = layer && layer->m_namespace == SETTINGS_NAMESPACE;
    const bool editor = layer && layer->m_namespace == EDITOR_NAMESPACE
        && (hasBottomSettings(layer->m_monitor ? layer->m_monitor->m_name : "")
            || std::any_of(g_editorShapes.begin(), g_editorShapes.end(),
                          [](const auto& shape) { return shape.active; }));
    const bool selector = layer && layer->m_namespace == SELECTOR_NAMESPACE;
    if (selector && (!layer->m_monitor || !g_selectorShapes.contains(layer->m_monitor->m_name))) {
        original(renderer, element, damage);
        return;
    }
    const bool sharedWidgets = layer
        && layer->m_namespace == SHARED_WIDGETS_NAMESPACE;
    const bool opticalSurface = panel || topbar || unifiedBar || rightMenu
        || settings || editor || sharedWidgets || selector;
    const std::string monitorName = layer && layer->m_monitor ? layer->m_monitor->m_name : "";
    const bool cachedFrame = unifiedBar && g_frameBackdrops.contains(monitorName)
        && g_frameBackdrops.at(monitorName);
    const bool captured = opticalSurface && (cachedFrame || (topbar
        ? captureClearBackdrop(g_frameBackdrops[monitorName]) : captureClearBackdrop()));
    if (!captured) {
        original(renderer, element, damage);
        return;
    }
    if (sharedWidgets)
        // Keep the existing capture, swapping buffers instead of copying the
        // sharp desktop a second time or keeping a pointer that is overwritten.
        std::swap(g_clearBackdrop, g_frameFusionBackdrops[monitorName].sharp);
    bool rendered = false;
    if (sharedWidgets) {
        const auto material = g_desktopBarMaterials.find(monitorName);
        if (material != g_desktopBarMaterials.end()
                && !hasBottomSettings(monitorName)
                && unifiedBarShape(monitorName).active)
            rendered = renderLiquidBackdrop(element, damage, true, false,
                false, &unifiedBarShape(monitorName));
        rendered = renderSharedWidgetsBackdrop(element, damage, g_frameFusionBackdrops[monitorName].sharp) || rendered;
    }
    else if (topbar) {
        const auto found = layer->m_monitor
            ? g_connectedTopbars.find(layer->m_monitor->m_name) : g_connectedTopbars.end();
        if (found != g_connectedTopbars.end()) {
            if (found->second.active)
                rendered = renderLiquidBackdrop(element, damage, true, false, false, &found->second);
        } else {
            for (const auto& shape : g_topbarShapes) {
                if (shape.active)
                    rendered = renderLiquidBackdrop(element, damage, true, false,
                                                     false, &shape) || rendered;
            }
        }
    } else if (unifiedBar && unifiedBarShape(monitorName).active) {
        rendered = renderLiquidBackdrop(element, damage, true, false,
                                        false, &unifiedBarShape(monitorName));
    } else if (selector) {
        const auto found = g_selectorShapes.find(monitorName);
        if (found != g_selectorShapes.end() && found->second.active)
            // Same clear lens as the lock/editor; no frost or compositor blur.
            rendered = renderLiquidBackdrop(element, damage, false, false,
                                             false, &found->second, true);
    } else if (editor) {
        if (hasBottomSettings(monitorName))
            rendered = renderLiquidBackdrop(element, damage, true, false,
                false, &unifiedBarShape(monitorName));
        for (const auto& shape : g_editorShapes) {
            if (shape.active)
                rendered = renderLiquidBackdrop(element, damage, false, false,
                                                 false, &shape, true) || rendered;
        }
    } else if ((panel && !g_editorialLock) || rightMenu || settings)
        rendered = renderLiquidBackdrop(element, damage, topbar, rightMenu, settings);
    if (!rendered) {
        original(renderer, element, damage);
        return;
    }

    // The native material has already rendered Hyprland blur or refraction.
    // Draw only the transparent QML surface and its foreground content now;
    // letting Hyprland blend its regular blur again would flatten the lens
    // and replace antialiased text/corner pixels with an opaque bright
    // backdrop. This applies to glass as well as liquid materials.
    const bool oldBlur = element->m_data.blur;
    element->m_data.blur = false;
    original(renderer, element, damage);
    element->m_data.blur = oldBlur;
}

int luaDispatch(lua_State* state) {
    const std::string name = luaL_checkstring(state, 1);
    const std::string arguments = luaL_checkstring(state, 2);
    // Expose only this plugin's validated dispatchers, never arbitrary eval.
    static const std::unordered_map<std::string, SDispatchResult (*)(std::string)> handlers = {
        {"transition", transitionDispatcher}, {"dial", dialDispatcher},
        {"caustics", causticsDispatcher}, {"topbar-connected", connectedTopbarDispatcher},
        {"bar-blur", barBlurDispatcher}, {"widget-blur", widgetBlurDispatcher},
        {"liquid-style", liquidStyleDispatcher}, {"wallpaper", wallpaperDispatcher},
        {"wallpaper-transition", wallpaperTransitionDispatcher},
        {"terminal-glass-control", terminalGlassDispatcher},
        {"terminal-bar-match", terminalBarMatchDispatcher},
        {"terminal-follow-bar", terminalFollowBarDispatcher},
        {"terminal-brightness", terminalBrightnessDispatcher},
        {"bar-brightness", barBrightnessDispatcher},
        {"lyrics-beat", lyricsBeatDispatcher},
        {"bar-refraction", barRefractionDispatcher},
        {"topbar-shape", topbarShapeDispatcher}, {"desktop-bar-material", desktopBarMaterialDispatcher},
        {"unified-bar-shape", unifiedBarShapeDispatcher}, {"topbar-settle", topbarSettleDispatcher},
        {"right-menu-shape", rightMenuShapeDispatcher}, {"settings-shape", settingsShapeDispatcher},
        {"settings-connected", settingsConnectedDispatcher}, {"editor-shape", editorShapeDispatcher},
        {"selector-shape", selectorShapeDispatcher}, {"appearance", appearanceDispatcher},
        {"lock-layout", lockLayoutDispatcher}, {"shared-widgets-shape", sharedWidgetsShapeDispatcher}
    };
    const auto found = handlers.find(name);
    if (found == handlers.end()) return luaL_error(state, "unknown Velora dispatcher");
    const auto result = found->second(arguments);
    if (!result.success) return luaL_error(state, "%s", result.error.c_str());
    return 0;
}

std::string status(eHyprCtlOutputFormat format, std::string) {
    std::string materials = "[";
    for (const auto& [name, material] : g_desktopBarMaterials) {
        if (materials.size() > 1) materials += ",";
        materials += std::format(R"({{"monitor":"{}","mode":{},"tint":[{},{},{},{}]}})",
            name, material.mode, material.tint[0], material.tint[1], material.tint[2], material.tint[3]);
    }
    materials += "]";
    const auto desktopSize   = g_desktopSize ? g_desktopSize->value() : 0;
    const auto desktopPasses = g_desktopPasses ? g_desktopPasses->value() : 0;
    const auto desktopNoise = g_desktopNoise ? g_desktopNoise->value() : 0.F;
    const auto desktopContrast = g_desktopContrast ? g_desktopContrast->value() : 0.F;
    const auto desktopBrightness = g_desktopBrightness ? g_desktopBrightness->value() : 0.F;
    const auto desktopVibrancy = g_desktopVibrancy ? g_desktopVibrancy->value() : 0.F;
    const auto desktopVibrancyDarkness = g_desktopVibrancyDarkness ? g_desktopVibrancyDarkness->value() : 0.F;
    const auto panelSize     = g_panelSize ? g_panelSize->value() : 0;
    const auto panelPasses   = g_panelPasses ? g_panelPasses->value() : 0;
    const auto panelNoise = g_panelNoise ? g_panelNoise->value() : 0.F;
    const auto panelContrast = g_panelContrast ? g_panelContrast->value() : 0.F;
    const auto panelBrightness = g_panelBrightness ? g_panelBrightness->value() : 0.F;
    const auto panelVibrancy = g_panelVibrancy ? g_panelVibrancy->value() : 0.F;
    const auto panelVibrancyDarkness = g_panelVibrancyDarkness ? g_panelVibrancyDarkness->value() : 0.F;
    const auto panelRefraction = g_panelRefraction ? g_panelRefraction->value() : 0.F;
    const auto panelEdgeWidth = g_panelEdgeWidth ? g_panelEdgeWidth->value() : 0.F;
    const auto panelDispersion = g_panelDispersion ? g_panelDispersion->value() : 0.F;
    const auto panelTint = g_panelTint ? g_panelTint->value() : 0.F;
    const auto topbarSize = g_topbarSize ? g_topbarSize->value() : 0;
    const auto topbarPasses = g_topbarPasses ? g_topbarPasses->value() : 0;
    const auto topbarNoise = g_topbarNoise ? g_topbarNoise->value() : 0.F;
    const auto topbarContrast = g_topbarContrast ? g_topbarContrast->value() : 0.F;
    const auto topbarBrightness = g_topbarBrightness ? g_topbarBrightness->value() : 0.F;
    const auto topbarVibrancy = g_topbarVibrancy ? g_topbarVibrancy->value() : 0.F;
    const auto topbarVibrancyDarkness = g_topbarVibrancyDarkness ? g_topbarVibrancyDarkness->value() : 0.F;
    const auto topbarShapeCount = std::count_if(
        g_topbarShapes.begin(), g_topbarShapes.end(),
        [](const auto& shape) { return shape.active; });
    const auto editorShapeCount = std::count_if(
        g_editorShapes.begin(), g_editorShapes.end(),
        [](const auto& shape) { return shape.active; });
    const auto sharedWidgetShapeCount = std::count_if(
        g_sharedWidgetShapes.begin(), g_sharedWidgetShapes.end(),
        [](const auto& shape) { return shape.active && shape.opacity > 0.001F; });

    if (format == FORMAT_JSON)
        return std::format(
            R"({{"active":true,"abi":"{}","materials":{},"capabilities":[{}"alpha-mask","desktop-bar-material","transition","dial","caustics","topbar-connected","bar-blur","widget-blur","liquid-style","wallpaper","topbar-shape","unified-bar-shape","topbar-settle","right-menu-shape","settings-shape","settings-connected","editor-shape","selector-shape","appearance","lock-layout","shared-widgets-shape","wallpaper-transition","terminal-glass","terminal-glass-control","terminal-bar-match","bar-refraction","terminal-follow-bar","terminal-brightness","bar-brightness","lyrics-beat","lyrics-beat-palette","optical-glass"],"terminalGlass":{{"enabled":{},"strength":{:.3f},"draws":{},"sharpDraws":{},"desktopCopies":{},"shaderFailed":{},"source":"live-framebuffer-and-hyprland-blur","barMatch":{},"barMatchDraws":{},"followsBar":{},"followBarDraws":{},"brightness":{:.3f}}},"wallpaperBlur":{:.3f},"barRefraction":{:.3f},"barBrightness":{:.3f},"lyricsBeatCount":{},"liquidStyle":"{}","backdrop":"sharp-framebuffer","hyprlandBlur":{},"barBlur":{{"enabled":{},"source":"hyprland","topbarDraws":{},"sidebarDraws":{},"waveDraws":{}}},"appearance":{{"blur":{:.3f},"contrast":{:.3f},"reflection":{:.3f},"preview":{}}},"desktop":{{"size":{},"passes":{},"draws":{},"noise":{:.3f},"contrast":{:.3f},"brightness":{:.3f},"vibrancy":{:.3f},"vibrancyDarkness":{:.3f}}},"panel":{{"size":{},"passes":{},"draws":{},"refractionDraws":{},"noise":{:.3f},"contrast":{:.3f},"brightness":{:.3f},"vibrancy":{:.3f},"vibrancyDarkness":{:.3f},"refraction":{:.3f},"edgeWidth":{:.3f},"dispersion":{:.3f},"tint":{:.3f}}},"topbar":{{"size":{},"passes":{},"shapes":{},"draws":{},"refractionDraws":{},"noise":{:.3f},"contrast":{:.3f},"brightness":{:.3f},"vibrancy":{:.3f},"vibrancyDarkness":{:.3f}}},"rightMenu":{{"draws":{},"refractionDraws":{}}},"settings":{{"draws":{},"refractionDraws":{}}},"editor":{{"shapes":{},"draws":{},"refractionDraws":{},"connectedSettings":{}}},"sharedWidgets":{{"blurEnabled":{},"blurDraws":{},"active":{},"shapes":{},"draws":{},"refractionDraws":{},"caustics":{}}},"transition":{{"progress":{:.3f},"animating":{}}},"caustics":{{"enabled":{},"intensity":{:.3f},"lines":{},"animating":{},"frames":{}}}}})",
            __hyprland_api_get_client_hash(), materials, g_luaDispatch ? "\"lua-dispatch\"," : "",
            terminalGlassEnabled() ? "true" : "false",
            terminalGlassStrength(), g_terminalGlassDraws,
            g_terminalSharpDraws, g_terminalDesktopCopies, g_terminalShaderFailed ? "true" : "false", g_terminalBarMatch ? "true" : "false", g_terminalBarMatchDraws, g_terminalFollowBar ? "true" : "false", g_terminalFollowBarDraws, g_terminalBarBrightness, g_wallpaperBlur, barRefractionStrength(), g_barBrightness, g_lyricsBeatCount, g_liquidFrosted ? "frosted" : "clear", g_barBlurEnabled, g_barBlurEnabled, g_topbarBlurDraws, g_sidebarBlurDraws, g_waveBlurDraws,
            g_activeAppearance.blur, g_activeAppearance.contrast,
            g_activeAppearance.reflection,
            g_activeAppearance.preview ? "true" : "false",
            desktopSize, desktopPasses, g_desktopDraws, desktopNoise, desktopContrast,
            desktopBrightness, desktopVibrancy, desktopVibrancyDarkness,
            panelSize, panelPasses, g_panelDraws, g_refractionDraws,
            panelNoise, panelContrast, panelBrightness, panelVibrancy, panelVibrancyDarkness,
            panelRefraction, panelEdgeWidth, panelDispersion, panelTint,
            topbarSize, topbarPasses, topbarShapeCount,
            g_topbarDraws, g_topbarRefractionDraws,
            topbarNoise, topbarContrast,
            topbarBrightness, topbarVibrancy, topbarVibrancyDarkness,
            g_rightMenuDraws, g_rightMenuRefractionDraws,
            g_settingsDraws, g_settingsRefractionDraws,
            editorShapeCount, g_editorDraws, g_editorRefractionDraws, g_bottomSettings.size(),
            g_widgetBlurEnabled, g_widgetBlurDraws,
            g_sharedWidgetShapesActive ? "true" : "false",
            sharedWidgetShapeCount, g_sharedWidgetDraws,
            g_sharedWidgetRefractionDraws,
            g_sharedWidgetCaustics ? "true" : "false",
            g_transition.current, g_transition.animating ? "true" : "false",
            g_caustics.enabled ? "true" : "false", g_caustics.intensity,
            g_caustics.lines ? "true" : "false",
            g_caustics.animating ? "true" : "false",
            g_causticsFrames);

    return std::format("appearance blur={:.3f} contrast={:.3f} reflection={:.3f} preview={}\ndesktop size={} passes={} draws={} noise={:.3f} contrast={:.3f} brightness={:.3f} vibrancy={:.3f} vibrancy_darkness={:.3f}\npanel size={} passes={} draws={} refraction_draws={} noise={:.3f} contrast={:.3f} brightness={:.3f} vibrancy={:.3f} vibrancy_darkness={:.3f} refraction={:.3f} edge_width={:.3f} dispersion={:.3f} tint={:.3f}\ntopbar size={} passes={} shapes={} draws={} refraction_draws={} noise={:.3f} contrast={:.3f} brightness={:.3f} vibrancy={:.3f} vibrancy_darkness={:.3f}\nright_menu draws={} refraction_draws={}\nsettings draws={} refraction_draws={}\neditor shapes={} draws={} refraction_draws={}\nshared_widgets active={} shapes={} draws={} refraction_draws={} caustics={}\ntransition progress={:.3f} animating={}\ncaustics enabled={} intensity={:.3f} lines={} animating={} frames={}\n",
                       g_activeAppearance.blur, g_activeAppearance.contrast,
                       g_activeAppearance.reflection, g_activeAppearance.preview,
                       desktopSize, desktopPasses, g_desktopDraws, desktopNoise, desktopContrast,
                       desktopBrightness, desktopVibrancy, desktopVibrancyDarkness,
                       panelSize, panelPasses, g_panelDraws, g_refractionDraws,
                       panelNoise, panelContrast, panelBrightness, panelVibrancy, panelVibrancyDarkness,
                       panelRefraction, panelEdgeWidth, panelDispersion, panelTint,
                       topbarSize, topbarPasses, topbarShapeCount,
                       g_topbarDraws, g_topbarRefractionDraws,
                       topbarNoise, topbarContrast,
                       topbarBrightness, topbarVibrancy, topbarVibrancyDarkness,
                       g_rightMenuDraws, g_rightMenuRefractionDraws,
                       g_settingsDraws, g_settingsRefractionDraws,
                       editorShapeCount, g_editorDraws, g_editorRefractionDraws,
                       g_sharedWidgetShapesActive, sharedWidgetShapeCount,
                       g_sharedWidgetDraws, g_sharedWidgetRefractionDraws,
                       g_sharedWidgetCaustics,
                       g_transition.current, g_transition.animating,
                       g_caustics.enabled, g_caustics.intensity,
                       g_caustics.lines,
                       g_caustics.animating,
                       g_causticsFrames);
}

bool addIntValue(SP<Config::Values::CIntValue>& target, const char* name, const char* description,
                 const Config::INTEGER value, const Config::INTEGER maximum) {
    target = makeShared<Config::Values::CIntValue>(
        name, description, value,
        Config::Values::SIntValueOptions{.min = 1, .max = maximum});
    return HyprlandAPI::addConfigValueV2(g_handle, target);
}

bool addFloatValue(SP<Config::Values::CFloatValue>& target, const char* name, const char* description,
                   const Config::FLOAT value, const Config::FLOAT minimum,
                   const Config::FLOAT maximum) {
    target = makeShared<Config::Values::CFloatValue>(
        name, description, value,
        Config::Values::SFloatValueOptions{.min = minimum, .max = maximum});
    return HyprlandAPI::addConfigValueV2(g_handle, target);
}
} // namespace

APICALL EXPORT std::string PLUGIN_API_VERSION() {
    return HYPRLAND_API_VERSION;
}

APICALL EXPORT PLUGIN_DESCRIPTION_INFO PLUGIN_INIT(HANDLE handle) {
    g_handle = handle;
    if (std::string{__hyprland_api_get_hash()} != __hyprland_api_get_client_hash())
        throw std::runtime_error("Velora Shell blur plugin was built for a different Hyprland ABI");
    if (!g_pHyprRenderer || !Render::GL::g_pHyprOpenGL)
        throw std::runtime_error("Velora native blur requires the compositor OpenGL renderer");
    Render::GL::g_pHyprOpenGL->makeEGLCurrent();
    if (!ensureLiquidShader() || !ensureDesktopShader())
        throw std::runtime_error("Velora native blur shaders could not be compiled by this renderer");

    g_terminalGlass = makeShared<Config::Values::CIntValue>(
        "plugin:velora-blur:kitty_glass", "Liquid glass in all Kitty windows", 1,
        Config::Values::SIntValueOptions{.min = 0, .max = 1});
    if (!addFloatValue(g_barRefraction, "plugin:velora-blur:bar_refraction_strength",
            "Independent bar and frame refraction strength", BAR_DEFAULT_REFRACTION, 0.F, BAR_MAX_REFRACTION))
        throw std::runtime_error("Bar refraction configuration could not be registered");

    if (!HyprlandAPI::addConfigValueV2(g_handle, g_terminalGlass)
            || !addFloatValue(g_terminalStrength, "plugin:velora-blur:kitty_glass_strength",
                "Kitty lens refraction and reflection strength", 1.F, 0.F, TERMINAL_MAX_STRENGTH))
        throw std::runtime_error("Kitty liquid glass configuration could not be registered");

    if (!addIntValue(g_desktopSize, "plugin:velora-blur:desktop_size", "Velora desktop blur radius", 7, 40) ||
        !addIntValue(g_desktopPasses, "plugin:velora-blur:desktop_passes", "Velora desktop blur passes", 3, 8) ||
        !addFloatValue(g_desktopNoise, "plugin:velora-blur:desktop_noise", "Velora desktop blur grain", 0.004F, 0.F, 1.F) ||
        !addFloatValue(g_desktopContrast, "plugin:velora-blur:desktop_contrast", "Velora desktop blur contrast", 1.00F, 0.F, 2.F) ||
        !addFloatValue(g_desktopBrightness, "plugin:velora-blur:desktop_brightness", "Velora desktop blur brightness", 1.03F, 0.F, 2.F) ||
        !addFloatValue(g_desktopVibrancy, "plugin:velora-blur:desktop_vibrancy", "Velora desktop blur vibrancy", 0.72F, 0.F, 1.F) ||
        !addFloatValue(g_desktopVibrancyDarkness, "plugin:velora-blur:desktop_vibrancy_darkness", "Velora desktop dark-area vibrancy", 0.08F, 0.F, 1.F) ||
        !addIntValue(g_panelSize, "plugin:velora-blur:panel_size", "Velora panel blur radius", 10, 40) ||
        !addIntValue(g_panelPasses, "plugin:velora-blur:panel_passes", "Velora panel blur passes", 3, 8) ||
        !addFloatValue(g_panelNoise, "plugin:velora-blur:panel_noise", "Velora panel glass grain", 0.004F, 0.F, 1.F) ||
        !addFloatValue(g_panelContrast, "plugin:velora-blur:panel_contrast", "Velora panel glass contrast", 1.01F, 0.F, 2.F) ||
        !addFloatValue(g_panelBrightness, "plugin:velora-blur:panel_brightness", "Velora panel glass brightness", 0.98F, 0.F, 2.F) ||
        !addFloatValue(g_panelVibrancy, "plugin:velora-blur:panel_vibrancy", "Velora panel glass chroma lift", 0.38F, 0.F, 1.F) ||
        !addFloatValue(g_panelVibrancyDarkness, "plugin:velora-blur:panel_vibrancy_darkness", "Velora panel dark-area vibrancy", 0.08F, 0.F, 1.F) ||
        !addFloatValue(g_panelRefraction, "plugin:velora-blur:panel_refraction", "Velora panel edge refraction in pixels", 9.0F, 0.F, 48.F) ||
        !addFloatValue(g_panelEdgeWidth, "plugin:velora-blur:panel_edge_width", "Velora panel optical rim width", 28.0F, 6.F, 140.F) ||
        !addFloatValue(g_panelDispersion, "plugin:velora-blur:panel_dispersion", "Velora panel spectral separation", 0.65F, 0.F, 8.F) ||
        !addFloatValue(g_panelTint, "plugin:velora-blur:panel_tint", "Velora panel adaptive milky tint", 0.080F, 0.F, 0.35F) ||
        !addIntValue(g_topbarSize, "plugin:velora-blur:topbar_size", "Velora topbar blur radius", 3, 40) ||
        !addIntValue(g_topbarPasses, "plugin:velora-blur:topbar_passes", "Velora topbar blur passes", 2, 8) ||
        !addFloatValue(g_topbarNoise, "plugin:velora-blur:topbar_noise", "Velora topbar glass grain", 0.002F, 0.F, 1.F) ||
        !addFloatValue(g_topbarContrast, "plugin:velora-blur:topbar_contrast", "Velora topbar glass contrast", 0.96F, 0.F, 2.F) ||
        !addFloatValue(g_topbarBrightness, "plugin:velora-blur:topbar_brightness", "Velora topbar glass brightness", 0.98F, 0.F, 2.F) ||
        !addFloatValue(g_topbarVibrancy, "plugin:velora-blur:topbar_vibrancy", "Velora topbar glass vibrancy", 0.32F, 0.F, 1.F) ||
        !addFloatValue(g_topbarVibrancyDarkness, "plugin:velora-blur:topbar_vibrancy_darkness", "Velora topbar dark-area vibrancy", 0.12F, 0.F, 1.F))
        throw std::runtime_error("Velora Shell blur configuration could not be registered");

    g_globalSize.bind("decoration:blur:size");
    g_globalPasses.bind("decoration:blur:passes");
    g_globalNoise.bind("decoration:blur:noise");
    g_globalContrast.bind("decoration:blur:contrast");
    g_globalBrightness.bind("decoration:blur:brightness");
    g_globalVibrancy.bind("decoration:blur:vibrancy");
    g_globalVibrancyDarkness.bind("decoration:blur:vibrancy_darkness");

    const auto drawTex = findDrawTex();
    if (!drawTex)
        throw std::runtime_error("IElementRenderer::drawTex was not found");

    g_drawTex = HyprlandAPI::createFunctionHook(g_handle, drawTex, reinterpret_cast<const void*>(&hkDrawTex));
    if (!g_drawTex || !g_drawTex->hook())
        throw std::runtime_error("Velora Shell could not install its blur render hook");

    const auto glDrawTex = findGLDrawTex();
    if (!glDrawTex)
        throw std::runtime_error("CGLElementRenderer::draw(CTexPassElement) was not found");

    g_drawGLTex = HyprlandAPI::createFunctionHook(g_handle, glDrawTex, reinterpret_cast<const void*>(&hkGLDrawTex));
    if (!g_drawGLTex || !g_drawGLTex->hook())
        throw std::runtime_error("Velora Shell could not install its liquid glass render hook");

    void* preBlurDraw = nullptr;
    for (const auto& match : HyprlandAPI::findFunctionsByName(g_handle, "draw")) {
        if (match.demangled.contains("CGLElementRenderer::draw(")
                && match.demangled.contains("CPreBlurElement")) {
            preBlurDraw = match.address;
            break;
        }
    }
    if (!preBlurDraw)
        throw std::runtime_error("CGLElementRenderer::draw(CPreBlurElement) was not found");
    g_drawGLPreBlur = HyprlandAPI::createFunctionHook(g_handle, preBlurDraw, reinterpret_cast<const void*>(&hkGLDrawPreBlur));
    if (!g_drawGLPreBlur || !g_drawGLPreBlur->hook())
        throw std::runtime_error("Could not install Kitty pre-blur desktop hook");

    if (!HyprlandAPI::addDispatcherV2(g_handle, "velora-blur:transition", transitionDispatcher))
        throw std::runtime_error("Velora Shell blur transition dispatcher could not be registered");
    if (!HyprlandAPI::addDispatcherV2(g_handle, "velora-blur:dial", dialDispatcher))
        throw std::runtime_error("Velora Shell dial morph dispatcher could not be registered");
    if (!HyprlandAPI::addDispatcherV2(g_handle, "velora-blur:caustics", causticsDispatcher))
        throw std::runtime_error("Velora Shell caustics dispatcher could not be registered");
    if (!HyprlandAPI::addDispatcherV2(g_handle, "velora-blur:topbar-connected", connectedTopbarDispatcher))
        throw std::runtime_error("Could not register connected topbar dispatcher");
    if (!HyprlandAPI::addDispatcherV2(g_handle, "velora-blur:bar-blur", barBlurDispatcher))
        throw std::runtime_error("Could not register bar blur dispatcher");
    if (!HyprlandAPI::addDispatcherV2(g_handle, "velora-blur:widget-blur", widgetBlurDispatcher))
        throw std::runtime_error("Could not register widget blur dispatcher");
    if (!HyprlandAPI::addDispatcherV2(g_handle, "velora-blur:liquid-style", liquidStyleDispatcher))
        throw std::runtime_error("Could not register liquid glass style dispatcher");
    if (!HyprlandAPI::addDispatcherV2(g_handle, "velora-blur:bar-refraction", barRefractionDispatcher))
        throw std::runtime_error("Could not register bar refraction dispatcher");
    if (!HyprlandAPI::addDispatcherV2(g_handle, "velora-blur:wallpaper", wallpaperDispatcher))
        throw std::runtime_error("Could not register wallpaper blur dispatcher");
    if (!HyprlandAPI::addDispatcherV2(g_handle, "velora-blur:terminal-brightness", terminalBrightnessDispatcher))
        throw std::runtime_error("Could not register terminal brightness dispatcher");
    if (!HyprlandAPI::addDispatcherV2(g_handle, "velora-blur:lyrics-beat", lyricsBeatDispatcher))
        throw std::runtime_error("Could not register Lyrics beat dispatcher");

    if (!HyprlandAPI::addDispatcherV2(g_handle, "velora-blur:bar-brightness", barBrightnessDispatcher))
        throw std::runtime_error("Could not register bar brightness dispatcher");
    if (!HyprlandAPI::addDispatcherV2(g_handle, "velora-blur:terminal-follow-bar", terminalFollowBarDispatcher))
        throw std::runtime_error("Could not register terminal follow bar dispatcher");
    if (!HyprlandAPI::addDispatcherV2(g_handle, "velora-blur:terminal-bar-match", terminalBarMatchDispatcher))
        throw std::runtime_error("Could not register Kitty/bar material matching dispatcher");
    if (!HyprlandAPI::addDispatcherV2(g_handle, "velora-blur:terminal-glass-control", terminalGlassDispatcher))
        throw std::runtime_error("Could not register terminal liquid glass dispatcher");
    if (!HyprlandAPI::addDispatcherV2(g_handle, "velora-blur:topbar-shape", topbarShapeDispatcher))
        throw std::runtime_error("Velora Shell topbar shape dispatcher could not be registered");
    if (!HyprlandAPI::addDispatcherV2(g_handle, "velora-blur:desktop-bar-material", desktopBarMaterialDispatcher))
        throw std::runtime_error("Could not register desktop bar material dispatcher");
    if (!HyprlandAPI::addDispatcherV2(g_handle, "velora-blur:unified-bar-shape", unifiedBarShapeDispatcher))
        throw std::runtime_error("Velora Shell unified bar shape dispatcher could not be registered");
    if (!HyprlandAPI::addDispatcherV2(g_handle, "velora-blur:topbar-settle", topbarSettleDispatcher))
        throw std::runtime_error("Velora Shell topbar settle dispatcher could not be registered");
    if (!HyprlandAPI::addDispatcherV2(g_handle, "velora-blur:right-menu-shape", rightMenuShapeDispatcher))
        throw std::runtime_error("Velora Shell right menu shape dispatcher could not be registered");
    if (!HyprlandAPI::addDispatcherV2(g_handle, "velora-blur:settings-shape", settingsShapeDispatcher))
        throw std::runtime_error("Velora Shell settings shape dispatcher could not be registered");
    if (!HyprlandAPI::addDispatcherV2(g_handle, "velora-blur:settings-connected", settingsConnectedDispatcher))
        throw std::runtime_error("Could not register settings-connected dispatcher");
    if (!HyprlandAPI::addDispatcherV2(g_handle, "velora-blur:editor-shape", editorShapeDispatcher))
        throw std::runtime_error("Velora Shell editor shape dispatcher could not be registered");
    if (!HyprlandAPI::addDispatcherV2(g_handle, "velora-blur:selector-shape", selectorShapeDispatcher))
        throw std::runtime_error("Velora Shell selector shape dispatcher could not be registered");
    if (!HyprlandAPI::addDispatcherV2(g_handle, "velora-blur:appearance", appearanceDispatcher))
        throw std::runtime_error("Velora Shell appearance dispatcher could not be registered");
    if (!HyprlandAPI::addDispatcherV2(g_handle, "velora-blur:lock-layout", lockLayoutDispatcher))
        throw std::runtime_error("Velora Shell lock layout dispatcher could not be registered");
    if (!HyprlandAPI::addDispatcherV2(g_handle, "velora-blur:shared-widgets-shape", sharedWidgetsShapeDispatcher))
        throw std::runtime_error("Velora Shell shared widget shape dispatcher could not be registered");

    if (Config::mgr()->type() == Config::CONFIG_LUA) {
        g_luaDispatch = HyprlandAPI::addLuaFunction(g_handle, "velora", "dispatch", luaDispatch);
        if (!g_luaDispatch) throw std::runtime_error("Velora Lua transport could not be registered");
    }

    if (!HyprlandAPI::addDispatcherV2(g_handle, "velora-blur:wallpaper-transition", wallpaperTransitionDispatcher))
        throw std::runtime_error("Could not register wallpaper transition dispatcher");
    g_wallpaperTimer = makeShared<CEventLoopTimer>(std::nullopt,onWallpaperTimer,nullptr);
    g_pEventLoopManager->addTimer(g_wallpaperTimer);

    g_tickListener = Event::bus()->m_events.tick.listen(onTick);
    g_causticsTimer = makeShared<CEventLoopTimer>(
        std::nullopt, onCausticsTimer, nullptr);
    g_pEventLoopManager->addTimer(g_causticsTimer);

    g_statusCommand = HyprlandAPI::registerHyprCtlCommand(
        g_handle, SHyprCtlCommand{.name = "velora-blur-status", .exact = true, .fn = status});
    if (!g_statusCommand)
        throw std::runtime_error("Velora Shell blur status command could not be registered");

    if (g_pEventManager)
        g_pEventManager->postEvent({"velora-blur", "ready"});
    // Refresh the matching sharp/blurred desktop pair after hot load, including
    // an idle static wallpaper. No recurring terminal animation is scheduled.
    for (const auto& monitor : State::monitorState()->monitors()) {
        monitor->m_blurFBDirty = true;
        monitor->m_blurFBShouldRender = true;
    }
    damageAllMonitors();

    return {
        .name = "velora-blur",
        .description = "Clear live framebuffer refraction for Velora",
        .author = "Velora Shell",
        .version = "0.17.20",
    };
}

APICALL EXPORT void PLUGIN_EXIT() {
    g_unloading = true;
    HyprlandAPI::removeDispatcher(g_handle, "velora-blur:lyrics-beat");
    g_lyricsBeats.clear();
    HyprlandAPI::removeDispatcher(g_handle, "velora-blur:bar-refraction");
    HyprlandAPI::removeDispatcher(g_handle, "velora-blur:terminal-bar-match");
    HyprlandAPI::removeDispatcher(g_handle, "velora-blur:terminal-follow-bar");
    HyprlandAPI::removeDispatcher(g_handle, "velora-blur:terminal-brightness");
    HyprlandAPI::removeDispatcher(g_handle, "velora-blur:bar-brightness");
    HyprlandAPI::removeDispatcher(g_handle, "velora-blur:terminal-glass-control");
    if (g_pEventManager)
        g_pEventManager->postEvent({"velora-blur", "unloaded"});
    if (g_causticsTimer && g_pEventLoopManager)
        g_pEventLoopManager->removeTimer(g_causticsTimer);
    g_causticsTimer.reset();
    if (g_wallpaperTimer && g_pEventLoopManager) g_pEventLoopManager->removeTimer(g_wallpaperTimer);
    g_wallpaperTimer.reset();
    HyprlandAPI::removeDispatcher(g_handle, "velora-blur:wallpaper-transition");
    clearWallpaperTransition();
    if (Render::GL::g_pHyprOpenGL) Render::GL::g_pHyprOpenGL->makeEGLCurrent();
    g_wallpaperShader.reset();
    g_opticalBlurShader.reset();
    g_opticalBlurBuffers.clear();

    HyprlandAPI::removeDispatcher(g_handle, "velora-blur:lock-layout");
    HyprlandAPI::removeDispatcher(g_handle, "velora-blur:appearance");
    HyprlandAPI::removeDispatcher(g_handle, "velora-blur:settings-connected");
    g_bottomSettings.clear();
    HyprlandAPI::removeDispatcher(g_handle, "velora-blur:editor-shape");
    HyprlandAPI::removeDispatcher(g_handle, "velora-blur:selector-shape");
    HyprlandAPI::removeDispatcher(g_handle, "velora-blur:shared-widgets-shape");
    HyprlandAPI::removeDispatcher(g_handle, "velora-blur:settings-shape");
    HyprlandAPI::removeDispatcher(g_handle, "velora-blur:right-menu-shape");
    HyprlandAPI::removeDispatcher(g_handle, "velora-blur:topbar-settle");
    HyprlandAPI::removeDispatcher(g_handle, "velora-blur:topbar-shape");
    HyprlandAPI::removeDispatcher(g_handle, "velora-blur:topbar-connected");
    HyprlandAPI::removeDispatcher(g_handle, "velora-blur:bar-blur");
    HyprlandAPI::removeDispatcher(g_handle, "velora-blur:widget-blur");
    HyprlandAPI::removeDispatcher(g_handle, "velora-blur:wallpaper");
    HyprlandAPI::removeDispatcher(g_handle, "velora-blur:liquid-style");
    HyprlandAPI::removeDispatcher(g_handle, "velora-blur:desktop-bar-material");
    g_desktopBarMaterials.clear();
    HyprlandAPI::removeDispatcher(g_handle, "velora-blur:unified-bar-shape");
    HyprlandAPI::removeDispatcher(g_handle, "velora-blur:dial");
    HyprlandAPI::removeDispatcher(g_handle, "velora-blur:caustics");
    HyprlandAPI::removeDispatcher(g_handle, "velora-blur:transition");
    g_tickListener.reset();
    if (g_statusCommand)
        HyprlandAPI::unregisterHyprCtlCommand(g_handle, g_statusCommand);
    g_statusCommand.reset();
    g_kittyIdentities.clear();
    if ((g_liquidShader || g_desktopShader || g_terminalShader) && Render::GL::g_pHyprOpenGL) {
        Render::GL::g_pHyprOpenGL->makeEGLCurrent();
        g_clearBackdrop.reset();
        g_frameBackdrops.clear();
        g_frameFusionBackdrops.clear();
        g_liquidShader.reset();
        g_desktopShader.reset();
        g_terminalShader.reset();
        g_terminalBarShader.reset();
        g_terminalBackdrops.clear();
    }
}
