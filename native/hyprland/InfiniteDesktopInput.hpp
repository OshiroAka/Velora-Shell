#pragma once
#include <hyprland/src/managers/SeatManager.hpp>
#include <hyprland/src/managers/input/InputManager.hpp>
#include <hyprland/src/protocols/LayerShell.hpp>

// The camera owns the fast path when supported. Older plugins keep the socket
// event fallback used by Quickshell; no second consumer receives the same delta.
inline bool (*infiniteDesktopNativeScroll)(PHLMONITOR, double, double) = nullptr;

inline bool infiniteDesktopGestureFocused(const PHLMONITOR& monitor) {
    if (!monitor || !g_pSeatManager) return false;
    const auto focus = g_pSeatManager->m_state.pointerFocus.lock();
    if (!focus) return false;
    for (const auto& ref : monitor->m_layerSurfaceLayers[1]) {
        const auto layer = ref.lock();
        if (!layer || (layer->m_namespace != "velora-infinite-desktop-gesture"
            && layer->m_namespace != "velora-shell-shared-widgets")) continue;
        const auto resource = layer->m_layerSurface.lock();
        if (resource && resource->m_surface.lock() == focus) return true;
    }
    return false;
}

// Route only Super + finger scrolling on the canvas, before wheel keybinds.
// Physical wheels, application surfaces and other modifiers keep their actions.
inline void infiniteDesktopAxis(const IPointer::SAxisEvent& event, Event::SCallbackInfo& info) {
    if (info.cancelled || event.source != WL_POINTER_AXIS_SOURCE_FINGER || !g_pInputManager || !g_pSeatManager
        || (static_cast<uint32_t>(g_pInputManager->getModsFromAllKBs()) & (64U | 1U | 4U | 8U)) != 64U) return;
    const auto focus = g_pSeatManager->m_state.pointerFocus.lock();
    if (!focus) return;
    for (const auto& monitor : State::monitorState()->monitors()) {
        if (!monitor) continue;
        for (const auto& ref : monitor->m_layerSurfaceLayers[1]) {
            const auto layer = ref.lock();
            if (!layer || (layer->m_namespace != "velora-infinite-desktop-gesture"
                && layer->m_namespace != "velora-shell-shared-widgets")) continue;
            const auto resource = layer->m_layerSurface.lock();
            if (!resource || resource->m_surface.lock() != focus) continue;
            if (!std::isfinite(event.delta)) return;
            const double dx = event.axis == WL_POINTER_AXIS_HORIZONTAL_SCROLL ? -event.delta : 0.;
            const double dy = event.axis == WL_POINTER_AXIS_VERTICAL_SCROLL ? -event.delta : 0.;
            if (infiniteDesktopNativeScroll && infiniteDesktopNativeScroll(monitor, dx, dy)) {
                info.cancelled = true;
                return;
            }
            const auto payload = std::format("{},{},{}", monitor->m_name,
                event.axis == WL_POINTER_AXIS_HORIZONTAL_SCROLL ? -event.delta : 0.0,
                event.axis == WL_POINTER_AXIS_VERTICAL_SCROLL ? -event.delta : 0.0);
#if __has_include(<hyprland/src/ipc/s2/S2.hpp>)
            if (!IPC::Socket2::sock()) return;
            IPC::Socket2::sock()->postEvent({"velora-infinite-scroll", payload});
#else
            if (!g_pEventManager) return;
            g_pEventManager->postEvent({"velora-infinite-scroll", payload});
#endif
            info.cancelled = true;
            return;
        }
    }
}
