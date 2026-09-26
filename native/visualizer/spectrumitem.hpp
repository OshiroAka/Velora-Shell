#pragma once

#include <QColor>
#include <QQuickItem>
#include <QtQml/qqmlregistration.h>

class SpectrumAnalyzer;

class SpectrumItem : public QQuickItem {
    Q_OBJECT
    QML_NAMED_ELEMENT(Spectrum)

    Q_PROPERTY(SpectrumAnalyzer* analyzer READ analyzer WRITE setAnalyzer
               NOTIFY analyzerChanged)
    Q_PROPERTY(bool active READ active WRITE setActive NOTIFY activeChanged)
    Q_PROPERTY(qreal referenceHeight READ referenceHeight WRITE setReferenceHeight
               NOTIFY referenceHeightChanged)
    Q_PROPERTY(qreal strength READ strength WRITE setStrength NOTIFY strengthChanged)
    Q_PROPERTY(QColor accentStart READ accentStart WRITE setAccentStart
               NOTIFY accentStartChanged)
    Q_PROPERTY(QColor accentMiddle READ accentMiddle WRITE setAccentMiddle
               NOTIFY accentMiddleChanged)
    Q_PROPERTY(QColor accentEnd READ accentEnd WRITE setAccentEnd
               NOTIFY accentEndChanged)
    Q_PROPERTY(QColor outlineColor READ outlineColor WRITE setOutlineColor
               NOTIFY outlineColorChanged)
    Q_PROPERTY(qreal clipSideInset READ clipSideInset WRITE setClipSideInset
               NOTIFY clipSideInsetChanged)
    Q_PROPERTY(qreal clipCornerRadius READ clipCornerRadius WRITE setClipCornerRadius
               NOTIFY clipCornerRadiusChanged)
    Q_PROPERTY(qreal clipBottomInset READ clipBottomInset WRITE setClipBottomInset
               NOTIFY clipBottomInsetChanged)
    Q_PROPERTY(bool clipSideOnRight READ clipSideOnRight WRITE setClipSideOnRight
               NOTIFY clipSideOnRightChanged)

public:
    explicit SpectrumItem(QQuickItem* parent = nullptr);

    [[nodiscard]] SpectrumAnalyzer* analyzer() const noexcept;
    void setAnalyzer(SpectrumAnalyzer* value);
    [[nodiscard]] bool active() const noexcept;
    void setActive(bool value);
    [[nodiscard]] qreal referenceHeight() const noexcept;
    void setReferenceHeight(qreal value);
    [[nodiscard]] qreal strength() const noexcept;
    void setStrength(qreal value);
    [[nodiscard]] QColor accentStart() const;
    void setAccentStart(const QColor& value);
    [[nodiscard]] QColor accentMiddle() const;
    void setAccentMiddle(const QColor& value);
    [[nodiscard]] QColor accentEnd() const;
    void setAccentEnd(const QColor& value);
    [[nodiscard]] QColor outlineColor() const;
    void setOutlineColor(const QColor& value);
    [[nodiscard]] qreal clipSideInset() const noexcept;
    void setClipSideInset(qreal value);
    [[nodiscard]] qreal clipCornerRadius() const noexcept;
    void setClipCornerRadius(qreal value);
    [[nodiscard]] qreal clipBottomInset() const noexcept;
    void setClipBottomInset(qreal value);
    [[nodiscard]] bool clipSideOnRight() const noexcept;
    void setClipSideOnRight(bool value);

signals:
    void analyzerChanged();
    void activeChanged();
    void referenceHeightChanged();
    void strengthChanged();
    void accentStartChanged();
    void accentMiddleChanged();
    void accentEndChanged();
    void outlineColorChanged();
    void clipSideInsetChanged();
    void clipCornerRadiusChanged();
    void clipBottomInsetChanged();
    void clipSideOnRightChanged();

protected:
    QSGNode* updatePaintNode(QSGNode* oldNode, UpdatePaintNodeData*) override;

private:
    void scheduleUpdate();

    SpectrumAnalyzer* analyzer_ = nullptr;
    bool active_ = true;
    qreal referenceHeight_ = 180.0;
    qreal strength_ = 0.46;
    QColor accentStart_{"#8b9ee8"};
    QColor accentMiddle_{"#72c7e7"};
    QColor accentEnd_{"#e2a4ca"};
    QColor outlineColor_{QColor::fromRgbF(1.F, 1.F, 1.F, 0.54F)};
    qreal clipSideInset_ = 0;
    qreal clipCornerRadius_ = 0;
    qreal clipBottomInset_ = 0;
    bool clipSideOnRight_ = false;
};
