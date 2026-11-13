#include "spectrumitem.hpp"

#include "spectrumengine.hpp"

#include <QSGGeometryNode>
#include <QSGVertexColorMaterial>

#include <algorithm>
#include <cmath>

namespace {
constexpr float kInset = 4.0F;
constexpr float kBarWidth = 5.0F;
constexpr float kSectionWidth = 6.0F;

QColor mixColor(const QColor& first, const QColor& second, float amount) {
    const float mix = std::clamp(amount, 0.0F, 1.0F);
    return QColor::fromRgbF(
        first.redF() + (second.redF() - first.redF()) * mix,
        first.greenF() + (second.greenF() - first.greenF()) * mix,
        first.blueF() + (second.blueF() - first.blueF()) * mix,
        first.alphaF() + (second.alphaF() - first.alphaF()) * mix
    );
}

void writeRectangle(QSGGeometry::ColoredPoint2D*& vertex, float x, float y, float width, float height, const QColor& color) {
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
    auto& engine = SpectrumEngine::instance();
    connect(&engine, &SpectrumEngine::frameReady, this, &SpectrumItem::scheduleUpdate, Qt::QueuedConnection);
    connect(&engine, &SpectrumEngine::signalStateChanged, this, &SpectrumItem::hasSignalChanged, Qt::QueuedConnection);
}

void SpectrumItem::scheduleUpdate() {
    if (active_ && isVisible() && width() > 0 && height() > 0)
        update();
}

bool SpectrumItem::hasSignal() const noexcept {
    return SpectrumEngine::instance().hasSignal();
}

#define VELORA_SETTER(Name, Signal, Field, Type) \
    void SpectrumItem::set##Name(Type value) { \
        if (Field == value) return; \
        Field = value; \
        emit Signal(); \
        update(); \
    }

VELORA_SETTER(Active, activeChanged, active_, bool)
VELORA_SETTER(GrowUpward, growUpwardChanged, growUpward_, bool)
VELORA_SETTER(GrowFromCenter, growFromCenterChanged, growFromCenter_, bool)
VELORA_SETTER(MinimumLevel, minimumLevelChanged, minimumLevel_, qreal)
VELORA_SETTER(ReferenceHeight, referenceHeightChanged, referenceHeight_, qreal)
VELORA_SETTER(Strength, strengthChanged, strength_, qreal)

#undef VELORA_SETTER

void SpectrumItem::setAccentStart(const QColor& value) {
    if (accentStart_ == value) return;
    accentStart_ = value;
    emit accentStartChanged();
    update();
}

void SpectrumItem::setAccentMiddle(const QColor& value) {
    if (accentMiddle_ == value) return;
    accentMiddle_ = value;
    emit accentMiddleChanged();
    update();
}

void SpectrumItem::setAccentEnd(const QColor& value) {
    if (accentEnd_ == value) return;
    accentEnd_ = value;
    emit accentEndChanged();
    update();
}

QSGNode* SpectrumItem::updatePaintNode(QSGNode* oldNode, UpdatePaintNodeData*) {
    auto* node = static_cast<QSGGeometryNode*>(oldNode);
    if (!node) {
        node = new QSGGeometryNode();
        auto* geometry = new QSGGeometry(QSGGeometry::defaultAttributes_ColoredPoint2D(), 0);
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
    if (!active_ || width() <= 0 || height() <= 0) {
        geometry->allocate(0);
        node->markDirty(QSGNode::DirtyGeometry);
        return node;
    }

    const auto values = SpectrumEngine::instance().values();
    const int barCount = std::max(0, static_cast<int>(std::floor((width() - kInset * 2.0) / kSectionWidth)));
    geometry->allocate(barCount * 12);
    auto* vertex = geometry->vertexDataAsColoredPoint2D();
    const float maximumHeight = std::max(1.0F, std::min(static_cast<float>(height()), static_cast<float>(referenceHeight_)));
    const float gain = static_cast<float>(0.95 + std::clamp(strength_, 0.0, 1.0) * 1.55);
    const QColor outline = QColor::fromRgbF(1.0, 1.0, 1.0, 0.54);

    for (int index = 0; index < barCount; ++index) {
        const float unit = (index + 0.5F) / std::max(1, barCount);
        const float scaled = unit * std::max(0, static_cast<int>(values.size()) - 1);
        const int lower = std::clamp(static_cast<int>(std::floor(scaled)), 0, std::max(0, static_cast<int>(values.size()) - 1));
        const int upper = std::clamp(lower + 1, 0, std::max(0, static_cast<int>(values.size()) - 1));
        const float fraction = scaled - lower;
        const float sampled = values.empty() ? 0.0F : values[lower] * (1.0F - fraction) + values[upper] * fraction;
        const float level = std::max(static_cast<float>(minimumLevel_), sampled);
        const float outerHeight = std::round(std::clamp(level * maximumHeight * gain, 0.0F, maximumHeight));
        const float innerHeight = std::max(0.0F, outerHeight - 1.0F);
        const float outerY = growFromCenter_ ? std::round((height() - outerHeight) * 0.5) : (growUpward_ ? height() - outerHeight : 0.0);
        const float innerY = growFromCenter_ ? std::round((height() - innerHeight) * 0.5) : (growUpward_ ? height() - innerHeight : 0.0);
        const float x = kInset + index * kSectionWidth;
        const QColor color = unit < 0.44F
            ? mixColor(accentStart_, accentMiddle_, unit / 0.44F)
            : mixColor(accentMiddle_, accentEnd_, (unit - 0.44F) / 0.56F);

        writeRectangle(vertex, x, outerY, kBarWidth, outerHeight, outline);
        writeRectangle(vertex, x + 1.0F, innerY, kBarWidth - 2.0F, innerHeight, color);
    }

    node->markDirty(QSGNode::DirtyGeometry);
    return node;
}
