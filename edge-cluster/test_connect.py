import random
import time
from paho.mqtt import client as mqtt_client
import json

# MQTT Configuration
BROKER = 'localhost'
PORT = 1883
TOPIC = "/python/mqtt"
CLIENT_ID = f'python-mqtt-{random.randint(0, 1000)}'

def connect_mqtt():
    """Connect to MQTT broker"""
    def on_connect(client, userdata, flags, rc):
        if rc == 0:
            print("Connected to MQTT Broker!")
        else:
            print("Failed to connect, return code %d\n", rc)







def run():
    # on reçoi : user, password, ID
    client = mqtt_client.Client()
    client.on_connect = on_connect
    client.connect(BROKER, PORT)
    time.sleep(1)
    client.subscribe("/auth/user/")

    payload = json.dumps({'ID': 134, 'USER': "Admin", "Password": "augeigf"})
    try:
        client.publish("auth/user/",payload)
        print("Message envoyé")
    except Exception as e:
        print(e)
    client.loop_forever()
    


if __name__ == '__main__':
    run()
