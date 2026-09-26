#include "spectrumitem.hpp"

#include "spectrumanalyzer.hpp"

#include <QSGGeometryNode>
#include <QSGVertexColorMaterial>

#include <algorithm>
#include <cmath>

namespace {
constexpr float kInset = 4.F;
constexpr float kBarWidth = 5.F;
constexpr float kSectionWidth = 6.F;

QColor mixColor(const QColor& first, const QColor& second, float amount) {
    const float ratio = std::clamp(amount, 0.F, 1.F);
    return QColor::fromRgbF(
        first.redF() + (second.redF() - first.redF()) * ratio,
        first.greenF() + (second.greenF() - first.greenF()) * ratio,
        first.blueF() + (second.blueF() - first.blueF()) * ratio,
        first.alphaF() + (second.alphaF() - first.alphaF()) * ratio);
}

void writeRectangle(QSGGeometry::ColoredPoint2D*& vertex, float x, float y,
                    float width, float height, const QColor& color) {
    const auto red = static_cast<uchar>(color.red());
    const auto green = static_cast<uchar>(color.green());
    const auto blue = static_cast<uchar>(color.blue());
    const auto alpha = static_cast<uchar>(color.alpha());
    vertex++->set(x, y, red, green, blue, alpha);
    vertex++->set(x + width, y, red, green, blue, alpha);
    vertex++->set(x, y + height, red, green, blue, alpha);
    vertex++->set(x + width, y, red, green, blue, alpha);
    vertex++->set(x + width, y + height, red, green, blue, alpha);
    vertex++->set(x, y + height, red, green, blue, alpha);
}
}

SpectrumItem::SpectrumItem(QQuickItem* parent)
    : QQuickItem(parent) {
    setFlag(ItemHasContents, true);
}

SpectrumAnalyzer* SpectrumItem::analyzer() const noexcept {
    return analyzer_;
}

void SpectrumItem::setAnalyzer(SpectrumAnalyzer* value) {
    if (analyzer_ == value)
        return;
    if (analyzer_)
        disconnect(analyzer_, nullptr, this, nullptr);
    analyzer_ = value;
    if (analyzer_) {
        connect(analyzer_, &SpectrumAnalyzer::bandsChanged,
                this, &SpectrumItem::scheduleUpdate, Qt::QueuedConnection);
        connect(analyzer_, &SpectrumAnalyzer::runningChanged,
                this, &SpectrumItem::scheduleUpdate, Qt::QueuedConnection);
    }
    emit analyzerChanged();
    update();
}

bool SpectrumItem::active() const noexcept { return active_; }

void SpectrumItem::setActive(bool value) {
    if (active_ == value)
        return;
    active_ = value;
    emit activeChanged();
    update();
}

qreal SpectrumItem::referenceHeight() const noexcept { return referenceHeight_; }

void SpectrumItem::setReferenceHeight(qreal value) {
    if (qFuzzyCompare(referenceHeight_, value))
        return;
    referenceHeight_ = value;
    emit referenceHeightChanged();
    update();
}

qreal SpectrumItem::strength() const noexcept { return strength_; }

void SpectrumItem::setStrength(qreal value) {
    if (qFuzzyCompare(strength_, value))
        return;
    strength_ = value;
    emit strengthChanged();
    update();
}

QColor SpectrumItem::accentStart() const { return accentStart_; }
void SpectrumItem::setAccentStart(const QColor& value) {
    if (accentStart_ == value)
        return;
    accentStart_ = value;
    emit accentStartChanged();
    update();
}

QColor SpectrumItem::accentMiddle() const { return accentMiddle_; }
void SpectrumItem::setAccentMiddle(const QColor& value) {
    if (accentMiddle_ == value)
        return;
    accentMiddle_ = value;
    emit accentMiddleChanged();
    update();
}

QColor SpectrumItem::accentEnd() const { return accentEnd_; }
void SpectrumItem::setAccentEnd(const QColor& value) {
    if (accentEnd_ == value)
        return;
    accentEnd_ = value;
    emit accentEndChanged();
    update();
}

QColor SpectrumItem::outlineColor() const { return outlineColor_; }
void SpectrumItem::setOutlineColor(const QColor& value) {
    if (outlineColor_ == value)
        return;
    outlineColor_ = value;
    emit outlineColorChanged();
    update();
}

qreal SpectrumItem::clipSideInset() const noexcept { return clipSideInset_; }
void SpectrumItem::setClipSideInset(qreal value) {
    value = std::max<qreal>(0, value);
    if (qFuzzyCompare(clipSideInset_, value))
        return;
    clipSideInset_ = value;
    emit clipSideInsetChanged();
    update();
}

qreal SpectrumItem::clipCornerRadius() const noexcept { return clipCornerRadius_; }
void SpectrumItem::setClipCornerRadius(qreal value) {
    value = std::max<qreal>(0, value);
    if (qFuzzyCompare(clipCornerRadius_, value))
        return;
    clipCornerRadius_ = value;
    emit clipCornerRadiusChanged();
    update();
}

qreal SpectrumItem::clipBottomInset() const noexcept { return clipBottomInset_; }
void SpectrumItem::setClipBottomInset(qreal value) {
    value = std::max<qreal>(0, value);
    if (qFuzzyCompare(clipBottomInset_, value))
        return;
    clipBottomInset_ = value;
    emit clipBottomInsetChanged();
    update();
}

