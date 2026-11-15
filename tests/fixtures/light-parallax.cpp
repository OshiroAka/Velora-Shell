#include "LightParallax.hpp"
#include <cassert>
#include <sstream>
#include <iostream>
#include <string>
using Hyprutils::Math::Vector2D;
struct SDispatchResult { bool success = true; std::string error; };
struct SAppearanceOptics { float blur=.55F, contrast=1.08F, reflection=.35F; bool preview=false, motionEnabled=true; };
static SAppearanceOptics g_activeAppearance, g_committedAppearance;
static int damageCalls=0;
void damageAllMonitors() { ++damageCalls; }
void aimLightParallax(const Vector2D&) {}
namespace Pointer {
struct Manager { Vector2D untransformedPosition() { return {}; } };
Manager* mgr() { static Manager instance;return &instance; }
}
#include "parallax-appearance.inc"
int main() {
    for(int rate : {60,120,144}) {
        Velora::LightParallax light;
        assert(!light.moving() && !light.advance(1./rate));
        assert(light.aim({1.,-.5}));
        auto previous=light.current;
        for(int frame=0;frame<rate;++frame) {
            light.advance(1./rate);
            assert(light.current.x>=previous.x && light.current.x<=.12);
            assert(light.current.y<=previous.y && light.current.y>=-.06);
            previous=light.current;
        }
        assert(!light.moving() && (light.current-Vector2D(.12,-.06)).size()<1e-9);
        assert(!light.advance(1./rate) && !light.aim({1.,-.5}));
        assert(!light.aim({NAN,0.}) && !light.aim({0.,INFINITY}));
        assert(light.aim({-100.,100.}));
        assert(light.target==Vector2D(-.12,.12));
        assert(!light.advance(NAN) && !light.advance(-1.));
        for(int frame=0;frame<rate;++frame) light.advance(1./rate);
        assert(!light.moving() && light.current==light.target);
        light={};assert(light.current==Vector2D{} && !light.moving());
    }
    assert(appearanceDispatcher("commit .55 1.08 .35 0").success);
    assert(!g_activeAppearance.motionEnabled && !g_committedAppearance.motionEnabled);
    assert(appearanceDispatcher("preview .2 1.1 .5").success);
    assert(!g_activeAppearance.motionEnabled && g_activeAppearance.preview);
    assert(appearanceDispatcher("reset").success);
    assert(!g_activeAppearance.preview && !g_activeAppearance.motionEnabled);
    assert(appearanceDispatcher("commit .55 1.08 .35 1").success);
    assert(g_activeAppearance.motionEnabled);
    const auto count=damageCalls;
    for(const auto bad : {"commit .55 1.08 .35 2","commit .55 1.08 .35 bad","commit .55 1.08 .35 0 extra"})
        assert(!appearanceDispatcher(bad).success);
    assert(damageCalls==count && g_activeAppearance.motionEnabled);
    std::cout << "LIGHT_PARALLAX_OK\n";
}
