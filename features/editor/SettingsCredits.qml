pragma ComponentBehavior: Bound
import QtQuick

Column {
    id: root
    required property var theme
    required property var motion
    signal profileLinkRequested(string url)
    width: parent ? parent.width : 600
    spacing: 20
    function formatProfileText(value) {
        let result="",run="",family=""
        function flush() {
            if (run) result+='<font face="'+family+'">'+run+'</font>'
            run=""
        }
        for (const character of String(value)) {
            const point=character.codePointAt(0)
            const next=point>=0x1f000 && point<=0x1ffff ? emoji.name
                : "なかの｡|".includes(character) ? kana.name
                    : (point>=0x1d400 && point<=0x1d7ff) || "✩°⋆".includes(character) ? symbols.name : theme.bodyFont
            if (next!==family) { flush();family=next }
            run+=character==="\n" ? "<br/>" : character==="&" ? "&amp;" : character==="<" ? "&lt;" : character===">" ? "&gt;" : character
        }
        flush()
        return result
    }
    readonly property var styledFamilies: [symbols.name,kana.name,emoji.name,theme.bodyFont]
    FontLoader { id: symbols; source: Qt.resolvedUrl("../../assets/fonts/CreditsSymbols.otf") }
    FontLoader { id: kana; source: Qt.resolvedUrl("../../assets/fonts/CreditsKana.ttf") }
    FontLoader { id: emoji; source: Qt.resolvedUrl("../../assets/fonts/NotoColorEmoji.ttf") }
    Text {
        text: "Criador"; color: root.theme.textSecondary
        font.family: root.theme.bodyFont; font.pixelSize: 14; font.weight: Font.DemiBold
    }
    CreditProfile {
        objectName: "credits.creator"
        width: parent.width; theme: root.theme; motion: root.motion
        profileName: "Oshiro_"; displayName: "𝕆𝕤𝕙𝕚𝕣𝕠_"; role: "Criador"; tiktok: "_m_i_k_u__"
        nameFamilies: root.styledFamilies; formatProfileText: root.formatProfileText
        onProfileLinkRequested: url => root.profileLinkRequested(url)
    }
    Text {
        text: "Testers"; color: root.theme.textSecondary
        font.family: root.theme.bodyFont; font.pixelSize: 14; font.weight: Font.DemiBold
    }
    CreditProfile {
        objectName: "credits.tester1"
        width: parent.width; theme: root.theme; motion: root.motion
        profileName: "sooren"; role: "Tester"; nameLetterSpacing: 3; nameWeight: Font.DemiBold
    }
    CreditProfile {
        objectName: "credits.tester2"
        width: parent.width; theme: root.theme; motion: root.motion
        profileName: "なかの|𝘏𝘈𝘙𝘜✩°｡⋆ 💞🪽"; role: "Tester"; tiktok: "naka_haru_"
        nameFamilies: root.styledFamilies; formatProfileText: root.formatProfileText; wrapName: true
        recognition: "Primeiro tester do Velora e parceiro de mais longa data."
        statistics: [
            {id:"following",value:"347",label:"Seguindo"},
            {id:"followers",value:"6260",label:"Seguidores"},
            {id:"likes",value:"409.2K",label:"Curtidas"}
        ]
        biographyLead: "⋆｡°✩𝘛𝘦𝘤𝘩 𝘦𝘥𝘪𝘵𝘰𝘳 𝘸𝘪𝘵𝘩 𝘙𝘰𝘹𝘺 𝘵𝘦𝘢𝘮✩°｡⋆"
        biography: "📱- Poco X7 Pro SKver.\n💻- ASUS TUF F16 5060\n10k → I'm going to dress up as Maid In Live!"
        contactLabel: "Contact me ↓  linktr.ee/Naka_Haru"
        contactUrl: "https://linktr.ee/Naka_Haru"
        onProfileLinkRequested: url => root.profileLinkRequested(url)
    }
    Text {
        text: "Feedbacker"; color: root.theme.textSecondary
        font.family: root.theme.bodyFont; font.pixelSize: 14; font.weight: Font.DemiBold
    }
    CreditProfile {
        objectName: "credits.feedbacker"
        width: parent.width; theme: root.theme; motion: root.motion
        profileName: "liam | tech"; role: "Feedbacker"; tiktok: "l1am_edxts"
        nameWeight: Font.DemiBold
        onProfileLinkRequested: url => root.profileLinkRequested(url)
    }

}
