#include "desktopresponse.hpp"
#include <array>
#include <cassert>
#include <iostream>

int main() {
    constexpr int hop=267;
    std::array<float,2048> history{};
    DesktopResponse response;
    int sample=0;
    auto tick=[&](float amplitude,float frequency) {
        std::move(history.begin()+hop,history.end(),history.begin());
        for (int i=2048-hop;i<2048;++i,++sample)
            history[i]=amplitude*std::sin(2.F*3.14159265358979323846F*frequency*static_cast<float>(sample)/16000.F);
        response.process(history,static_cast<float>(hop)/16000.F);
        return *std::max_element(response.levels().begin(),response.levels().end());
    };
    auto steady=[&](float amplitude,float frequency) {
        response.reset();history.fill(0);
        float peak=0;
        for(int i=0;i<90;++i) peak=tick(amplitude,frequency);
        return peak;
    };
    float quiet=steady(.0005F,80);
    float soft=steady(.006F,80);
    float medium=steady(.05F,80);
    float loud=steady(.5F,80);
    assert(quiet==0 && soft<.08F && medium>soft*3 && loud>medium*2 && loud>.8F);
    assert(steady(.1F,1000)>.3F);
    assert(steady(.1F,6000)>.3F);
    auto inverted=history;
    for(float& value:inverted)value=-value;
    const auto reference=response.levels();
    response.process(history,inverted,1.F/60.F);
    const float stereo=*std::max_element(response.levels().begin(),response.levels().end());
    assert(stereo>.3F && stereo>=*std::max_element(reference.begin(),reference.end())*.95F);
    steady(.006F,80);
    float first=tick(.5F,80), second=tick(.5F,80), third=tick(.5F,80);
    assert(first>soft && second>first && third>second && third>.7F);
    int decay=0;float value=third;
    while(value>.002F && decay<90) { value=tick(0,80);++decay; }
    assert(decay<50);
    for(int i=0;i<60;++i) tick(0,80);
    for(float level:response.levels()) assert(level==0);
    response.reset();for(float level:response.levels())assert(level==0);
    std::cout<<"DESKTOP_RESPONSE_OK quiet="<<quiet<<" soft="<<soft<<" medium="<<medium<<" loud="<<loud
             <<" onset="<<first<<","<<second<<","<<third<<" decay_ms="<<decay*267*1000/16000<<"\n";
}
