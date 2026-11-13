#pragma once
#include <array>
#include <cmath>
#include <optional>
#include <sstream>
#include <string>
#include <string_view>

constexpr int LYRICS_BEAT_SLOTS = 8;
constexpr float LYRICS_BEAT_SECONDS = 1.6F;
struct SLyricsBeatCommand {
    std::string monitor;
    bool reset = false;
    float x = 0.F, y = 0.F, strength = 0.F;
    std::array<float, 6> colors{.25F, .50F, .93F, .84F, .32F, .58F};
};
inline std::optional<SLyricsBeatCommand> parseLyricsBeat(std::string_view text) {
    std::istringstream input{std::string{text}};
    SLyricsBeatCommand value;
    std::string token, trailing;
    if (!(input >> value.monitor >> token)) return std::nullopt;
    if (token == "reset") value.reset = true;
    else {
        std::istringstream number{token};
        if (!(number >> value.x) || (number >> trailing) || !(input >> value.y >> value.strength))
            return std::nullopt;
        for (float coordinate : {value.x, value.y, value.strength})
            if (!std::isfinite(coordinate) || coordinate < 0.F || coordinate > 1.F)
                return std::nullopt;
        input >> std::ws;
        if (!input.eof()) {
            for (auto& channel : value.colors)
                if (!(input >> channel) || !std::isfinite(channel) || channel < 0.F || channel > 1.F)
                    return std::nullopt;
        }
    }
    if (input >> trailing) return std::nullopt;
    return value;
}
