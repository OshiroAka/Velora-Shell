#pragma once

#include <algorithm>
#include <array>
#include <cmath>
#include <span>
#include <fftw3.h>

// Absolute level for the desktop only. The shared 96-band analyzer retains its
// existing normalization for media contours and percussion detection.
class DesktopResponse {
public:
    static constexpr int sampleRate = 16000;
    static constexpr int fftSize = 1024; // 64 ms, rather than a 128 ms Hann window.
    static constexpr int bandCount = 96;

    DesktopResponse() {
        for (int i=0;i<fftSize;++i)
            window_[i]=.5F-.5F*std::cos(2.F*3.14159265358979323846F
                                      *static_cast<float>(i)/static_cast<float>(fftSize-1));
        plan_=fftwf_plan_dft_r2c_1d(fftSize,input_.data(),output_.data(),FFTW_ESTIMATE);
    }
    ~DesktopResponse() { if (plan_) fftwf_destroy_plan(plan_); }
    DesktopResponse(const DesktopResponse&)=delete;
    DesktopResponse& operator=(const DesktopResponse&)=delete;
    void reset() { levels_.fill(0.F); }
    [[nodiscard]] const std::array<float,bandCount>& levels() const { return levels_; }
    void process(std::span<const float> mono, float seconds) {
        process(mono,mono,seconds);
    }
    void process(std::span<const float> left, std::span<const float> right, float seconds) {
        if (!plan_ || left.size()<fftSize || right.size()<fftSize) return;
        std::array<float,fftSize/2+1> magnitude{};
        // Average channel energy, not signed samples. Wide/opposite-phase
        // stereo must not cancel the beat into silence.
        for (auto channel : {left.last(fftSize),right.last(fftSize)}) {
            for (int i=0;i<fftSize;++i) input_[i]=channel[static_cast<std::size_t>(i)]*window_[i];
            fftwf_execute(plan_);
            for (std::size_t i=0;i<magnitude.size();++i)
                magnitude[i]+=(output_[i][0]*output_[i][0]+output_[i][1]*output_[i][1]);
        }
        for (float& value : magnitude) value=std::sqrt(value*.5F)*(4.F/fftSize);
        for (int band=0;band<bandCount;++band) {
            const float frequency=35.F*std::pow(7600.F/35.F,static_cast<float>(band)/(bandCount-1));
            const float bin=frequency*fftSize/sampleRate;
            const int low=std::clamp(static_cast<int>(bin),0,fftSize/2-1);
            const float fraction=bin-static_cast<float>(low);
            float amplitude=magnitude[low]*(1.F-fraction)+magnitude[low+1]*fraction;
            // Sample the logarithmic band's actual range too, so high notes
            // between center bins remain visible without broadening the bass.
            const float ratio=std::pow(7600.F/35.F,.5F/(bandCount-1));
            for (int i=std::max(1,static_cast<int>(std::ceil(bin/ratio)));
                 i<=std::min(fftSize/2,static_cast<int>(std::floor(bin*ratio)));++i)
                amplitude=std::max(amplitude,magnitude[i]);
            const float db=20.F*std::log10(std::max(amplitude,1e-8F));
            const float range=std::clamp((db+52.F)/44.F,0.F,1.F);
            const float target=range*range;
            const float time=target>levels_[band] ? .012F : .105F;
            levels_[band]+=(target-levels_[band])*(1.F-std::exp(-seconds/time));
            if (levels_[band]<.0002F) levels_[band]=0.F;
        }
    }

private:
    std::array<float,fftSize> input_{};
    std::array<float,fftSize> window_{};
    std::array<fftwf_complex,fftSize/2+1> output_{};
    std::array<float,bandCount> levels_{};
    fftwf_plan plan_=nullptr;
};
