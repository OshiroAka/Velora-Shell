import QtQuick
import QtQuick.Effects

Item {
    id: root

    property url source
    property real radius: 22
    property real blurAmount: 0
    property real contentScale: 1
    property real contentOffsetX: 0
    property real contentOffsetY: 0
    property bool mirrored: false
    property bool asynchronous: true
    property int fillMode: Image.PreserveAspectCrop
    property int verticalAlignment: Image.AlignVCenter
    property bool animateContentTransform: true
    // The whole 1600x900 composition may be scaled by the output. Render the
    // masked texture above logical size so rounded photos remain crisp.
    readonly property real renderScale: 2
    readonly property int status: rawImage.status

    Item {
        id: highResolutionSurface
        x: 0
        y: 0
        width: root.width * root.renderScale
        height: root.height * root.renderScale
        scale: 1 / root.renderScale
        transformOrigin: Item.TopLeft

        Item {
            id: imageComposition
            anchors.fill: parent
            visible: false

            Image {
                id: rawImage
                width: parent.width * root.contentScale
                height: parent.height * root.contentScale
                x: (parent.width - width) / 2 + root.contentOffsetX * root.renderScale
                y: (parent.height - height) / 2 + root.contentOffsetY * root.renderScale
                source: root.source
                fillMode: root.fillMode
                verticalAlignment: root.verticalAlignment
                smooth: true
                mipmap: true
                asynchronous: root.asynchronous

                transform: Scale {
                    origin.x: rawImage.width / 2
                    origin.y: rawImage.height / 2
                    xScale: root.mirrored ? -1 : 1

                    Behavior on xScale {
                        enabled: root.animateContentTransform
                        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                    }
                }

                Behavior on x {
                    enabled: root.animateContentTransform
                    NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                }
                Behavior on y {
                    enabled: root.animateContentTransform
                    NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                }
                Behavior on width {
                    enabled: root.animateContentTransform
                    NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                }
                Behavior on height {
                    enabled: root.animateContentTransform
                    NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                }
            }
        }

        Rectangle {
            id: imageMask
            anchors.fill: parent
            radius: root.radius * root.renderScale
            visible: false
            layer.enabled: true
        }

        MultiEffect {
            anchors.fill: parent
            source: imageComposition
            visible: rawImage.status === Image.Ready
            autoPaddingEnabled: false
            maskEnabled: true
            maskSource: imageMask
            maskThresholdMin: 0.45
            maskSpreadAtMin: 1.0
            blurEnabled: root.blurAmount > 0.001
            blur: root.blurAmount
            blurMax: 24 * root.renderScale
        }
    }
}
