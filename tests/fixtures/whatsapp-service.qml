import QtQuick
import QtQuick.Window
import QtTest
import QtMultimedia
import Quickshell
import "../../components" as Components
import "../../services" as Services

ShellRoot {
    id: fixture
    QtObject { id: palette; property string bodyFont: "sans-serif" }
    Services.WhatsAppService { id: client; enabled: false }
    Window {
        id: win
        width: 448; height: 1100; visible: true
        Components.VeloraEdgeWhatsAppPanel {
            id: panel
            anchors.fill: parent
            preview: client; theme: palette; embeddedContacts: true; reducedMotion: true
        }
        SignalSpy { id: commands; target: client; signalName: "commandRequested" }
        TestCase {
            id: checks; name: "WhatsAppConnection"; when: false
            function equal(actual,expected,message) {
                if (actual!==expected) throw new Error((message||"Value mismatch")+": "+actual+" != "+expected)
            }
            function ensure(value,message) { if (!value) throw new Error(message||"Check failed") }
            function until(predicate,message) { for(let i=0;i<40&&!predicate();i++) wait(50); ensure(predicate(),message) }
            function coloredEmojiVisible() {
                const pixels=grabImage(win.contentItem)
                for(let y=0;y<pixels.height;y+=2) for(let x=0;x<pixels.width;x+=2)
                    if (pixels.red(x,y)>128 && pixels.green(x,y)>50 && pixels.blue(x,y)<80) return true
                return false
            }
            function test_pairing_modes_and_real_messages() {
                client.acceptState({type:"state",ready:true,state:"idle",method:"qr",hasSession:false,contacts:[]})
                wait(150)
                const loader=findChild(panel,"whatsappPairing")
                ensure(loader.active,"Pairing form must mount before login")
                mouseClick(findChild(panel,"whatsappMethodcode"))
                equal(commands.signalArguments[0][0].action,"method")
                equal(commands.signalArguments[0][0].method,"code")
                client.acceptState({type:"state",ready:true,state:"idle",method:"code",hasSession:false,contacts:[]})
                wait(80)
                const phone=findChild(panel,"whatsappPairPhone")
                phone.text="5511999990000"
                mouseClick(findChild(panel,"whatsappPairConnect"))
                equal(commands.signalArguments[1][0].action,"pair")
                equal(commands.signalArguments[1][0].phone,"5511999990000")
                client.acceptState({type:"state",ready:true,state:"awaiting_code",method:"code",hasSession:false,
                    pairingCode:"ABCD-1234",contacts:[]})
                wait(80)
                equal(findChild(panel,"whatsappPairCode").text,"ABCD-1234")
                mouseClick(findChild(panel,"whatsappMethodqr"))
                equal(commands.signalArguments[2][0].method,"qr")
                const svg="data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNTAiIGhlaWdodD0iMjUwIj48cmVjdCB3aWR0aD0iMjUwIiBoZWlnaHQ9IjI1MCIgZmlsbD0id2hpdGUiLz48L3N2Zz4="
                client.acceptState({type:"state",ready:true,state:"awaiting_qr",method:"qr",hasSession:false,qrImage:svg,contacts:[]})
                tryCompare(findChild(panel,"whatsappPairQr"),"status",Image.Ready)
                for (const size of [[320,560],[448,720],[448,1100]]) {
                    win.width=size[0]; win.height=size[1]; wait(100)
                    const connect=findChild(panel,"whatsappPairConnect")
                    const position=connect.mapToItem(panel,0,0)
                    ensure(position.y>=90 && position.y+connect.height<=panel.height,
                        "Pairing controls stay inside "+size+": y="+position.y+" height="+connect.height)
                }
                win.width=448; win.height=1100
                client.acceptState({type:"state",ready:true,state:"connected",method:"qr",hasSession:true,selectedId:"1@s.whatsapp.net",
                    contacts:[{id:"1@s.whatsapp.net",name:"Ana",style:-1,avatar:"",status:"Conversa",messages:[
                        {id:"one",text:"/menu <b>literal</b>",time:"12:00",outgoing:false,read:false,senderAvatar:svg},
                        {id:"two",text:"Recebida",time:"12:01",outgoing:false,read:false}]}]})
                wait(100)
                ensure(!loader.active,"Pairing closes after login")
                const messages=findChild(panel,"whatsappMessages")
                equal(messages.count,2)
                equal(findChild(panel,"whatsappContactName").text,"Ana")
                ensure(!findChild(panel,"whatsappComposer").readOnly,"Connected composer is editable")
                ensure(!findChild(panel,"whatsappSend").enabled,"Empty composer cannot send")
                const bubble=findChild(messages.itemAtIndex(0),"whatsappBubble")
                const body=findChild(bubble,"whatsappMessageText")
                ensure(body,"Message body is present"); equal(body.textFormat,Text.PlainText)
                equal(findChild(messages.itemAtIndex(0),"whatsappSenderAvatar").imageSource,svg)
                equal(commands.count,3,"Received messages never trigger outgoing commands")
                const composer=findChild(panel,"whatsappComposer")
                mouseClick(composer); keyClick(Qt.Key_A); keyClick(Qt.Key_B)
                equal(client.draft,"ab")
                ensure(findChild(panel,"whatsappSend").enabled)
                keyClick(Qt.Key_Return)
                equal(commands.signalArguments[3][0].action,"send")
                equal(commands.signalArguments[3][0].text,"ab")
                client.acceptState({type:"sent",chat:client.selectedId,text:"ab"}); equal(composer.text,"")
                keyClick(Qt.Key_V,Qt.ControlModifier)
                equal(commands.signalArguments[4][0].action,"paste")
                client.acceptState({type:"paste",chat:client.selectedId,text:"colado"})
                equal(composer.text,"colado")
                client.acceptState({type:"operation",error:"Não enviado"})
                equal(client.operationError,"Não enviado")
                // A group history refresh may change portraits without resetting scroll.
                const history=[]
                for (let i=0;i<40;i++) history.push({id:"group-"+i,text:"Mensagem "+i,time:"12:00",outgoing:false,
                    sender:i%2?"Bea":"Ana",senderAvatar:svg})
                function groupState(items) { return {type:"state",ready:true,state:"connected",hasSession:true,groups:true,
                    selectedId:"1@g.us",contacts:[{id:"1@g.us",name:"Friends",style:-1,avatar:svg,status:"Grupo",messages:items}]} }
                client.acceptState(groupState(history)); wait(150)
                until(()=>messages.atLatest,"Group opens at the most recent message")
                const tail=messages.itemAtIndex(messages.count-1)
                ensure(tail && tail.y+tail.height<=messages.contentY+messages.height+1,"Last message is fully visible")
                equal(findChild(messages.itemAtIndex(38),"whatsappSenderName").text,"Ana")
                equal(findChild(messages.itemAtIndex(39),"whatsappSenderName").text,"Bea")
                messages.contentY=200; messages.followEnd=false
                const offset=messages.contentY
                const jump=findChild(panel,"whatsappScrollBottom")
                ensure(jump.visible,"Scroll-down button appears away from the bottom")
                const refreshed=history.map(value=>Object.assign({},value,{senderAvatar:""}))
                client.acceptState(groupState(refreshed));wait(100)
                ensure(Math.abs(messages.contentY-offset)<1,"Portrait refresh preserves scroll")
                mouseClick(jump); wait(100); ensure(messages.atLatest,"Scroll-down button reaches the bottom")
                messages.contentY=200; messages.followEnd=false
                const extended=refreshed.concat([{id:"own-send",text:"Enviada",time:"12:01",outgoing:true}])
                client.acceptState({type:"sent",chat:client.selectedId,text:"colado"})
                client.acceptState(groupState(extended));wait(100)
                ensure(messages.atLatest,"Own sends keep the group at the bottom")
                const mediaItems=[
                    {id:"picture",text:"Imagem",time:"12:02",outgoing:false,sender:"Ana",media:{kind:"image",source:svg}},
                    {id:"video",text:"Vídeo",time:"12:03",outgoing:false,sender:"Bea",media:{kind:"video",source:"VIDEO_FIXTURE_URL",thumbnail:svg}},
                    {id:"audio",text:"Mensagem de voz",time:"12:04",outgoing:false,sender:"Ana",media:{kind:"audio",source:"AUDIO_FIXTURE_URL",seconds:3}}
                ]
                client.acceptState(groupState(mediaItems));wait(200)
                mouseClick(findChild(messages.itemAtIndex(0),"whatsappOpenMedia")); wait(100)
                const viewer=findChild(panel,"whatsappMediaViewer")
                ensure(viewer.visible,"Image opens inside the panel");viewer.close();wait(100)
                mouseClick(findChild(messages.itemAtIndex(1),"whatsappOpenMedia"))
                const videoPlayer=findChild(panel,"whatsappVideoPlayer")
                until(()=>videoPlayer.duration>0,"Qt decodes the video")
                ensure(videoPlayer.error===MediaPlayer.NoError,"Video has no decode error")
                viewer.close(); wait(100)
                mouseClick(findChild(messages.itemAtIndex(2),"whatsappPlayAudio"))
                const audioBubble=findChild(messages.itemAtIndex(2),"whatsappBubble")
                ensure(audioBubble.width<=176 && audioBubble.height<=70,"Audio bubble stays compact")
                ensure(audioBubble.color.a===1,"Audio bubbles must be opaque above the liquid panel")
                const audioPlayer=findChild(panel,"whatsappAudioPlayer")
                until(()=>audioPlayer.duration>0,"Qt decodes the audio")
                ensure(audioPlayer.error===MediaPlayer.NoError,"Audio has no decode error")
                ensure(audioPlayer.playbackState===MediaPlayer.PlayingState,"Audio playback starts")
                mouseClick(findChild(messages.itemAtIndex(2),"whatsappPlayAudio"));wait(100)
                equal(audioPlayer.playbackState,MediaPlayer.PausedState)
                const seek=findChild(messages.itemAtIndex(2),"whatsappAudioSeek")
                ensure(seek.enabled,"Compact audio keeps seeking available")
                mouseClick(seek,seek.width*.7,seek.height/2)
                until(()=>audioPlayer.position>1500,"Compact progress track seeks in the decoded audio")
                ensure(seek.mapToItem(audioBubble,seek.width,0).x<audioBubble.width,"Progress track fits the bubble")
                const duration=findChild(messages.itemAtIndex(2),"whatsappAudioTime")
                ensure(duration.mapToItem(audioBubble,duration.width,0).x<=audioBubble.width-6,"Audio duration fits the bubble")
                client.acceptState(groupState([{id:"short",text:"?",time:"12:04",outgoing:false,sender:"Ana"}]))
                wait(150)
                const shortBubble=findChild(messages.itemAtIndex(0),"whatsappBubble")
                ensure(shortBubble.width<120 && shortBubble.height<76,"Short group message follows its content")
                until(()=>findChild(panel,"whatsappEmojiFont").status===FontLoader.Ready,"Bundled emoji font loads")
                const emojiButton=findChild(panel,"whatsappEmoji")
                ensure(emojiButton.enabled && !emojiButton.tooltipEnabled,"Emoji control works without a tooltip")
                client.draft="ab";composer.cursorPosition=1
                mouseClick(emojiButton);wait(100)
                const picker=findChild(panel,"whatsappEmojiPicker")
                ensure(picker.visible,"Emoji picker opens")
                const emojiGrid=findChild(panel,"whatsappEmojiGrid")
                const option=emojiGrid.itemAtIndex(0)
                ensure(option,"Emoji option is created")
                ensure(picker.y>500,"Picker sits above the composer")
                ensure(coloredEmojiVisible(),"Emoji glyph renders in color")
                mouseClick(option);wait(80)
                equal(client.draft,"a😀b","Emoji is inserted at the caret")
                ensure(coloredEmojiVisible(),"Composer preserves the color emoji fallback")
                mouseClick(findChild(panel,"whatsappSend"))
                equal(commands.signalArguments[commands.count-1][0].text,"a😀b","Emoji uses real send action")
                client.acceptState({type:"sent",chat:client.selectedId,text:"a😀b"})
                mouseClick(emojiButton);wait(80)
                mouseClick(findChild(panel,"whatsappPickerTabs").itemAt(1));wait(100)
                equal(commands.signalArguments[commands.count-1][0].action,"stickers")
                client.stickers=[{chat:"1@g.us",id:"sticker-one",kind:"sticker",source:"STICKER_FIXTURE_URL",displaySource:"STICKER_PREVIEW_URL",isAnimated:true}]
                wait(120)
                const stickerOption=findChild(panel,"whatsappStickerGrid").itemAtIndex(0)
                const stickerAnimation=findChild(stickerOption,"whatsappStickerAnimation")
                until(()=>stickerAnimation.status===Image.Ready,"Qt decodes the animated sticker")
                ensure(stickerAnimation.frameCount===2 && !stickerAnimation.playing,"Reduced motion pauses the animated sticker")
                mouseClick(stickerOption);wait(100)
                ensure(commands.signalArguments.some(value=>value[0].action==="attachSticker" && value[0].id==="sticker-one"),"Sticker selection attaches the real message")
                // Motion is visual only: a received row enters without shifting a historical viewport.
                panel.reducedMotion=false
                picker.mode=0
                mouseClick(emojiButton);wait(80)
                ensure(picker.reveal>0 && picker.reveal<1,"Picker opens through an intermediate pose")
                wait(280);equal(picker.reveal,1)
                picker.close();wait(80)
                ensure(picker.reveal>0 && picker.reveal<1,"Picker closes with a smooth fade")
                wait(150);ensure(!picker.visible,"Picker finishes closing")
                const firstMotion=findChild(messages.itemAtIndex(0),"whatsappMessageMotion")
                mouseMove(shortBubble,10,12);wait(100)
                ensure(firstMotion.hoverAmount>0 && firstMotion.lift<0,"Message hover lifts and highlights")
                mouseMove(win.contentItem,0,0);wait(230)
                client.acceptState(groupState([{id:"short",text:"?",time:"12:04",outgoing:false,sender:"Ana"},
                    {id:"arrival",text:"Nova mensagem",time:"12:05",outgoing:false,sender:"Bea"}]))
                wait(90)
                const arrivalMotion=findChild(messages.itemAtIndex(1),"whatsappMessageMotion")
                ensure(arrivalMotion.presence>0 && arrivalMotion.presence<1,"Received message has an intermediate entrance")
                wait(470);equal(arrivalMotion.presence,1)
                client.acceptState(groupState([{id:"short",text:"?",time:"12:04",outgoing:false,sender:"Ana"},
                    {id:"arrival",text:"Nova mensagem",time:"12:05",outgoing:false,sender:"Bea"},
                    {id:"outgoing",text:"Resposta",time:"12:05",outgoing:true,read:false}]))
                wait(80)
                const outgoingMotion=findChild(messages.itemAtIndex(2),"whatsappMessageMotion")
                ensure(outgoingMotion.presence>0 && outgoingMotion.presence<1 && outgoingMotion.slide>0,"Sent message enters from the outgoing side")
                client.acceptState({type:"sent",chat:client.selectedId,text:"Resposta"});wait(60)
                ensure(panel.sendPulse>0,"Successful send gives visual feedback")
                wait(430);equal(panel.sendPulse,0);equal(outgoingMotion.presence,1)
                firstMotion.scrollVelocity=3200;wait(150)
                ensure(firstMotion.scrollEnergy>.5 && firstMotion.scrollLag<0,"Fast scroll reacts in the direction of travel")
                firstMotion.scrollVelocity=-3200;wait(150);ensure(firstMotion.scrollLag>0,"Scroll reversal reverses the lag")
                panel.reducedMotion=true;wait(200)
                equal(firstMotion.scrollEnergy,0);equal(firstMotion.scrollLag,0);equal(firstMotion.lift,0)
                mouseClick(findChild(panel,"whatsappAccount")); wait(100)
                mouseClick(findChild(panel,"whatsappLogout"))
                equal(commands.signalArguments[commands.count-1][0].action,"logout")
            }
        }
    }
    Timer {
        interval: 200; running: true
        onTriggered: {
            try { checks.test_pairing_modes_and_real_messages(); console.info("WHATSAPP_CONNECTION_OK") }
            catch (error) { console.error("WHATSAPP_CONNECTION_FAILED",String(error),error.stack||"") }
            Qt.quit()
        }
    }
}
