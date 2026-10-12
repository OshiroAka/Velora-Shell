#pragma once

#include <QColor>
#include <QQuickItem>
#include <QtQml/qqmlregistration.h>

class SpectrumItem : public QQuickItem {
    Q_OBJECT
    QML_NAMED_ELEMENT(VeloraNativeSpectrum)

    Q_PROPERTY(bool active READ active WRITE setActive NOTIFY activeChanged)
    Q_PROPERTY(bool growUpward READ growUpward WRITE setGrowUpward NOTIFY growUpwardChanged)
    Q_PROPERTY(bool growFromCenter READ growFromCenter WRITE setGrowFromCenter NOTIFY growFromCenterChanged)
    Q_PROPERTY(qreal minimumLevel READ minimumLevel WRITE setMinimumLevel NOTIFY minimumLevelChanged)
    Q_PROPERTY(qreal referenceHeight READ referenceHeight WRITE setReferenceHeight NOTIFY referenceHeightChanged)
    Q_PROPERTY(qreal strength READ strength WRITE setStrength NOTIFY strengthChanged)
    Q_PROPERTY(QColor accentStart READ accentStart WRITE setAccentStart NOTIFY accentStartChanged)
    Q_PROPERTY(QColor accentMiddle READ accentMiddle WRITE setAccentMiddle NOTIFY accentMiddleChanged)
    Q_PROPERTY(QColor accentEnd READ accentEnd WRITE setAccentEnd NOTIFY accentEndChanged)
    Q_PROPERTY(bool hasSignal READ hasSignal NOTIFY hasSignalChanged)

public:
    explicit SpectrumItem(QQuickItem* parent = nullptr);

    [[nodiscard]] bool active() const noexcept { return active_; }
    void setActive(bool value);
    [[nodiscard]] bool growUpward() const noexcept { return growUpward_; }
    void setGrowUpward(bool value);
    [[nodiscard]] bool growFromCenter() const noexcept { return growFromCenter_; }
    void setGrowFromCenter(bool value);
    [[nodiscard]] qreal minimumLevel() const noexcept { return minimumLevel_; }
    void setMinimumLevel(qreal value);
    [[nodiscard]] qreal referenceHeight() const noexcept { return referenceHeight_; }
    void setReferenceHeight(qreal value);
    [[nodiscard]] qreal strength() const noexcept { return strength_; }
    void setStrength(qreal value);
    [[nodiscard]] QColor accentStart() const { return accentStart_; }
    void setAccentStart(const QColor& value);
    [[nodiscard]] QColor accentMiddle() const { return accentMiddle_; }
    void setAccentMiddle(const QColor& value);
    [[nodiscard]] QColor accentEnd() const { return accentEnd_; }
    void setAccentEnd(const QColor& value);
    [[nodiscard]] bool hasSignal() const noexcept;

signals:
    void activeChanged();
    void growUpwardChanged();
    void growFromCenterChanged();
    void minimumLevelChanged();
    void referenceHeightChanged();
    void strengthChanged();
    void accentStartChanged();
    void accentMiddleChanged();
    void accentEndChanged();
    void hasSignalChanged();

protected:
    QSGNode* updatePaintNode(QSGNode* oldNode, UpdatePaintNodeData*) override;

private:
    void scheduleUpdate();

    bool active_ = true;
    bool growUpward_ = false;
    bool growFromCenter_ = false;
    qreal minimumLevel_ = 0.0;
    qreal referenceHeight_ = 46.0;
    qreal strength_ = 1.0;
    QColor accentStart_{"#8b9ee8"};
    QColor accentMiddle_{"#72c7e7"};
    QColor accentEnd_{"#e2a4ca"};
};
