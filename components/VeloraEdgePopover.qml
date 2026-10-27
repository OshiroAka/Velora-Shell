pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import "../services" as Services
import "EdgeMediaContours.js" as Contours

VeloraRailPopover {
    id: root
    required property var media
    property var whatsapp: null
    property var analyzer: null
    property bool beatEnabled: true
    property bool visualizerDockEnabled: true
    system: media
    rightSide: true
    property string page: "apps"
    property string pendingPage: "apps"
    property int pageMorphDuration: motion.geometryDuration
    property int pageFadeDuration: motion.contentDuration
    property bool pageLeavingWhatsapp: false
    readonly property bool audioPage: page === "media" || page === "lyrics"
    readonly property bool mediaPanelActive: mounted && (audioPage || pendingPage === "media" || pendingPage === "lyrics")
    readonly property bool fullHeightPanelActive: mounted
        && (page !== "apps" || pendingPage !== "apps" || bodyHeight > 164.5)
    readonly property bool whatsappPage: page === "whatsapp"
    readonly property bool keepOpenOutside: whatsappPage || pendingPage === "whatsapp"
    readonly property real contactsWidth: Math.min(84, Math.max(0, width - railWidth - 448 - 16))
    readonly property real contactsHeight: Math.min(448, Math.max(0, height - 92))
    readonly property bool embeddedContacts: contactsWidth < 72
    property real contactsReveal: 0
    property real contactsContentReveal: 0
    property bool contactsExpanded: true
    property real contactsFold: 1
    property bool contactsDragging: false
    readonly property real contactsExtent: contactsReveal * contactsFold
    readonly property bool contactsAnimating: contactsIn.running || contactsOut.running || contactsFoldMotion.running || contactsDragging
    VeloraWhatsAppPreview { id: whatsappPreview }
    readonly property var whatsappState: whatsapp || whatsappPreview
    readonly property bool whatsappContactsVisible: whatsappPage
        && (!whatsapp || whatsapp.hasSession)
    property bool spotifyHovered: false
    readonly property bool lyricsAvailable: !!media && media.spotifyPlaying
    property real labelReveal: 0
    property real labelContent: 0
    property real contour: audioPage ? (page === "lyrics" ? 2 : 1) : 0
    // Hold the last contour through exit; stopping FFT must not snap the edge.
    property var contourSamples: Contours.samples(0)
    Connections {
        target: waves
        function onSamplesChanged() { if (root.opened) root.contourSamples = waves.samples }
    }
    readonly property bool beatActive: beatEnabled && opened && visible && !reducedMotion
        && page === "lyrics" && pendingPage === "lyrics" && !!media && media.spotifyPlaying
    readonly property bool spectrumActive: waves.spectrumActive || beatActive
    signal percussionBeat(real strength, var colors)
    Services.AlbumPaletteService {
        id: beatPalette
        active: root.beatActive
        source: root.media ? String(root.media.artUrl || "") : ""
    }
    Services.LyricsBeatService {
        analyzer: root.analyzer
        active: root.beatActive
        onBeat: strength => { if (beatPalette.ready) root.percussionBeat(strength, beatPalette.colors) }
    }
    property real dockProgress: 0
    function syncDock() {
        const next = visualizerDockEnabled && opened && mediaPanelActive ? 1 : 0
        if (!visualizerDockEnabled || reducedMotion) {
            dockMotion.stop()
            dockProgress = next
        } else if (!(dockMotion.running && dockMotion.to === next)
                && Math.abs(dockProgress - next) > .000001) {
            dockMotion.stop()
            dockMotion.to = next
            dockMotion.start()
        }
    }
    onVisualizerDockEnabledChanged: syncDock()
    onMediaPanelActiveChanged: syncDock()
    NumberAnimation { id: dockMotion; target: root; property: "dockProgress"; duration: 2200; easing.type: Easing.InOutCubic }
    readonly property real sidebarWaveScale: dockProgress * .55
    readonly property real sidebarWaveWidth: Math.min(400, Math.max(0, width - railWidth - 16)) * .55
    property var sidebarSamples: Contours.samples(1)
    onContourSamplesChanged: if (mediaPanelActive && page !== "apps") sidebarSamples = contourSamples.slice()
    function sidebarOffset(t) {
        const reach = Math.max(.001, dockProgress * 1.12)
        const rise = Math.max(0, Math.min(1, ((t - (1 - reach)) / .12)))
        return Contours.offset(sidebarSamples, t) * sidebarWaveWidth * dockProgress * rise * rise * (3 - 2 * rise)
    }
    function keepOpenForControl(type) {
        return keepOpenOutside || (mediaPanelActive && (type === "volume" || type === "brightness"))
    }
    function beginContactsDrag() { contactsFoldMotion.stop(); contactsDragging = true }
    function settleContacts(expanded) {
        contactsDragging = false
        contactsExpanded = expanded
        contactsFoldMotion.stop()
        if (reducedMotion || !opened || !mounted || !whatsappPage) contactsFold = expanded ? 1 : 0
        else {
            contactsFoldMotion.to = expanded ? 1 : 0
            contactsFoldMotion.restart()
        }
    }
    NumberAnimation {
        id: contactsFoldMotion
        target: root; property: "contactsFold"
        duration: root.motion.geometryDuration
        easing.type: root.motion.easeHandoff
    }
    VeloraEdgeWaves {
        id: waves
        objectName: "edgeWaves"
        analyzer: root.analyzer
        active: root.opened && root.visible && root.audioPage && root.page === root.pendingPage
        reducedMotion: root.reducedMotion
        playing: !!root.media && root.media.spotifyPlaying
        page: root.page; contour: root.contour
        synced: mediaLibrary.synced; lines: mediaLibrary.lines; activeLine: mediaLibrary.activeLine
        position: root.media ? root.media.sampledPosition : 0
        duration: root.media ? root.media.length : 0
    }
    function contourOffset(progress) { return Contours.offset(contourSamples, progress) * bodyWidth }
    property alias labelMask: labelArea
    property alias contactsDragMask: contactsHandle
    readonly property color ink: theme ? theme.textPrimary : "white"
    readonly property string family: theme ? theme.bodyFont : "sans-serif"
    preferredWidth: page === "apps" ? 56 : whatsappPage ? 448 : 400
    preferredHeight: page === "apps" ? 164 : height
    verticalMargin: page === "apps" ? 24 : 0
    fullHeightSurface: page !== "apps"
    contentExitDuration: page === "apps" ? motion.contentExit : (reducedMotion ? 0 : whatsappPage ? 420 : 180)
    surfaceExitDuration: page === "apps" ? motion.closeDuration : (reducedMotion ? 0 : 760)
    contentPadding: 0
    contentSlideX: whatsappPage ? 34 : 0
    contentSlideY: whatsappPage ? 0 : -6
    contentMinimumHeight: page === "media" ? 640 : whatsappPage ? 560 : preferredHeight
    closeOnLeave: page === "apps" && pendingPage === "apps"
    extraHovered: labelHover.hovered || lyricsButton.activeFocus
    extension: whatsappPage
        ? ({y: bodyY, width: embeddedContacts || !whatsappContactsVisible ? 0
            : contactsWidth * contactsReveal * reveal * Math.min(1,contactsFold * contactsHeight / Math.max(1,contactsWidth)),
            height: contactsHeight * contactsExtent})
        : ({y: bodyY + 12, width: 104 * labelReveal * reveal, height: 44})
    Behavior on preferredWidth { NumberAnimation { duration: root.reducedMotion ? 0 : root.pageMorphDuration; easing.type: Easing.InOutCubic } }
    Behavior on preferredHeight { NumberAnimation { duration: root.reducedMotion ? 0 : root.pageMorphDuration; easing.type: Easing.InOutCubic } }
    Behavior on contour { NumberAnimation { duration: root.reducedMotion ? 0 : root.pageMorphDuration; easing.type: Easing.InOutCubic } }
    Services.MediaLibraryService {
        id: mediaLibrary
        media: root.media
        active: root.opened && root.audioPage
        page: root.page === "lyrics" ? "lyrics" : "queue"
    }
    function showPage(next) {
        if (next === "lyrics" && !lyricsAvailable) return
        if (next === "media" || next === "lyrics") media.selectSpotify()
        holdContentEntrance()
        pageMotion.stop()
        contactsFoldMotion.stop(); contactsDragging = false
        contactsFold = contactsExpanded ? 1 : 0
        pageLeavingWhatsapp = whatsappPage
        pageMorphDuration = next === "media" ? 1800 : next === "whatsapp" ? 1100 : motion.geometryDuration
        pageFadeDuration = next === "media" || next === "whatsapp" ? 600 : motion.contentDuration
        pendingPage = next
        hideLabel()
        contactsIn.stop(); contactsOut.stop()
        if (reducedMotion) { page = next; contentReveal = 1; updateContacts() }
        else pageMotion.restart()
    }
    function updateContacts() {
        if (!opened || !whatsappContactsVisible) {
            contactsIn.stop()
            if (reducedMotion || !mounted) { contactsOut.stop(); contactsReveal = 0; contactsContentReveal = 0 }
            else if (!contactsOut.running && (contactsReveal > 0 || contactsContentReveal > 0)) contactsOut.restart()
            return
        }
        if (pageMotion.running || contentReveal < .999 || reveal < .999) return
        contactsOut.stop()
        if (reducedMotion) { contactsReveal = 1; contactsContentReveal = 1 }
        else if (!contactsIn.running && (contactsReveal < 1 || contactsContentReveal < 1)) contactsIn.restart()
    }
    function updateLabel() {
        if (opened && page === "apps" && pendingPage === "apps" && lyricsAvailable
                && (spotifyHovered || extraHovered)) {
            labelLeave.stop(); labelOut.stop()
            if (reducedMotion) { labelReveal = 1; labelContent = 1 }
            else if (labelReveal < 1 && !labelIn.running) labelIn.restart()
        } else labelLeave.restart()
    }
    function hideLabel() {
        labelLeave.stop(); labelIn.stop()
        if (reducedMotion) { labelReveal = 0; labelContent = 0 }
        else labelOut.restart()
    }
    onPageChanged: { mediaLibrary.page = page === "lyrics" ? "lyrics" : "queue"; updateContacts() }
    onContentRevealChanged: updateContacts()
    onWhatsappContactsVisibleChanged: updateContacts()
    onSpotifyHoveredChanged: updateLabel()
    onExtraHoveredChanged: updateLabel()
    onLyricsAvailableChanged: { if (!lyricsAvailable) hideLabel(); else updateLabel() }
    onOpenedChanged: {
        syncDock()
        if (!opened) { pageMotion.stop(); hideLabel() }
        else contourSamples = waves.samples
        updateContacts()
    }
    onMountedChanged: if (!mounted) {
        pageMotion.stop(); contactsIn.stop(); contactsOut.stop(); labelIn.stop(); labelOut.stop(); labelLeave.stop()
        pageMorphDuration = motion.geometryDuration; pageFadeDuration = motion.contentDuration
        page = "apps"; pendingPage = "apps"; spotifyHovered = false
        labelReveal = 0; labelContent = 0
        contactsReveal = 0; contactsContentReveal = 0
        contactsFoldMotion.stop(); contactsDragging = false
        contactsFold = contactsExpanded ? 1 : 0
        contourSamples = Contours.samples(0)
    }
    Connections {
        target: root.motion
        function onReducedChanged() {
            root.syncDock()
            if (!root.reducedMotion) return
            pageMotion.complete(); contactsIn.complete(); contactsOut.complete(); labelIn.complete(); labelOut.complete()
            contactsFoldMotion.complete()
            if (!root.contactsDragging) root.contactsFold = root.contactsExpanded ? 1 : 0
            root.updateContacts()
        }
    }
    SequentialAnimation {
        id: pageMotion
        onFinished: root.updateContacts()
        ParallelAnimation {
            NumberAnimation { target: root; property: "contentReveal"; to: 0; duration: root.pageLeavingWhatsapp ? 420 : root.motion.contentExit; easing.type: Easing.InOutCubic }
            NumberAnimation { target: root; property: "contactsContentReveal"; to: 0; duration: root.pageLeavingWhatsapp ? 180 : 0 }
            NumberAnimation { target: root; property: "contactsReveal"; to: 0; duration: root.pageLeavingWhatsapp ? 420 : 0; easing.type: Easing.InOutCubic }
        }
        ScriptAction { script: root.page = root.pendingPage }
        PauseAnimation { duration: root.reducedMotion ? 0 : root.pageMorphDuration }
        NumberAnimation { target: root; property: "contentReveal"; to: 1; duration: root.reducedMotion ? 0 : root.pageFadeDuration; easing.type: Easing.InOutCubic }
    }
    SequentialAnimation {
        id: contactsIn
        NumberAnimation { target: root; property: "contactsReveal"; to: 1; duration: 820; easing.type: Easing.InOutCubic }
        NumberAnimation { target: root; property: "contactsContentReveal"; to: 1; duration: 340; easing.type: Easing.InOutCubic }
    }
    SequentialAnimation {
        id: contactsOut
        NumberAnimation { target: root; property: "contactsContentReveal"; to: 0; duration: 180 }
        NumberAnimation { target: root; property: "contactsReveal"; to: 0; duration: 420; easing.type: Easing.InOutCubic }
    }
    Timer { id: labelLeave; interval: root.motion.leaveGrace; onTriggered: root.hideLabel() }
    SequentialAnimation {
        id: labelIn
        NumberAnimation { target: root; property: "labelReveal"; to: 1; duration: root.motion.geometryDuration; easing.type: Easing.OutCubic }
        NumberAnimation { target: root; property: "labelContent"; to: 1; duration: root.motion.contentDuration }
    }
    SequentialAnimation {
        id: labelOut
        NumberAnimation { target: root; property: "labelContent"; to: 0; duration: root.motion.contentExit }
        NumberAnimation { target: root; property: "labelReveal"; to: 0; duration: root.motion.closeDuration; easing.type: Easing.InOutCubic }
    }
    Item {
        id: labelArea
        x: root.width - root.railWidth - root.bodyWidth - width
        y: root.extension.y
        width: root.mounted ? root.extension.width : 0
        height: width > 0 ? root.extension.height : 0
        visible: height > 0
        clip: true
        HoverHandler { id: labelHover; blocking: false }
        Button {
            id: lyricsButton
            objectName: "edgeLyricsButton"
            visible: !root.whatsappPage
            width: 104; height: 44
            text: "Lyrics"
            opacity: root.labelContent
            enabled: root.opened && root.lyricsAvailable && opacity > .95
            Accessible.name: "Abrir letras da música no Spotify"
            onClicked: root.showPage("lyrics")
            background: Rectangle {
                anchors.margins: 4; anchors.fill: parent; radius: 9
                color: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, lyricsButton.hovered || lyricsButton.activeFocus ? .09 : 0)
            }
            contentItem: Text {
                text: lyricsButton.text; color: root.ink; font.family: root.family; font.pixelSize: 14
                horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
            }
        }
        Loader {
            objectName: "edgeWhatsAppContacts"
            width: parent.width; height: root.contactsHeight
            y: -24 * (1 - root.contactsContentReveal)
            visible: root.whatsappContactsVisible
            active: root.whatsappContactsVisible && !root.embeddedContacts && root.contactsReveal > 0
            opacity: root.contactsContentReveal * root.contentReveal * Math.min(1,root.contactsFold * 3)
            enabled: root.opened && root.contactsContentReveal > .9 && root.contactsFold > .98 && !root.contactsDragging
            sourceComponent: Component {
                VeloraWhatsAppContacts { preview: root.whatsappState; ink: root.ink; reducedMotion: root.reducedMotion; vertical: true }
            }
        }
    }
    VeloraWhatsAppContactsHandle {
        id: contactsHandle
        objectName: "whatsappContactsHandle"
        z: 4
        width: root.embeddedContacts ? 64 : root.contactsWidth
        x: root.width - root.railWidth - root.bodyWidth - (root.embeddedContacts ? 0 : width)
        y: root.bodyY + root.contactsHeight * root.contactsExtent
        visible: root.opened && root.whatsappPage && root.pendingPage === "whatsapp"
            && root.whatsappContactsVisible && root.reveal > .98 && root.contentReveal > .9 && root.contactsReveal > .98
        enabled: visible
        progress: root.contactsFold
        expanded: root.contactsExpanded
        travel: root.contactsHeight
        onDragStarted: root.beginContactsDrag()
        onDragged: progress => root.contactsFold = progress
        onReleased: expanded => root.settleContacts(expanded)
    }
    customContent: Component {
        Loader {
            readonly property bool interactionHeld: root.holdsInteraction(item)
            sourceComponent: root.page === "apps" ? apps : root.whatsappPage ? whatsapp : player
            Component {
                id: apps
                VeloraEdgeApps {
                    ink: root.ink; reducedMotion: root.reducedMotion
                    onSpotifyRequested: root.showPage("media")
                    onWhatsappRequested: root.showPage("whatsapp")
                    onSpotifyHoverChanged: hovered => root.spotifyHovered = hovered
                }
            }
            Component {
                id: whatsapp
                VeloraEdgeWhatsAppPanel {
                    preview: root.whatsappState; theme: root.theme
                    embeddedContacts: root.embeddedContacts; reducedMotion: root.reducedMotion
                    contactsProgress: root.contactsReveal; contactsOpacity: root.contactsContentReveal
                    contactsFold: root.contactsFold
                    onBackRequested: root.showPage("apps")
                    onCloseRequested: { root.blocked = root.triggerHovered; root.close() }
                }
            }
            Component {
                id: player
                VeloraEdgeMediaPanel {
                    media: root.media; library: mediaLibrary; theme: root.theme
                    lyrics: root.page === "lyrics"; reducedMotion: root.reducedMotion
                    contourSamples: root.contourSamples
                    onBackRequested: root.showPage("apps")
                    onLyricsRequested: root.showPage("lyrics")
                    onMediaRequested: root.showPage("media")
                    onCloseRequested: { root.blocked = root.triggerHovered; root.close() }
                }
            }
        }
    }
}
