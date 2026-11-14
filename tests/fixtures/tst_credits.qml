import QtQuick
import QtTest
import "../../core" as Core
import "../../features/editor" as Editor

Item {
    id: fixture; width: 1000; height: 1050
    property string evidenceDirectory: ""
    QtObject { id: config; property bool reducedMotion: false; property string motionPreset: "balanced" }
    Core.Motion { id: motion; config: config }
    QtObject {
        id: palette
        property color textPrimary: "#f3edf1"
        property color textSecondary: "#b8b5c0"
        property color accentSoft: "#eeb6c3"
        property color moduleSurface: "#17171e"
        property color borderSubtle: "#443b47"
        property string bodyFont: "Sans"
        function withAlpha(color,alpha) { return Qt.rgba(color.r,color.g,color.b,alpha) }
    }
    Rectangle { anchors.fill: parent; color: "#131319" }
    Editor.SettingsCredits { id: page; x: 32; y: 24; width: 620; theme: palette; motion: motion }
    SignalSpy { id: links; target: page; signalName: "profileLinkRequested" }
    TestCase {
        name: "Credits"; when: windowShown
        function card(id) { return findChild(page,"credits."+id) }
        function veteranDetails(name) { return findChild(card("tester2"),name) }
        function outside() { mouseMove(fixture,fixture.width-5,fixture.height-5) }
        function capture(name) {
            if (fixture.evidenceDirectory) grabImage(fixture).save(fixture.evidenceDirectory+"/"+name+".png")
        }
        function init() {
            page.visible=true;page.width=620;outside();fixture.forceActiveFocus()
            config.reducedMotion=true
            for (const id of ["creator","tester1","tester2","feedbacker"]) card(id).dismiss()
            wait(30);config.reducedMotion=false;links.clear()
        }
        function test_profiles_initials_and_recognition() {
            compare(card("creator").profileName,"Oshiro_")
            compare(card("tester1").profileName,"sooren")
            compare(card("tester1").tiktok,"");compare(card("tester1").profileUrl,"")
            verify(!findChild(card("tester1"),"creditTikTok").visible)
            verify(card("tester2").recognition.indexOf("Primeiro tester")>=0)
            verify(card("tester2").recognition.indexOf("longa data")>=0)
            for (const id of ["creator","tester1","tester2","feedbacker"]) {
                verify(!findChild(card(id),"creditPortrait"),"No profile image renderer")
                const initial=findChild(card(id),"creditInitial")
                verify(initial && initial.text.length>0,"Profile initial remains visible")
                compare(card(id).reveal,0);verify(!card(id).animating)
            }
            capture("credits-idle")
        }
        function test_hover_slide_reversal_and_click() {
            const creator=card("creator")
            mouseMove(creator,creator.width/2,creator.avatarSize/2)
            wait(85);verify(creator.reveal>0 && creator.reveal<1)
            const before=creator.reveal
            outside();verify(Math.abs(creator.reveal-before)<.07,"Mouse exit must preserve the current pose")
            wait(90);verify(creator.reveal<before,"Mouse exit must start closing without a delay")
            mouseMove(creator,creator.width/2,creator.avatarSize/2)
            tryCompare(creator,"reveal",1)
            const link=findChild(creator,"creditTikTok")
            mouseMove(link,link.width/2,link.height/2)
            verify(creator.highlighted,"The link must remain reachable after leaving the avatar")
            mouseClick(link,link.width/2,link.height/2)
            compare(links.count,1);compare(links.signalArguments[0][0],"https://www.tiktok.com/@_m_i_k_u__")
            capture("credits-creator")
            outside();tryCompare(creator,"reveal",0);verify(!creator.animating)
        }
        function test_keyboard_focus_and_tester_links() {
            const tester=card("tester1")
            tester.forceActiveFocus(Qt.TabFocusReason);tryCompare(tester,"reveal",1)
            keyClick(Qt.Key_Return);compare(links.count,0,"sooren must not have an invented account")
            const veteran=card("tester2")
            veteran.forceActiveFocus(Qt.TabFocusReason);tryCompare(veteran,"reveal",1)
            const link=findChild(veteran,"creditTikTok")
            link.forceActiveFocus(Qt.TabFocusReason);keyClick(Qt.Key_Return)
            compare(links.count,1);compare(links.signalArguments[0][0],"https://www.tiktok.com/@naka_haru_")
            verify(veteran.highlighted)
            compare(veteran.profileName,"なかの|𝘏𝘈𝘙𝘜✩°｡⋆ 💞🪽")
            const details=findChild(veteran,"creditDetails")
            tryVerify(()=>details.visible && details.height>0)
            compare(veteranDetails("creditStat-following").text,"347")
            compare(veteranDetails("creditStat-followers").text,"6260")
            compare(veteranDetails("creditStat-likes").text,"409.2K")
            compare(veteran.biographyLead,"⋆｡°✩𝘛𝘦𝘤𝘩 𝘦𝘥𝘪𝘵𝘰𝘳 𝘸𝘪𝘵𝘩 𝘙𝘰𝘹𝘺 𝘵𝘦𝘢𝘮✩°｡⋆")
            compare(veteran.biography,"📱- Poco X7 Pro SKver.\n💻- ASUS TUF F16 5060\n10k → I'm going to dress up as Maid In Live!")
            const contact=veteranDetails("creditContact")
            contact.forceActiveFocus(Qt.TabFocusReason);keyClick(Qt.Key_Return)
            compare(links.count,2);compare(links.signalArguments[1][0],"https://linktr.ee/Naka_Haru")
            capture("credits-first-tester")
            outside();fixture.forceActiveFocus();tryCompare(veteran,"reveal",0)
            compare(details.height,0);verify(!veteran.animating)
        }
        function test_feedbacker_photo_hover_and_tiktok() {
            const profile=card("feedbacker")
            compare(profile.role,"Feedbacker");compare(profile.profileName,"liam | tech")
            mouseMove(profile,profile.width/2,profile.avatarSize/2)
            tryCompare(profile,"reveal",1)
            const link=findChild(profile,"creditTikTok")
            verify(link.visible)
            mouseClick(link,link.width/2,link.height/2)
            compare(links.count,1)
            compare(links.signalArguments[0][0],"https://www.tiktok.com/@l1am_edxts")
            capture("credits-feedbacker")
            outside();tryCompare(profile,"reveal",0);verify(!profile.animating)
        }
        function test_reduced_motion_mid_slide_and_hidden_page() {
            const creator=card("creator")
            mouseMove(creator,creator.width/2,creator.avatarSize/2);wait(70);verify(creator.animating)
            config.reducedMotion=true;compare(creator.reveal,1);verify(!creator.animating)
            outside();compare(creator.reveal,0,"Reduced motion must close immediately when the pointer leaves")
            config.reducedMotion=false;mouseMove(creator,creator.width/2,creator.avatarSize/2);wait(50)
            page.visible=false;compare(creator.reveal,0);verify(!creator.animating)
            page.visible=true;outside();fixture.forceActiveFocus()
            tryCompare(creator,"reveal",0)
        }
        function test_vertical_profile_list() {
            for (const width of [340,620,840]) {
                page.width=width;config.reducedMotion=true;wait(30)
                let previous=null
                for (const id of ["creator","tester1","tester2","feedbacker"]) {
                    const profile=card(id),position=profile.mapToItem(page,0,0)
                    fuzzyCompare(position.x,0,.1);fuzzyCompare(profile.width,page.width,.1)
                    if (previous) verify(previous.mapToItem(page,0,previous.height).y<=position.y,"Profiles must occupy separate non-overlapping rows")
                    previous=profile
                }
                const veteran=card("tester2"),liam=card("feedbacker")
                veteran.forceActiveFocus();wait(30)
                verify(liam.mapToItem(page,0,0).y>=veteran.mapToItem(page,0,veteran.height).y,"Expanded biography must move the next profile below it")
                const name=findChild(veteran,"creditName")
                verify(name.mapToItem(veteran,0,0).x>=veteran.avatarSize,"Name must slide to the right of the initial")
                fixture.forceActiveFocus();veteran.dismiss();wait(30)
            }
        }
        function test_inline_details_and_immediate_close() {
            const profile=card("tester2")
            const details=findChild(profile,"creditDetails")
            for (const width of [340,620,840]) {
                page.width=width;config.reducedMotion=true;wait(30)
                mouseMove(profile,profile.width/2,profile.avatarSize/2);wait(30)
                compare(profile.reveal,1)
                const bounds=details.mapToItem(page,0,0)
                const origin=profile.mapToItem(page,0,0)
                verify(bounds.x>=origin.x && bounds.x+details.width<=origin.x+profile.width,"Description must stay inside HARU's row")
                const link=findChild(profile,"creditTikTok")
                const bottom=link.mapToItem(profile,0,link.height)
                verify(details.y>=bottom.y && details.y-bottom.y<=18,"Description must touch the identity below the TikTok")
                for (const id of ["following","followers","likes"]) {
                    const stat=findChild(details,"creditStat-"+id)
                    const point=stat.mapToItem(details,0,0)
                    verify(point.x>=0 && point.x+stat.implicitWidth<=details.width,"Statistics must fit the profile width")
                }
                mouseMove(details,details.width/2,24);wait(30)
                compare(profile.reveal,1,"Reading the inline description must keep the expansion open")
                outside();compare(profile.reveal,0)
            }
            config.reducedMotion=false
            mouseMove(profile,profile.width/2,profile.avatarSize/2);tryCompare(profile,"reveal",1)
            outside();wait(80)
            verify(profile.reveal<1 && profile.animating,"Closing must start immediately after pointer exit")
            tryCompare(profile,"reveal",0,motion.accordionDuration+100)
        }
        function test_compact_layout_and_pinned_touch() {
            page.width=340;config.reducedMotion=true
            const creator=card("creator")
            mouseClick(creator,creator.width/2,creator.avatarSize/2);verify(creator.pinned);compare(creator.reveal,1)
            outside();compare(creator.reveal,1,"Tapped profile must stay open for touch")
            for (const id of ["creator","tester2"]) {
                const profile=card(id)
                profile.pinned=true
                const name=findChild(profile,"creditName")
                const point=name.mapToItem(profile,0,0)
                verify(point.x>=0 && point.x+name.width<=profile.width,"Names must fit the compact page")
            }
            const veteran=card("tester2")
            const bio=veteranDetails("creditBio")
            verify(bio.wrapMode===Text.WordWrap)
            verify(findChild(veteran,"creditDetails").visible && findChild(veteran,"creditDetails").height>0,"Long-time tester details must expand beneath his identity")
            capture("credits-compact")
            mouseClick(creator,creator.width/2,creator.avatarSize/2);verify(!creator.pinned)
        }
    }
}
