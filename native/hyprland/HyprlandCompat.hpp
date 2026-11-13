#pragma once

// Hyprland 0.57 owns render state in the context passed to each draw. Keep
// that exact context through nested blur passes; never substitute a global
// context or reinterpret a hook with the previous calling convention.
#if __has_include(<hyprland/src/render/Context.hpp>)
#include <hyprland/src/render/Context.hpp>
#define VELORA_HAS_RENDER_CONTEXT 1
#define VELORA_HOOK_CONTEXT_ARG Render::CRenderContext& ctx,
#define VELORA_HOOK_CONTEXT_TYPE Render::CRenderContext&,
#define VELORA_HOOK_CONTEXT_PASS ctx,
#define VELORA_LEGACY_CONTEXT
#else
#define VELORA_HAS_RENDER_CONTEXT 0
#define VELORA_HOOK_CONTEXT_ARG
#define VELORA_HOOK_CONTEXT_TYPE
#define VELORA_HOOK_CONTEXT_PASS
#define VELORA_LEGACY_CONTEXT VeloraCompat::RenderContext ctx;
#endif

#if __has_include(<hyprland/src/ipc/s1/S1.hpp>)
#include <hyprland/src/ipc/s1/S1.hpp>
#endif

namespace VeloraCompat {
#if VELORA_HAS_RENDER_CONTEXT
using RenderContext = Render::CRenderContext;
inline auto& renderData(RenderContext& ctx) { return ctx.m_data; }
#else
struct RenderContext {};
inline auto& renderData(RenderContext&) { return g_pHyprRenderer->m_renderData; }
#endif

inline auto projectBox(RenderContext& ctx, const CBox& box) {
#if VELORA_HAS_RENDER_CONTEXT
    return g_pHyprRenderer->projectBoxToTarget(ctx, box);
#else
    return g_pHyprRenderer->projectBoxToTarget(box);
#endif
}

inline void scissor(RenderContext& ctx, const pixman_box32* rect, bool transform = true) {
#if VELORA_HAS_RENDER_CONTEXT
    Render::GL::g_pHyprOpenGL->scissor(ctx, rect, transform);
#else
    Render::GL::g_pHyprOpenGL->scissor(rect, transform);
#endif
}

inline void bindFB(RenderContext& ctx, const SP<Render::IFramebuffer>& fb) {
#if VELORA_HAS_RENDER_CONTEXT
    g_pHyprRenderer->bindFB(ctx, fb);
#else
    g_pHyprRenderer->bindFB(fb);
#endif
}

inline SP<Render::ITexture> blurTexture(RenderContext& ctx,
        const SP<Render::IFramebuffer>& source, const CRegion& damage) {
#if VELORA_HAS_RENDER_CONTEXT
    const auto framebuffer = g_pHyprRenderer->blurFramebuffer(ctx, source, 1.F, damage);
    return framebuffer ? framebuffer->getTexture() : nullptr;
#else
    CRegion mutableDamage{damage};
    return g_pHyprRenderer->blurFramebuffer(source, 1.F, &mutableDamage);
#endif
}

inline bool mapped(const PHLLS& layer) {
#if __has_include(<hyprland/src/desktop/view/window/Window.hpp>)
    return layer->mapped();
#else
    return layer->m_mapped;
#endif
}

template <typename Predicate>
bool kittyAppID(const PHLWINDOW& window, Predicate predicate) {
#if __has_include(<hyprland/src/desktop/view/window/Window.hpp>)
    return predicate(window->metadata().appID()) || predicate(window->metadata().initialAppID());
#else
    return predicate(window->m_class) || predicate(window->m_initialClass);
#endif
}

inline auto windowPID(const PHLWINDOW& window) {
#if __has_include(<hyprland/src/desktop/view/window/Window.hpp>)
    return window->backend().pid();
#else
    return window->getPID();
#endif
}

#if __has_include(<hyprland/src/ipc/s1/S1.hpp>)
using StatusCommand = IPC::Socket1::SCommand;
using OutputFormat = IPC::Socket1::eOutputFormat;
constexpr auto JSON_FORMAT = IPC::Socket1::FORMAT_JSON;
inline StatusCommand statusCommand(std::string (*handler)(OutputFormat, std::string)) {
    return {.name = "velora-blur-status", .match = IPC::Socket1::COMMAND_MATCH_EXACT,
        .handler = [handler](const IPC::Socket1::SRequest& request) -> IPC::Socket1::SResponse {
            return handler(request.format, request.command);
        }};
}
#else
using StatusCommand = SHyprCtlCommand;
using OutputFormat = eHyprCtlOutputFormat;
constexpr auto JSON_FORMAT = FORMAT_JSON;
inline StatusCommand statusCommand(std::string (*handler)(OutputFormat, std::string)) {
    return {.name = "velora-blur-status", .exact = true, .fn = handler};
}
#endif
}