bool SpectrumItem::clipSideOnRight() const noexcept { return clipSideOnRight_; }
void SpectrumItem::setClipSideOnRight(bool value) {
    if (clipSideOnRight_ == value)
        return;
    clipSideOnRight_ = value;
    emit clipSideOnRightChanged();
    update();
}

void SpectrumItem::scheduleUpdate() {
    if (active_ && isVisible() && width() > 0 && height() > 0)
        update();
}

QSGNode* SpectrumItem::updatePaintNode(QSGNode* oldNode,
                                       UpdatePaintNodeData*) {
    auto* node = static_cast<QSGGeometryNode*>(oldNode);
    if (!node) {
        node = new QSGGeometryNode();
        auto* geometry = new QSGGeometry(
            QSGGeometry::defaultAttributes_ColoredPoint2D(), 0);
        geometry->setDrawingMode(QSGGeometry::DrawTriangles);
        geometry->setVertexDataPattern(QSGGeometry::DynamicPattern);
        node->setGeometry(geometry);
        node->setFlag(QSGNode::OwnsGeometry);
        auto* material = new QSGVertexColorMaterial();
        material->setFlag(QSGMaterial::Blending, true);
        node->setMaterial(material);
        node->setFlag(QSGNode::OwnsMaterial);
    }

    auto* geometry = node->geometry();
    if (!active_ || !analyzer_ || !analyzer_->running()
        || width() <= 0 || height() <= 0) {
        geometry->allocate(0);
        node->markDirty(QSGNode::DirtyGeometry);
        return node;
    }

    const auto values = analyzer_->values();
    const int barCount = std::max(0, static_cast<int>(std::floor(
        (width() - kInset * 2.F) / kSectionWidth)));
    geometry->allocate(barCount * 12);
    auto* vertex = geometry->vertexDataAsColoredPoint2D();
    const float baseY = std::max(0.F, static_cast<float>(height())
        - static_cast<float>(clipBottomInset_));
    const float sideInset = std::max(0.F, static_cast<float>(clipSideInset_));
    const float cornerRadius = std::max(0.F, std::min({
        static_cast<float>(clipCornerRadius_),
        static_cast<float>(width()) - sideInset, baseY}));
    const float maximumHeight = std::max(1.F, std::min(
        baseY, static_cast<float>(referenceHeight_)));
    const float gain = 0.82F
        + static_cast<float>(std::clamp(strength_, 0.0, 1.0)) * 0.38F;
    const QColor outline = outlineColor_;

    for (int index = 0; index < barCount; ++index) {
        const float unit = (static_cast<float>(index) + 0.5F)
            / static_cast<float>(std::max(1, barCount));
        // The old SplitParser exposed the trailing semicolon as one final zero
        // sample. Preserve that endpoint taper without serializing any text.
        const float scaled = unit * static_cast<float>(values.size());
        const int lower = std::clamp(static_cast<int>(std::floor(scaled)), 0,
            static_cast<int>(values.size()));
        const int upper = std::clamp(lower + 1, 0,
            static_cast<int>(values.size()));
        const float fraction = scaled - static_cast<float>(lower);
        const auto sample = [&values](int sampleIndex) {
            return sampleIndex >= 0
                    && sampleIndex < static_cast<int>(values.size())
                ? values[static_cast<std::size_t>(sampleIndex)] : 0.F;
        };
        const float level = sample(lower) * (1.F - fraction)
            + sample(upper) * fraction;
        const float outerHeight = std::round(std::max(
            0.F, level * maximumHeight * gain));
        const float innerHeight = std::max(0.F, outerHeight - 1.F);
        const float x = kInset + static_cast<float>(index) * kSectionWidth;
        const float fromSide = clipSideOnRight_
            ? static_cast<float>(width()) - x - kBarWidth : x;
        const QColor color = unit < 0.44F
            ? mixColor(accentStart_, accentMiddle_, unit / 0.44F)
            : mixColor(accentMiddle_, accentEnd_, (unit - 0.44F) / 0.56F);

        if (fromSide < sideInset || baseY <= 0.F) {
            writeRectangle(vertex, 0.F, 0.F, 0.F, 0.F, outline);
            writeRectangle(vertex, 0.F, 0.F, 0.F, 0.F, color);
            continue;
        }

        float barBaseY = baseY;
        if (cornerRadius > 0.F && fromSide < sideInset + cornerRadius) {
            const float dx = fromSide - sideInset - cornerRadius;
            barBaseY = baseY - cornerRadius + std::sqrt(
                std::max(0.F, cornerRadius * cornerRadius - dx * dx));
        }
        const float clippedOuterHeight = std::min(outerHeight, barBaseY);
        const float clippedInnerHeight = std::min(innerHeight, barBaseY);

        writeRectangle(vertex, x, barBaseY - clippedOuterHeight,
                       kBarWidth, clippedOuterHeight, outline);
        writeRectangle(vertex, x + 1.F,
                       barBaseY - clippedInnerHeight,
                       kBarWidth - 2.F, clippedInnerHeight, color);
    }

    node->markDirty(QSGNode::DirtyGeometry);
    return node;
}
