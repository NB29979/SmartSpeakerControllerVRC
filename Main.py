#  -*- utf-8 -*-
from fnmatch import translate
import json
import time
import json
import requests
import paho.mqtt.client as mqtt
from pythonosc import udp_client


prop_dict = {}
with open('Property.json')as f:
    prop_dict = json.load(f)

character_value_list = []
with open('CharacterValueList.json')as f:
    character_value_list = json.load(f)


# for MQTT Server
HOST   = prop_dict["MQTT"]["HOST"]
TOPIC  = prop_dict["MQTT"]["TOPIC"]
TOKEN  = prop_dict["MQTT"]["TOKEN"]
CACEPT = prop_dict["MQTT"]["CACEPT"]
PORT   = prop_dict["MQTT"]["PORT"]

# for OSC Client
LOCALIP   = prop_dict["OSC"]["LOCALIP"]
LOCALPORT = prop_dict["OSC"]["LOCALPORT"]

# for DeepL
AUTH_KEY = prop_dict["DeepL"]["AUTH_KEY"]



def on_connect(client, userdata, flags, response_code):
    client.subscribe(TOPIC)


def on_message(client, userdata, msg):
    recog_result = json.loads(msg.payload.decode("utf-8"))["data"]
    # 音声認識結果のスペースを詰める
    speech_input = recog_result.replace(' ', '')

    # Ex. VRCで空を飛びたい
    substr_index = speech_input.find("空を飛")
    if substr_index !=-1:
        send_jumping()
        print("jumping")

    # Ex. VRCで英訳 ほげほげ
    substr_index = speech_input.find("英訳")
    if substr_index != -1:
        speech_input = speech_input[substr_index+2:]
        print(speech_input)
        translated_input = translate_message(speech_input)
        send_translated_message(translated_input)


def send_message(address, value):
    osc_client = udp_client.SimpleUDPClient(LOCALIP, LOCALPORT)
    osc_client.send_message(address, value)
    time.sleep(0.05)


def send_message_(address, value):
    osc_client = udp_client.SimpleUDPClient(LOCALIP, LOCALPORT)
    osc_client.send_message(address, value)
    time.sleep(0.02)


def send_jumping():
    send_message("/avatar/parameters/fly", 1)
    send_message("/input/Jump", 1)
    send_message("/input/Jump", 0)


def initialize_character_table():
    for i in range(0,70):
        send_message_("/avatar/parameters/MotionTime_Index", (1.0/70)*i)
        send_message_("/avatar/parameters/MotionTime_Value", 0.0)


def translate_message(input_text):
    data = {
    'auth_key': AUTH_KEY,
    'text': input_text,
    'target_lang': 'EN'
    }

    response = requests.post('https://api-free.deepl.com/v2/translate', data=data)
    response_json = json.loads(response.content.decode())
    return response_json["translations"][0]["text"]


def send_translated_message(translated_text):
    print(translated_text)
    # 70が描画上限なのでカットする
    translated_text = translated_text[:min(70,len(translated_text))]

    converted_index_list = []
    for character in translated_text:
        # CharacterValuelistにない文字はスペース(0)として扱う
        if character in character_value_list:
            converted_index_list.append(character_value_list.index(character))
        else:
            converted_index_list.append(0)

    print(converted_index_list)

    for tableIndex, character_value in enumerate(converted_index_list):
        send_message("/avatar/parameters/MotionTime_Index", (1.0/70)*(tableIndex+1))
        send_message("/avatar/parameters/MotionTime_Value", (1.0/60)*character_value)
    time.sleep(2.5)
    initialize_character_table()


if __name__ == '__main__':
    client = mqtt.Client()
    client.on_connect = on_connect
    client.on_message = on_message
    client.username_pw_set("token:%s" % TOKEN)
    client.tls_set(CACEPT)
    client.connect(HOST, port=PORT, keepalive=60)
    client.loop_forever()
