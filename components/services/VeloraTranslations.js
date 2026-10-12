.pragma library

const texts = {
    "ja": {
        "bluetoothOff": "Bluetooth オフ",
        "btReady": "接続できます",
        "btDisabled": "無線が無効です",
        "btMissing": "bluetoothctl 未検出",
        "btInstall": "BlueZ tools をインストール",
        "btDevices": "デバイス",
        "btNoDevices": "デバイスなし",
        "btUnavailable": "Bluetooth は利用できません",
        "connect": "接",
        "disconnect": "切"
    },
    "en": {
        "bluetoothOff": "Bluetooth off",
        "btReady": "Ready to connect",
        "btDisabled": "Radio disabled",
        "btMissing": "bluetoothctl not found",
        "btInstall": "Install BlueZ tools",
        "btDevices": "devices",
        "btNoDevices": "No devices",
        "btUnavailable": "Bluetooth unavailable",
        "connect": "Connect",
        "disconnect": "Disconnect"
    },
    "pt-BR": {
        "bluetoothOff": "Bluetooth desligado",
        "btReady": "Pronto para conectar",
        "btDisabled": "Radio desativado",
        "btMissing": "bluetoothctl nao encontrado",
        "btInstall": "Instale as ferramentas BlueZ",
        "btDevices": "dispositivos",
        "btNoDevices": "Sem dispositivos",
        "btUnavailable": "Bluetooth indisponivel",
        "connect": "Conectar",
        "disconnect": "Desconectar"
    }
}

function translate(key, language) {
    const table = texts[language] || texts["pt-BR"]
    return table[key] || texts["pt-BR"][key] || key
}
