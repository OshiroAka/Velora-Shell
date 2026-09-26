#include <hyprland/src/config/ConfigValue.hpp>
#include <hyprland/src/config/values/types/FloatValue.hpp>
#include <hyprland/src/config/values/types/IntValue.hpp>
#include <hyprland/src/desktop/view/LayerSurface.hpp>
#include <hyprland/src/event/EventBus.hpp>
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
#include <sstream>
#include <stdexcept>
#include <string>

namespace {
constexpr auto DESKTOP_NAMESPACE = "velora-shell-lock-preview-desktop";
constexpr auto PANEL_NAMESPACE   = "velora-shell-lock-preview-panel";
constexpr auto TOPBAR_NAMESPACE  = "velora-shell-topbar";
constexpr auto UNIFIED_BAR_NAMESPACE = "velora-shell-unified-bar";
constexpr auto RIGHT_MENU_NAMESPACE = "velora-shell-right-menu";
constexpr auto SETTINGS_NAMESPACE = "velora-shell-settings";
constexpr auto EDITOR_NAMESPACE = "velora-shell-editor";
constexpr auto SHARED_WIDGETS_NAMESPACE = "velora-shell-shared-widgets";
constexpr size_t SHARED_WIDGET_COUNT = 6;

HANDLE         g_handle  = nullptr;
CFunctionHook* g_drawTex = nullptr;
CFunctionHook* g_drawGLTex = nullptr;
CHyprSignalListener g_tickListener;
SP<CEventLoopTimer> g_causticsTimer;
SP<Render::GL::CGLFramebuffer> g_clearBackdrop;
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
    float x = 0.F;
    float y = 0.F;
    float width = 1.F;
    float height = 1.F;
    float radius = 0.F;
};

constexpr size_t TOPBAR_SHAPE_COUNT = 3;
constexpr size_t EDITOR_SHAPE_COUNT = 6;
std::array<STopbarMorph, TOPBAR_SHAPE_COUNT> g_topbarShapes;
STopbarMorph g_unifiedBarShape;
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

layout(location = 0) out vec4 fragColor;

float roundedBoxSdf(vec2 point, vec2 halfSize, float cornerRadius) {
    vec2 q = abs(point) - halfSize + vec2(cornerRadius);
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - cornerRadius;
}

float smoothUnion(float first, float second, float softness) {
    float blend = clamp(0.5 + 0.5 * (second - first) / softness, 0.0, 1.0);
    return mix(second, first, blend) - softness * blend * (1.0 - blend);
}

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

