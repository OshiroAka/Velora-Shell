import QtQuick
import QtQuick.Window
import QtTest
import Quickshell
import "../../components" as Components
import "../../services" as Services
import "../../surfaces" as Surfaces
import "../../core" as Core

ShellRoot {
    id: fixture
    QtObject {
        id: palette
        property string bodyFont: "sans-serif"
        property color textPrimary: "#f1f3f4"
        property color accent: "#55c6a5"
        property color accentSoft: "#55c6a5"
    }
    QtObject {
        id: media
        property bool detailActive: false
        property bool spotifyPlaying: false
        property real sampledPosition: 0
        property real length: 0
        property string artUrl: ""
    }
    Core.Motion { id: motion; reduced: true }
    Services.WhatsAppService { id: client; enabled: false }
    Surfaces.WhatsAppWindowHost {
        id: host
        client: client; theme: palette; reducedMotion: motion.reduced
        onOpening: edge.close()
        onDockRequested: monitor => { fixture.dockMonitor = monitor; edge.open(); edge.showPage("whatsapp") }
    }
    property string dockMonitor: ""
    Window {
        id: dockWindow
        width: 1000; height: 900; visible: true
        Components.VeloraEdgePopover {
            id: edge
            anchors.fill: parent; railWidth: 8; anchorY: 450
            theme: palette; media: media; whatsapp: client; whatsappWindow: host
            motion: motion; beatEnabled: false
            onWhatsappWindowRequested: host.open("fixture-monitor", edge)
        }
    }
    SignalSpy { id: commands; target: client; signalName: "commandRequested" }
    TestCase {
        id: checks
        name: "WhatsAppWindow"; when: false
        function ensure(value, reason) { if (!value) throw new Error(reason || "Assertion failed") }
        function equal(actual, expected, reason) { ensure(actual === expected, (reason || "Mismatch") + ": " + actual + " != " + expected) }
        function until(predicate, reason) { for (let i=0; i<80 && !predicate(); i++) wait(25); ensure(predicate(), reason) }
        function child(parent, name) { const value = findChild(parent, name); ensure(value, "Missing " + name); return value }
        function menuAction(parent) {
            mouseClick(child(parent, "whatsappAccount")); wait(40)
            mouseClick(child(parent, "whatsappWindowMode")); wait(40)
        }
        function windowChat() { return child(host.window.contentItem, "whatsappWindowChat") }
        function state(contacts, selected) {
            client.acceptState({type:"state", ready:true, hasSession:true, state:"connected", contacts:contacts, selectedId:selected || contacts[0].id})
        }
        function runChecks() {
            equal(host.window, null, "Window is absent before use")
            const history = Array.from({length:55}, (_, i) => ({id:"message-"+i, text:"Mensagem sintética "+i, time:"12:30", outgoing:i%3===0}))
            const contacts = [
                {id:"one", name:"Ágata", style:0, status:"Disponível", unread:0, messages:history},
                {id:"two", name:"Bia", style:1, status:"Disponível", unread:3, messages:[{id:"bia", text:"Olá", time:"12:31", outgoing:false}]},
                {id:"three", name:"Caio", style:2, unread:1, messages:[]}
            ]
            state(contacts)
            edge.open(); edge.showPage("whatsapp"); wait(150)
            let account = child(dockWindow.contentItem, "whatsappAccount")
            ensure(account.enabled, "Options are available")
            let composer = child(dockWindow.contentItem, "whatsappComposer")
            client.draft = "rascunho preservado"; composer.cursorPosition = 6
            client.attachments = [{id:"attachment",name:"documento.txt",kind:"document",mime:"text/plain"}]
            let messages = child(dockWindow.contentItem, "whatsappMessages")
            messages.followEnd=false; messages.contentY=320
            const offset = messages.contentY
            const commandCount=commands.count
            motion.reduced=false
            menuAction(dockWindow.contentItem)
            ensure(host.active && host.pending && !host.window, "Handoff waits for the connected surface to exit")
            until(() => !!host.window, "Window opens after the morph")
            ensure(!edge.mounted, "Dock is fully unmounted before showing the window")
            wait(200)
            equal(client.draft,"rascunho preservado", "Draft survives handoff")
            equal(client.attachments.length,1,"Attachments survive handoff")
            equal(commands.count,commandCount,"Handoff never sends a backend command")
            let chat=windowChat()
            composer=child(chat,"whatsappComposer")
            equal(composer.cursorPosition,6,"Caret survives handoff")
            messages=child(chat,"whatsappMessages")
            ensure(!messages.followEnd && Math.abs(messages.contentY-offset)<2,"Historical scroll survives handoff")
            const firstWindow=host.window
            host.open("second-monitor",edge); host.raise()
            equal(host.window,firstWindow,"Repeated activation keeps one window")
            mouseClick(child(host.window.contentItem,"whatsappWindowMinimize")); wait(40)
            equal(host.window.visibility,Window.Minimized,"Native minimize control works")
            host.raise(); wait(40)
            ensure(host.window.visibility!==Window.Minimized,"Activating WhatsApp restores the window")
            mouseClick(child(host.window.contentItem,"whatsappWindowMaximize")); wait(40)
            equal(host.window.visibility,Window.Maximized,"Native maximize control works")
            mouseClick(child(host.window.contentItem,"whatsappWindowMaximize")); wait(40)
            equal(host.window.visibility,Window.Windowed,"Restore returns to a normal window")
            edge.showPage("whatsapp")
            ensure(!edge.opened,"Window mode cannot open a competing drawer")
            let list=child(host.window.contentItem,"whatsappConversationList")
            equal(list.count,3,"All conversations are listed")
            let search=child(host.window.contentItem,"whatsappConversationSearch")
            composer.forceActiveFocus(); keyClick(Qt.Key_F,Qt.ControlModifier); wait(40)
            ensure(search.activeFocus,"Ctrl+F focuses conversation search")
            search.text="agata"; wait(50); equal(list.count,1,"Search ignores accents")
            search.text="bia"; wait(50); equal(list.count,1)
            mouseClick(child(host.window.contentItem,"whatsappWindowContact0")); wait(50)
            equal(commands.signalArguments[commands.count-1][0].id,"two","Filtered row selects the original conversation index")
            state(contacts,"two"); wait(60)
            equal(child(chat,"whatsappContactName").text,"Bia")
            search.text=""; wait(40)
            mouseClick(child(host.window.contentItem,"whatsappUnreadFilter")); wait(40)
            equal(list.count,2,"Unread filter uses actual counts")
            mouseClick(child(host.window.contentItem,"whatsappWindowGroup1")); wait(40)
            equal(commands.signalArguments[commands.count-1][0].action,"groups")
            equal(commands.signalArguments[commands.count-1][0].groups,true)
            motion.reduced=true
            for (const size of [[360,560],[620,700],[1080,740],[1600,1000]]) {
                host.window.width=size[0]; host.window.height=size[1]; wait(50)
                ensure(child(chat,"whatsappComposer").width>50,"Composer fits "+size)
                if (size[0]<760) {
                    const back=child(host.window.contentItem,"whatsappWindowBack")
                    mouseClick(back); wait(40)
                    ensure(child(host.window.contentItem,"whatsappConversationSidebar").visible,"Compact window shows conversation list")
                    mouseClick(child(host.window.contentItem,"whatsappWindowContact0")); wait(40)
                    ensure(chat.visible,"Selecting a conversation restores compact chat")
                }
            }
            host.window.width=1080; host.window.height=740; wait(50)
            grabImage(host.window.contentItem).save("@PREVIEW@")
            client.draft="voltar"; wait(40)
            menuAction(chat)
            until(() => !host.window,"Docking releases the native window")
            ensure(edge.opened && edge.whatsappPage,"Docking restores WhatsApp on the bar")
            equal(client.draft,"voltar")
            equal(client.attachments.length,1)
            ensure(fixture.dockMonitor.length > 0, "Docking preserves a destination monitor")
            menuAction(dockWindow.contentItem)
            until(() => !!host.window,"Window reopens")
            host.window.close(); wait(60)
            ensure(!host.active && !host.window,"Native close releases the window only")
            equal(client.state,"connected","Closing preserves the account connection")
            equal(client.draft,"voltar","Closing preserves draft")
            motion.reduced=false
            edge.open(); edge.showPage("whatsapp"); wait(100)
            host.open("fixture-monitor",edge)
            ensure(host.pending,"Animated handoff can be pending")
            host.close(); wait(1300)
            ensure(!host.window && !host.active,"Canceling a pending handoff cannot create a stray window")
            motion.reduced=true
            // Window mode is also available before pairing.
            client.acceptState({type:"state",ready:true,state:"idle",hasSession:false,contacts:[]})
            host.open("fixture-monitor",null); wait(100)
            ensure(child(host.window.contentItem,"whatsappPairing").active,"Pairing works in the window")
            menuAction(host.window.contentItem)
            until(() => !host.window,"Unpaired account can return to the bar")
            ensure(edge.opened,"Unpaired drawer is restored")
            ensure(child(dockWindow.contentItem,"whatsappAccount").enabled,"Three dots work before login")
            equal(commands.signalArguments.filter(row=>row[0].action==="send" || row[0].action==="logout" || row[0].action==="pair").length,0,"Presentation never sends, logs out or pairs")
            console.info("WHATSAPP_WINDOW_OK")
        }
    }
    Timer {
        interval: 100; running: true
        onTriggered: {
            try { checks.runChecks() }
            catch (error) { console.error("WHATSAPP_WINDOW_FAILED",String(error),error.stack || "") }
            Qt.quit()
        }
    }
}
