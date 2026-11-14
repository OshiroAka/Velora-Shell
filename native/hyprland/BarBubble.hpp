#pragma once
#include <array>
#include <charconv>
#include <cstdint>
#include <cmath>
#include <optional>
#include <sstream>
#include <string>

constexpr size_t BAR_BUBBLE_LIMIT = 32;
inline std::optional<std::uint64_t> parseBarBubbleEpoch(const std::string& token) {
    std::uint64_t value = 0;
    const auto result = std::from_chars(token.data(), token.data()+token.size(), value);
    if (result.ec != std::errc{} || result.ptr != token.data()+token.size()) return std::nullopt;
    return value;
}
struct SBarBubble {
    std::string monitor, layer, token;
    bool active = false;
    std::uint64_t epoch = 0;
    // Local normalized rect, clipping rect, radius, effective opacity, theme tint.
    std::array<float, 14> values{};
};

inline std::optional<SBarBubble> parseBarBubble(const std::string& arguments) {
    std::istringstream input{arguments};
    SBarBubble result;
    int active;
    if (!(input >> result.monitor >> result.layer >> result.token >> active)
            || (active != 0 && active != 1)
            || (result.layer != "topbar" && result.layer != "sidebar")
            || result.monitor.size() > 128 || result.token.size() > 96) return std::nullopt;
    const auto separator = result.token.find('_');
    if (separator != std::string::npos) {
        const auto epoch = parseBarBubbleEpoch(result.token.substr(0,separator));
        if (!epoch) return std::nullopt;
        result.epoch = *epoch;
    }
    result.active = active == 1;
    if (result.active) {
        for (auto& value : result.values)
            if (!(input >> value) || !std::isfinite(value)) return std::nullopt;
        const auto& v = result.values;
        if (v[0] < -4 || v[1] < -4 || v[0] > 4 || v[1] > 4
                || v[2] <= 0 || v[3] <= 0 || v[2] > 4 || v[3] > 4
                || v[4] < 0 || v[5] < 0 || v[6] <= 0 || v[7] <= 0
                || v[4]+v[6] > 1.00001F || v[5]+v[7] > 1.00001F
                || v[8] < 0 || v[8] > 1) return std::nullopt;
        for (size_t i = 9; i < 14; ++i) if (v[i] < 0 || v[i] > 1) return std::nullopt;
    }
    input >> std::ws;
    if (!input.eof()) return std::nullopt;
    return result;
}
