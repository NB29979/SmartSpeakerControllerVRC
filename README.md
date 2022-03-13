# SmartSpeakerControllerVRC
VRChatでGoogleHomeを使って英訳するためのツールのバックエンド。

https://twitter.com/NB29979/status/1502269263188430849

# 処理の流れ
SmartSpeaker(SpeechInput) -> IFTTT -> [MQTT] -> PythonScript(Main.py) -> [HTTPS] -> DeepLAPI -> PythonScript(Main.py) -> [OSC] -> VRChat