float compositionSdf(vec2 point) {
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

void main() {
    vec2 panelUv = clamp(v_texcoord, 0.0, 1.0);
    vec2 panelSpan = windowBottomRight - windowTopLeft;
    vec2 panelPixels = max(panelSpan * fullSize, vec2(1.0));
    vec2 local = (panelUv - 0.5) * panelPixels;
    float mainDistance = thick > 1.5 ? rightMenuSdf(local)
        : mainShapeSdf(local);
    float dialDistance = thick > 0.5 && thick < 1.5
        ? roundedBoxSdf(local - uvOffset, uvSize, radiusOuter) : 1e6;
    float joinSoftness = min(48.0, max(10.0, radiusOuter * 0.38));
    float sdf = thick > 0.5 && thick < 1.5
        ? smoothUnion(mainDistance, dialDistance, joinSoftness)
        : mainDistance;
    float coverage = 1.0 - smoothstep(-1.25, 1.25, sdf);
    if (coverage <= 0.001)
        discard;

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
    vec2 normal = sdfGradient / max(length(sdfGradient), 0.0001);
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
    magnificationStrength = mix(magnificationStrength, 0.0009, barLens);
    vec2 magnification = -shapeLocal * magnificationStrength / fullSize;
    vec2 displacement = -normal * distort * lens / fullSize;
    // The unified bar inherits the lockscreen lens, but without visible pool
    // waves. Two very slow, non-repeating bends move only the refracted
    // wallpaper and keep the QML icons perfectly still.
    vec2 flowPoint = local / max(0.55, pointer_position.w);
    vec2 flow = vec2(
        sin(flowPoint.y * 0.020 + time * 0.42)
            + 0.48 * sin(flowPoint.x * 0.009 - time * 0.27),
        cos(flowPoint.x * 0.014 - time * 0.34)
            + 0.42 * cos(flowPoint.y * 0.011 + time * 0.23));
    vec2 animatedBend = flow * distort * (0.20 + lens * 0.24)
        * mix(0.60, 1.0, barLens) / fullSize;
    float panelScale = max(0.55, pointer_position.w);
    vec2 designPoint = (local - topLeft) / panelScale + vec2(800.0, 408.0);
    vec3 caustics = pointer_position.z > 0.5
        ? poolCaustics(designPoint, pointer_position.x,
                       pointer_position.y) : vec3(0.0);
    vec2 refractedUv = clamp(baseUv + magnification + displacement
        + animatedBend
        + caustics.xy * panelScale / fullSize,
        vec2(0.001), vec2(0.999));

    // The backdrop is copied with a straight framebuffer blit, so its texture
    // uses the same UV orientation as the window bounds above. Do not flip Y.
    // Clear glass keeps fine wallpaper details without a diffusion kernel.
    vec3 glass = texture(tex, refractedUv).rgb;

    // Subtle wavelength separation is visible only at the curved rim.
    vec2 spectral = normal * noise * lens / fullSize;
    glass.r = texture(tex, clamp(refractedUv + spectral, 0.001, 0.999)).r;
    glass.b = texture(tex, clamp(refractedUv - spectral, 0.001, 0.999)).b;

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
    if (!shader->createProgram(LIQUID_GLASS_VERTEX, LIQUID_GLASS_FRAGMENT, true, true)) {
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
    if (!element || !element->m_data.blurredBG || !ensureDesktopShader() ||
        !g_pHyprRenderer || !Render::GL::g_pHyprOpenGL)
        return false;

    const CBox surfaceBox = element->m_data.box;
    if (surfaceBox.width <= 0 || surfaceBox.height <= 0)
        return false;

    CRegion desktopDamage{surfaceBox};
    const CBox panelBox = liquidPanelBox(surfaceBox);
    const double designScale = std::min(surfaceBox.width / 1600.0,
                                        surfaceBox.height / 900.0);
    // Classic keeps the original two-surface panel and therefore needs a raw
    // opening behind it. Editorial has no central panel: subtracting this box
    // leaves a visibly sharp "hole" in an otherwise frosted full backdrop.
    if (!g_editorialLock)
        desktopDamage.subtract(roundedPanelRegion(panelBox, 54.0 * designScale));
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
        std::max(1.F, sc<float>(element->m_data.blurredBG->m_size.x)),
        std::max(1.F, sc<float>(element->m_data.blurredBG->m_size.y)));
    shader->setUniformFloat(SHADER_ALPHA,
                            std::clamp(g_transition.current, 0.F, 1.F));
    shader->setUniformFloat(SHADER_DISTORT,
                            sc<float>(g_desktopSize->value()));
    shader->setUniformFloat(SHADER_BRIGHTNESS,
                            g_desktopBrightness->value());
    shader->setUniformFloat(SHADER_VIBRANCY,
                            g_desktopVibrancy->value());

    glActiveTexture(GL_TEXTURE0);
    element->m_data.blurredBG->bind();
    element->m_data.blurredBG->setTexParameter(GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    element->m_data.blurredBG->setTexParameter(GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    Render::GL::g_pHyprOpenGL->blend(true);
    glBindVertexArray(shader->getUniformLocation(SHADER_SHADER_VAO));
    desktopDamage.forEachRect([](const auto& rect) {
        Render::GL::g_pHyprOpenGL->scissor(
            &rect, g_pHyprRenderer->m_renderData.transformDamage);
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    });
    glBindVertexArray(0);
    element->m_data.blurredBG->unbind();
    Render::GL::g_pHyprOpenGL->scissor(nullptr);
    return true;
}

bool captureClearBackdrop() {
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
    if (!g_clearBackdrop)
        g_clearBackdrop = makeShared<Render::GL::CGLFramebuffer>("velora-clear-glass");
    const int width = sc<int>(source->m_size.x);
    const int height = sc<int>(source->m_size.y);
    const bool allocated = g_clearBackdrop->alloc(width, height, source->m_drmFormat);
    if (allocated) {
        glDisable(GL_SCISSOR_TEST);
        glBindFramebuffer(GL_READ_FRAMEBUFFER, drawFB);
        glBindFramebuffer(GL_DRAW_FRAMEBUFFER, g_clearBackdrop->getFBID());
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

bool renderLiquidBackdrop(WP<CTexPassElement> element, const CRegion& damage,
                          const bool topbar = false,
                          const bool rightMenu = false,
                          const bool settings = false,
                          const STopbarMorph* independentShape = nullptr,
                          const bool editor = false) {
    if (!element || !g_clearBackdrop || !g_clearBackdrop->getTexture() || !ensureLiquidShader() ||
        !g_pHyprRenderer || !Render::GL::g_pHyprOpenGL)
        return false;

    const CBox surfaceBox = element->m_data.box;
    if ((topbar && (!independentShape || !independentShape->active)) ||
        (editor && (!independentShape || !independentShape->active)) ||
        (rightMenu && !g_rightMenuMorph.active) ||
        (settings && !g_settingsMorph.active))
        return false;

    const CBox panelBox = rightMenu ? liquidRightMenuBox(surfaceBox)
        : (settings ? liquidSettingsBox(surfaceBox)
                    : ((topbar || editor)
                        ? liquidTopbarBox(surfaceBox, *independentShape)
                              : liquidPanelBox(surfaceBox)));
    if (panelBox.width <= 0 || panelBox.height <= 0 || surfaceBox.width <= 0 || surfaceBox.height <= 0)
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

    CRegion liquidDamage{panelBox};
    if (hasDial)
        liquidDamage.add(dialBox);
    if (rightMenu)
        liquidDamage.add(railBox);
    if (!damage.empty())
        liquidDamage.intersect(damage);
    if (liquidDamage.empty())
        return true;

    const auto& matrix = g_pHyprRenderer->projectBoxToTarget(drawBox);
    auto shader = Render::GL::g_pHyprOpenGL->useShader(g_liquidShader);
    if (!shader)
        return false;

    const float panelScale = (topbar || rightMenu)
        ? sc<float>(surfaceBox.width / 1600.0)
        : sc<float>(std::min(surfaceBox.width / 1600.0, surfaceBox.height / 900.0));
    const float transitionAlpha = (topbar || rightMenu || settings || editor)
        ? 1.F : std::clamp((g_transition.current - 0.10F) / 0.90F, 0.F, 1.F);
    const float textureWidth = std::max(1.F, sc<float>(g_clearBackdrop->getTexture()->m_size.x));
    const float textureHeight = std::max(1.F, sc<float>(g_clearBackdrop->getTexture()->m_size.y));
    const float drawCenterX = sc<float>(drawBox.x + drawBox.width * 0.5);
    const float drawCenterY = sc<float>(drawBox.y + drawBox.height * 0.5);

    shader->setUniformMatrix3fv(SHADER_PROJ, 1, GL_TRUE, matrix.getMatrix());
    shader->setUniformInt(SHADER_TEX, 0);
    shader->setUniformFloat2(SHADER_FULL_SIZE, textureWidth, textureHeight);
    shader->setUniformFloat2(SHADER_WINDOW_TOP_LEFT,
                             sc<float>(drawBox.x / textureWidth),
                             sc<float>(drawBox.y / textureHeight));
    shader->setUniformFloat2(SHADER_WINDOW_BOTTOM_RIGHT,
                             sc<float>((drawBox.x + drawBox.width) / textureWidth),
                             sc<float>((drawBox.y + drawBox.height) / textureHeight));
    if (rightMenu) {
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
                            hasDial ? sc<float>(std::min(dialBox.width * 0.5,
                                                        dialBox.height * 0.5)) : 0.F);
    shader->setUniformFloat(SHADER_THICK, rightMenu ? 2.F : (hasDial ? 1.F : 0.F));
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
    if (rightMenu) {
        localRefraction *= 0.42F;
        localEdgeWidth *= 0.31F;
        localDispersion *= 0.55F;
    } else if (topbar || (editor && panelBox.height < 110.F * panelScale)) {
        const float topbarHalfThickness = std::max(
            1.F, sc<float>(std::min(panelBox.width, panelBox.height) * 0.5));
        localRefraction = std::min(
            localRefraction, topbarHalfThickness * 0.62F);
        localEdgeWidth = std::min(
            localEdgeWidth, std::max(8.F, topbarHalfThickness * 0.88F));
        localDispersion = std::min(
            localDispersion, std::max(0.45F, topbarHalfThickness * 0.07F));
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
                             renderCaustics && g_caustics.lines ? 1.F : 0.F,
                             0.F, 0.F, topbar ? 1.F : 0.F);
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
    g_clearBackdrop->getTexture()->bind();
    g_clearBackdrop->getTexture()->setTexParameter(GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    g_clearBackdrop->getTexture()->setTexParameter(GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    Render::GL::g_pHyprOpenGL->blend(true);
    glBindVertexArray(shader->getUniformLocation(SHADER_SHADER_VAO));

    liquidDamage.forEachRect([](const auto& rect) {
        Render::GL::g_pHyprOpenGL->scissor(&rect, g_pHyprRenderer->m_renderData.transformDamage);
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    });

    glBindVertexArray(0);
    g_clearBackdrop->getTexture()->unbind();
    Render::GL::g_pHyprOpenGL->scissor(nullptr);
    if (rightMenu)
        ++g_rightMenuRefractionDraws;
    else if (settings)
        ++g_settingsRefractionDraws;
    else if (editor)
        ++g_editorRefractionDraws;
    else if (topbar)
        ++g_topbarRefractionDraws;
    else
        ++g_refractionDraws;
    return true;
}

bool renderSharedWidgetsBackdrop(WP<CTexPassElement> element,
                                 const CRegion& damage) {
    if (!element || !g_clearBackdrop || !g_clearBackdrop->getTexture() || !ensureLiquidShader() ||
        !g_pHyprRenderer || !Render::GL::g_pHyprOpenGL ||
        !g_sharedWidgetShapesActive)
        return false;

    const CBox surfaceBox = element->m_data.box;
    if (surfaceBox.width <= 0 || surfaceBox.height <= 0)
        return false;

    auto shader = Render::GL::g_pHyprOpenGL->useShader(g_liquidShader);
    if (!shader)
        return false;

    const float textureWidth = std::max(
        1.F, sc<float>(g_clearBackdrop->getTexture()->m_size.x));
    const float textureHeight = std::max(
        1.F, sc<float>(g_clearBackdrop->getTexture()->m_size.y));
    const float panelScale = sc<float>(std::min(
        surfaceBox.width / 1600.0, surfaceBox.height / 900.0));

    shader->setUniformInt(SHADER_TEX, 0);
    shader->setUniformFloat2(SHADER_FULL_SIZE, textureWidth, textureHeight);
    shader->setUniformFloat(SHADER_RADIUS_OUTER, 0.F);
    shader->setUniformFloat(SHADER_THICK, 0.F);
    shader->setUniformFloat(SHADER_BRIGHTNESS, 1.025F);
    shader->setUniformFloat(SHADER_VIBRANCY, 1.12F);
    shader->setUniformFloat(SHADER_TIME,
                            g_pHyprRenderer->m_globalTimer.getSeconds());
    shader->setUniformFloat4(SHADER_COLOR, 0.87F, 0.93F, 1.0F,
                             g_panelTint->value());

    const bool renderCaustics = g_sharedWidgetCaustics && g_caustics.enabled;
    shader->setUniformFloat4(SHADER_POINTER,
                             g_caustics.phase,
                             renderCaustics ? g_caustics.intensity : 0.F,
                             renderCaustics ? 1.F : 0.F,
                             panelScale);

    glActiveTexture(GL_TEXTURE0);
    g_clearBackdrop->getTexture()->bind();
    g_clearBackdrop->getTexture()->setTexParameter(GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    g_clearBackdrop->getTexture()->setTexParameter(GL_TEXTURE_MIN_FILTER, GL_LINEAR);
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
            g_panelRefraction->value() * panelScale * 0.68F
                * reflectionFactor,
            std::max(2.5F, halfThickness * 0.26F));
        const float localEdgeWidth = std::min(
            g_panelEdgeWidth->value() * panelScale * 0.46F
                * std::sqrt(reflectionFactor),
            std::max(8.F, halfThickness * 0.44F));
        const float localDispersion = std::min(
            g_panelDispersion->value() * panelScale * 0.36F
                * std::sqrt(reflectionFactor),
            std::max(0.35F, halfThickness * 0.026F));
        shader->setUniformFloat(SHADER_DISTORT, localRefraction);
        shader->setUniformFloat(SHADER_CONTRAST, localEdgeWidth);
        shader->setUniformFloat(SHADER_NOISE, localDispersion);
        shader->setUniformFloat4(SHADER_POINTER_SHAPE,
                                 renderCaustics && g_caustics.lines ? 1.F : 0.F,
                                 radians, 1.F, 0.F);

        liquidDamage.forEachRect([](const auto& rect) {
            Render::GL::g_pHyprOpenGL->scissor(
                &rect, g_pHyprRenderer->m_renderData.transformDamage);
            glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        });
        drewShape = true;
    }

    glBindVertexArray(0);
    g_clearBackdrop->getTexture()->unbind();
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
                       const STopbarMorph& current) {
    if (!State::monitorState() || !g_pHyprRenderer)
        return;
    for (const auto& monitor : State::monitorState()->monitors()) {
        if (!monitor)
            continue;
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

SDispatchResult unifiedBarShapeDispatcher(std::string arguments) {
    std::istringstream input{arguments};
    int active = 0;
    if (!(input >> active))
        return {.success = false, .error = "expected active [x y width height radius]"};

    const STopbarMorph previous = g_unifiedBarShape;
    if (active == 0) {
        g_unifiedBarShape = {};
        damageTopbarMorph(previous, g_unifiedBarShape);
        return {};
    }

    float x = 0.F;
    float y = 0.F;
    float width = 0.F;
    float height = 0.F;
    float radius = 0.F;
    if (!(input >> x >> y >> width >> height >> radius))
        return {.success = false, .error = "expected active x y width height radius"};

    g_unifiedBarShape.active = true;
    g_unifiedBarShape.x = std::clamp(x, -0.1F, 1.1F);
    g_unifiedBarShape.y = std::clamp(y, -0.1F, 1.F);
    g_unifiedBarShape.width = std::clamp(width, 0.001F, 1.2F);
    g_unifiedBarShape.height = std::clamp(height, 0.001F, 1.2F);
    g_unifiedBarShape.radius = std::clamp(radius, 0.F, 0.5F);
    damageTopbarMorph(previous, g_unifiedBarShape);
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
    if (g_unifiedBarShape.active)
        damageTopbarMorph({}, g_unifiedBarShape);
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

void hkDrawTex(Render::IElementRenderer* renderer, WP<CTexPassElement> element, const CRegion& damage) {
    const auto original = reinterpret_cast<DrawTexFn>(g_drawTex->m_original);
    const auto layer = element ? element->m_data.currentLS.lock() : nullptr;
    if (g_unloading || !layer || !layer->m_namespace.starts_with("velora-shell-")) {
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

void hkGLDrawTex(Render::GL::CGLElementRenderer* renderer, WP<CTexPassElement> element, const CRegion& damage) {
    const auto original = reinterpret_cast<DrawGLTexFn>(g_drawGLTex->m_original);
    if (g_unloading || !element) {
        original(renderer, element, damage);
        return;
    }

    const auto layer = element->m_data.currentLS.lock();
    const bool panel = layer && layer->m_namespace == PANEL_NAMESPACE;
    const bool topbar = layer && layer->m_namespace == TOPBAR_NAMESPACE;
    const bool unifiedBar = layer
        && layer->m_namespace == UNIFIED_BAR_NAMESPACE;
    const bool rightMenu = layer && layer->m_namespace == RIGHT_MENU_NAMESPACE;
    const bool settings = layer && layer->m_namespace == SETTINGS_NAMESPACE;
    const bool editor = layer && layer->m_namespace == EDITOR_NAMESPACE;
    const bool sharedWidgets = layer
        && layer->m_namespace == SHARED_WIDGETS_NAMESPACE;
    const bool opticalSurface = panel || topbar || unifiedBar || rightMenu
        || settings || editor || sharedWidgets;
    if (!opticalSurface || !captureClearBackdrop()) {
        original(renderer, element, damage);
        return;
    }
    bool rendered = false;
    if (sharedWidgets)
        rendered = renderSharedWidgetsBackdrop(element, damage);
    else if (topbar) {
        for (const auto& shape : g_topbarShapes) {
            if (shape.active)
                rendered = renderLiquidBackdrop(element, damage, true, false,
                                                 false, &shape) || rendered;
        }
    } else if (unifiedBar && g_unifiedBarShape.active) {
        rendered = renderLiquidBackdrop(element, damage, true, false,
                                        false, &g_unifiedBarShape);
    } else if (editor) {
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

    // The native shader has already rendered the live refracted backdrop.
    // Draw only the transparent QML surface and its foreground content now;
    // letting Hyprland blend its regular blur again would flatten the lens.
    const bool oldBlur = element->m_data.blur;
    element->m_data.blur = false;
    original(renderer, element, damage);
    element->m_data.blur = oldBlur;
}

std::string status(eHyprCtlOutputFormat format, std::string) {
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
            R"({{"active":true,"backdrop":"sharp-framebuffer","hyprlandBlur":false,"appearance":{{"blur":{:.3f},"contrast":{:.3f},"reflection":{:.3f},"preview":{}}},"desktop":{{"size":{},"passes":{},"draws":{},"noise":{:.3f},"contrast":{:.3f},"brightness":{:.3f},"vibrancy":{:.3f},"vibrancyDarkness":{:.3f}}},"panel":{{"size":{},"passes":{},"draws":{},"refractionDraws":{},"noise":{:.3f},"contrast":{:.3f},"brightness":{:.3f},"vibrancy":{:.3f},"vibrancyDarkness":{:.3f},"refraction":{:.3f},"edgeWidth":{:.3f},"dispersion":{:.3f},"tint":{:.3f}}},"topbar":{{"size":{},"passes":{},"shapes":{},"draws":{},"refractionDraws":{},"noise":{:.3f},"contrast":{:.3f},"brightness":{:.3f},"vibrancy":{:.3f},"vibrancyDarkness":{:.3f}}},"rightMenu":{{"draws":{},"refractionDraws":{}}},"settings":{{"draws":{},"refractionDraws":{}}},"editor":{{"shapes":{},"draws":{},"refractionDraws":{}}},"sharedWidgets":{{"active":{},"shapes":{},"draws":{},"refractionDraws":{},"caustics":{}}},"transition":{{"progress":{:.3f},"animating":{}}},"caustics":{{"enabled":{},"intensity":{:.3f},"lines":{},"animating":{},"frames":{}}}}})",
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
            editorShapeCount, g_editorDraws, g_editorRefractionDraws,
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

    if (!HyprlandAPI::addDispatcherV2(g_handle, "velora-blur:transition", transitionDispatcher))
        throw std::runtime_error("Velora Shell blur transition dispatcher could not be registered");
    if (!HyprlandAPI::addDispatcherV2(g_handle, "velora-blur:dial", dialDispatcher))
        throw std::runtime_error("Velora Shell dial morph dispatcher could not be registered");
    if (!HyprlandAPI::addDispatcherV2(g_handle, "velora-blur:caustics", causticsDispatcher))
        throw std::runtime_error("Velora Shell caustics dispatcher could not be registered");
    if (!HyprlandAPI::addDispatcherV2(g_handle, "velora-blur:topbar-shape", topbarShapeDispatcher))
        throw std::runtime_error("Velora Shell topbar shape dispatcher could not be registered");
    if (!HyprlandAPI::addDispatcherV2(g_handle, "velora-blur:unified-bar-shape", unifiedBarShapeDispatcher))
        throw std::runtime_error("Velora Shell unified bar shape dispatcher could not be registered");
    if (!HyprlandAPI::addDispatcherV2(g_handle, "velora-blur:topbar-settle", topbarSettleDispatcher))
        throw std::runtime_error("Velora Shell topbar settle dispatcher could not be registered");
    if (!HyprlandAPI::addDispatcherV2(g_handle, "velora-blur:right-menu-shape", rightMenuShapeDispatcher))
        throw std::runtime_error("Velora Shell right menu shape dispatcher could not be registered");
    if (!HyprlandAPI::addDispatcherV2(g_handle, "velora-blur:settings-shape", settingsShapeDispatcher))
        throw std::runtime_error("Velora Shell settings shape dispatcher could not be registered");
    if (!HyprlandAPI::addDispatcherV2(g_handle, "velora-blur:editor-shape", editorShapeDispatcher))
        throw std::runtime_error("Velora Shell editor shape dispatcher could not be registered");
    if (!HyprlandAPI::addDispatcherV2(g_handle, "velora-blur:appearance", appearanceDispatcher))
        throw std::runtime_error("Velora Shell appearance dispatcher could not be registered");
    if (!HyprlandAPI::addDispatcherV2(g_handle, "velora-blur:lock-layout", lockLayoutDispatcher))
        throw std::runtime_error("Velora Shell lock layout dispatcher could not be registered");
    if (!HyprlandAPI::addDispatcherV2(g_handle, "velora-blur:shared-widgets-shape", sharedWidgetsShapeDispatcher))
        throw std::runtime_error("Velora Shell shared widget shape dispatcher could not be registered");

    g_tickListener = Event::bus()->m_events.tick.listen(onTick);
    g_causticsTimer = makeShared<CEventLoopTimer>(
        std::nullopt, onCausticsTimer, nullptr);
    g_pEventLoopManager->addTimer(g_causticsTimer);

    g_statusCommand = HyprlandAPI::registerHyprCtlCommand(
        g_handle, SHyprCtlCommand{.name = "velora-blur-status", .exact = true, .fn = status});
    if (!g_statusCommand)
        throw std::runtime_error("Velora Shell blur status command could not be registered");

    return {
        .name = "velora-blur",
        .description = "Clear live framebuffer refraction for Velora",
        .author = "Velora Shell",
        .version = "0.15.0",
    };
}

APICALL EXPORT void PLUGIN_EXIT() {
    g_unloading = true;
    if (g_causticsTimer && g_pEventLoopManager)
        g_pEventLoopManager->removeTimer(g_causticsTimer);
    g_causticsTimer.reset();
    HyprlandAPI::removeDispatcher(g_handle, "velora-blur:lock-layout");
    HyprlandAPI::removeDispatcher(g_handle, "velora-blur:appearance");
    HyprlandAPI::removeDispatcher(g_handle, "velora-blur:editor-shape");
    HyprlandAPI::removeDispatcher(g_handle, "velora-blur:shared-widgets-shape");
    HyprlandAPI::removeDispatcher(g_handle, "velora-blur:settings-shape");
    HyprlandAPI::removeDispatcher(g_handle, "velora-blur:right-menu-shape");
    HyprlandAPI::removeDispatcher(g_handle, "velora-blur:topbar-settle");
    HyprlandAPI::removeDispatcher(g_handle, "velora-blur:topbar-shape");
    HyprlandAPI::removeDispatcher(g_handle, "velora-blur:unified-bar-shape");
    HyprlandAPI::removeDispatcher(g_handle, "velora-blur:dial");
    HyprlandAPI::removeDispatcher(g_handle, "velora-blur:caustics");
    HyprlandAPI::removeDispatcher(g_handle, "velora-blur:transition");
    g_tickListener.reset();
    if (g_statusCommand)
        HyprlandAPI::unregisterHyprCtlCommand(g_handle, g_statusCommand);
    g_statusCommand.reset();
    if ((g_liquidShader || g_desktopShader) && Render::GL::g_pHyprOpenGL) {
        Render::GL::g_pHyprOpenGL->makeEGLCurrent();
        g_clearBackdrop.reset();
        g_liquidShader.reset();
        g_desktopShader.reset();
    }
}
