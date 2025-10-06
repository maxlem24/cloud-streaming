import random
import time
from paho.mqtt import client as mqtt_client
import json

# MQTT Configuration
BROKER = '10.207.130.234'
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
    

    client = mqtt_client.Client()
    client.on_connect = on_connect
    client.connect(BROKER, PORT)
    return client


def publish(client, topic, message):
    """Publish messages to MQTT topic"""
    msg_count = 0
    while True:
        time.sleep(1)
        msg = f"messages: {msg_count}"
        result = client.publish(topic, msg)
        
        # Check publish status
        status = result[0]
        if status == 0:
            print(f"Send `{msg}` to topic `{TOPIC}`")
        else:
            print(f"Failed to send message to topic {TOPIC}")
        msg_count += 1
        
        
def subscribe(client: mqtt_client, topic: str):
    def on_message(client, userdata, msg):
        print(f"Received `{msg.payload.decode()}` from `{msg.topic}` topic")
        if (msg.topic=="auth/user"):
            message_json=json.loads(msg.payload.decode())
            user=message_json["user"]
            password=message_json["password"]
            ID=message_json["ID"]
        #VERIF niveau bdd le user
        msg_a_envoyer={"param1":"param... A REMPLIR######################","status":"ok"}
        message_json=json.dumps(msg_a_envoyer)
        publish(client,f"auth/user/{ID}", message_json)


    client.subscribe(topic)
    client.on_message = on_message


def run():
    # on reçoi : user, password, ID
    
    client = connect_mqtt()
    subscribe(client, f"auth/user/")
    client.loop_forever()
    
    
    


if __name__ == '__main__':
    run()
