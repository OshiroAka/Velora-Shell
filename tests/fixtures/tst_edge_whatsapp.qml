import QtQuick
import QtTest
import "../../components" as Components

Item {
    id: fixture
    width: 1000; height: 1100
    QtObject { id: palette; property string bodyFont: "sans-serif" }
    Components.VeloraWhatsAppPreview { id: preview }
    Components.VeloraEdgeWhatsAppPanel {
        id: panel
        x: 552; width: 448; height: 1100
        preview: preview; theme: palette; reducedMotion: true
    }
    Components.VeloraWhatsAppContacts {
        id: contacts
        x: 468; width: 84; height: 520
        preview: preview; reducedMotion: true
    }
    SignalSpy { id: backSpy; target: panel; signalName: "backRequested" }
    SignalSpy { id: closeSpy; target: panel; signalName: "closeRequested" }
    TestCase {
        name: "EdgeWhatsApp"; when: windowShown
        function init() {
            panel.width=448; panel.height=1100; panel.embeddedContacts=false
            preview.selectGroupMode(false)
            panel.forceActiveFocus(); wait(100)
        }
        function test_contacts_and_groups_are_local() {
            const name=findChild(panel,"whatsappContactName")
            const messages=findChild(panel,"whatsappMessages")
            compare(findChild(contacts,"whatsappContactsScroll").flickableDirection,Flickable.VerticalFlick)
            verify(findChild(contacts,"whatsappGroups").y>findChild(contacts,"whatsappPeople").y)
            compare(name.text,"Kael"); compare(messages.count,9)
            mouseClick(findChild(contacts,"whatsappContact1"))
            compare(name.text,"Lia"); tryCompare(messages,"count",2)
            mouseClick(findChild(contacts,"whatsappGroups"))
            compare(preview.groups,true); compare(name.text,"Entre amigos")
            wait(100)
            mouseClick(findChild(contacts,"whatsappPeople"))
            compare(name.text,"Kael")
        }
        function test_draft_never_sends_a_message() {
            const composer=findChild(panel,"whatsappComposer")
            const send=findChild(panel,"whatsappSend")
            const messages=findChild(panel,"whatsappMessages")
            mouseClick(composer); keyClick(Qt.Key_A); keyClick(Qt.Key_B)
            compare(preview.draft,"ab"); verify(panel.interactionHeld)
            verify(!send.enabled)
            mouseClick(send); compare(messages.count,9)
            preview.selectContact(1); compare(composer.text,"")
        }
        function test_responsive_chat_and_controls() {
            const messages=findChild(panel,"whatsappMessages")
            const composer=findChild(panel,"whatsappComposer")
            const back=findChild(panel,"whatsappBack")
            for (const size of [[320,560],[448,720],[448,1100]]) {
                panel.width=size[0]; panel.height=size[1]
                panel.embeddedContacts=size[0]<380; wait(100)
                const composerPosition=composer.mapToItem(panel,0,0)
                const listPosition=messages.mapToItem(panel,0,messages.height)
                verify(listPosition.y<=composerPosition.y,"Messages must not overlap the composer")
                verify(back.mapToItem(panel,0,back.height).y<=panel.height)
                for (let i=0;i<messages.count;i++) {
                    const row=messages.itemAtIndex(i)
                    if (!row) continue
                    const bubble=findChild(row,"whatsappBubble")
                    verify(bubble.x>=0 && bubble.x+bubble.width<=messages.width)
                    verify(bubble.height>0)
                    compare(bubble.color.a,1,"Messages use an opaque background above the liquid panel")
                }
            }
            back.forceActiveFocus(); keyClick(Qt.Key_Return); compare(backSpy.count,1)
            mouseClick(findChild(panel,"whatsappClose")); compare(closeSpy.count,1)
        }
    }
}
