#pragma once

#include <QObject>

#include <atomic>
#include <mutex>
#include <thread>
#include <vector>

class SpectrumEngine final : public QObject {
    Q_OBJECT

public:
    static SpectrumEngine& instance();

    [[nodiscard]] std::vector<float> values() const;
    [[nodiscard]] bool hasSignal() const noexcept;

signals:
    void frameReady();
    void signalStateChanged();

private:
    SpectrumEngine();
    ~SpectrumEngine() override;
    Q_DISABLE_COPY_MOVE(SpectrumEngine)

    void run(std::stop_token stopToken);
    void publish(std::vector<float> values, bool hasSignal);

    mutable std::mutex valuesMutex_;
    std::vector<float> values_;
    std::atomic_bool hasSignal_{false};
    std::jthread worker_;
};
