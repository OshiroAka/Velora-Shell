#pragma once
#include <cstdint>
#include <set>
#include <sstream>
#include <string>

namespace Velora::InfiniteDesk {
struct WorkspaceModes {
    bool independent = true;
    bool global = false;
    std::set<uint32_t> workspaces;
    bool operator==(const WorkspaceModes&) const = default;
    bool active(uint32_t id) const { return id > 0 && (independent ? workspaces.contains(id) : global); }
    bool any() const { return independent ? !workspaces.empty() : global; }
    void set(uint32_t id, bool value) {
        if (!independent) global = value;
        else if (value) workspaces.insert(id);
        else workspaces.erase(id);
    }
    // Parse transactionally: malformed IPC never changes another workspace.
    bool configure(const std::string& arguments) {
        std::istringstream input(arguments);
        std::string scope, token;
        int shared = -1;
        if (!(input >> scope >> shared) || (scope != "workspace" && scope != "global") || (shared != 0 && shared != 1)) return false;
        WorkspaceModes next{scope == "workspace", bool(shared), {}};
        while (input >> token) {
            if (token.empty() || token.find_first_not_of("0123456789") != std::string::npos) return false;
            try {
                const auto id = std::stoull(token);
                if (!id || id > UINT32_MAX) return false;
                next.workspaces.insert(static_cast<uint32_t>(id));
            } catch (...) { return false; }
        }
        *this = next;
        return true;
    }
};
}
