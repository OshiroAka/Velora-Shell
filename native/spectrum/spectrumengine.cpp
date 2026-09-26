#include "spectrumengine.hpp"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <limits>

#include <fftw3.h>
#include <pulse/simple.h>

namespace {
constexpr int kSampleRate = 16000;
constexpr int kChannels = 2;
constexpr int kFftSize = 2048;
constexpr int kBars = 96;
constexpr int kCaptureRate = 30;
constexpr int kPublishRate = 10;
constexpr float kMinFrequency = 35.0F;
constexpr float kMaxFrequency = 7600.0F;
constexpr float kAttack = 0.72F;
constexpr float kRelease = 0.20F;
constexpr float kNoiseFloor = 0.035F;
constexpr float kAmplify = 1.72F;
}

SpectrumEngine& SpectrumEngine::instance() {
    static SpectrumEngine engine;
    return engine;
}

SpectrumEngine::SpectrumEngine()
    : values_(kBars, 0.0F)
    , worker_([this](std::stop_token token) { run(token); }) {}

SpectrumEngine::~SpectrumEngine() {
    worker_.request_stop();
}

std::vector<float> SpectrumEngine::values() const {
    std::scoped_lock lock(valuesMutex_);
    return values_;
}

bool SpectrumEngine::hasSignal() const noexcept {
    return hasSignal_.load(std::memory_order_relaxed);
}

void SpectrumEngine::publish(std::vector<float> values, bool hasSignal) {
    {
        std::scoped_lock lock(valuesMutex_);
        values_ = std::move(values);
    }

    const bool previousSignal = hasSignal_.exchange(hasSignal, std::memory_order_relaxed);
    emit frameReady();
    if (previousSignal != hasSignal)
        emit signalStateChanged();
}

void SpectrumEngine::run(std::stop_token stopToken) {
    const int chunkFrames = std::max(128, static_cast<int>(std::lround(kSampleRate / static_cast<double>(kCaptureRate))));
    const pa_sample_spec sampleSpec{PA_SAMPLE_FLOAT32LE, kSampleRate, kChannels};
    const pa_buffer_attr bufferAttributes{
        std::numeric_limits<std::uint32_t>::max(),
        std::numeric_limits<std::uint32_t>::max(),
        std::numeric_limits<std::uint32_t>::max(),
        std::numeric_limits<std::uint32_t>::max(),
        static_cast<std::uint32_t>(chunkFrames * kChannels * sizeof(float))
    };
    int pulseError = 0;
    pa_simple* pulse = pa_simple_new(
        nullptr,
        "velora-native-spectrum",
        PA_STREAM_RECORD,
        "@DEFAULT_MONITOR@",
        "Velora native spectrum",
        &sampleSpec,
        nullptr,
        &bufferAttributes,
        &pulseError
    );
    if (!pulse)
        return;

    std::vector<float> history(kFftSize, 0.0F);
    std::vector<float> window(kFftSize);
    std::vector<float> capture(static_cast<std::size_t>(chunkFrames * kChannels));
    std::vector<float> fftInput(kFftSize);
    std::vector<fftwf_complex> fftOutput(kFftSize / 2 + 1);
    std::vector<float> spectrum(kFftSize / 2 + 1);
    std::vector<float> smoothed(kBars, 0.0F);
    std::vector<float> targetBins(kBars);

    constexpr float pi = 3.14159265358979323846F;
    for (int index = 0; index < kFftSize; ++index)
        window[index] = 0.5F - 0.5F * std::cos((2.0F * pi * index) / (kFftSize - 1));
    for (int index = 0; index < kBars; ++index) {
        const float progress = static_cast<float>(index) / (kBars - 1);
        const float frequency = kMinFrequency * std::pow(kMaxFrequency / kMinFrequency, progress);
        targetBins[index] = frequency * kFftSize / kSampleRate;
    }

    fftwf_plan plan = fftwf_plan_dft_r2c_1d(kFftSize, fftInput.data(), fftOutput.data(), FFTW_ESTIMATE);
    if (!plan) {
        pa_simple_free(pulse);
        return;
    }

    int quietFrames = 0;
    int capturedFrames = 0;
    while (!stopToken.stop_requested()) {
        if (pa_simple_read(pulse, capture.data(), capture.size() * sizeof(float), &pulseError) < 0)
            break;

        const int shift = std::min(chunkFrames, kFftSize);
        std::move(history.begin() + shift, history.end(), history.begin());
        const int offset = kFftSize - shift;
        for (int frame = 0; frame < shift; ++frame) {
            const int source = (chunkFrames - shift + frame) * kChannels;
            history[offset + frame] = 0.5F * (capture[source] + capture[source + 1]);
        }
        for (int index = 0; index < kFftSize; ++index)
            fftInput[index] = history[index] * window[index];

        fftwf_execute(plan);
        float peak = 0.0001F;
        for (std::size_t index = 0; index < spectrum.size(); ++index) {
            spectrum[index] = std::log1p(std::hypot(fftOutput[index][0], fftOutput[index][1]));
            peak = std::max(peak, spectrum[index]);
        }

        float visualPeak = 0.0F;
        for (int index = 0; index < kBars; ++index) {
            const float position = std::clamp(targetBins[index], 0.0F, static_cast<float>(spectrum.size() - 1));
            const int lower = static_cast<int>(position);
            const int upper = std::min(lower + 1, static_cast<int>(spectrum.size() - 1));
            const float fraction = position - lower;
            float value = ((1.0F - fraction) * spectrum[lower] + fraction * spectrum[upper]) / peak;
            value = std::clamp((value - kNoiseFloor) * kAmplify, 0.0F, 1.0F);
            const float smoothing = value >= smoothed[index] ? kAttack : kRelease;
            smoothed[index] += (value - smoothed[index]) * smoothing;
            visualPeak = std::max(visualPeak, smoothed[index]);
        }

        const bool hasSignal = visualPeak > 0.002F;
        quietFrames = hasSignal ? 0 : quietFrames + 1;
        ++capturedFrames;
        const bool signalChanged = hasSignal != hasSignal_.load(std::memory_order_relaxed);
        if (!signalChanged && capturedFrames % std::max(1, kCaptureRate / kPublishRate) != 0)
            continue;
        if (quietFrames > kCaptureRate && quietFrames % kCaptureRate != 0)
            continue;
        publish(smoothed, hasSignal);
    }

    fftwf_destroy_plan(plan);
    pa_simple_free(pulse);
}
