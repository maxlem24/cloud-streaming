import json
import random
import time
from paho.mqtt import client as mqtt_client

# MQTT Configuration
BROKER = 'localhost'
PORT = 1883
TOPIC = "auth/user/"
TOPIC_ID = "auth/user/ID/"
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
    result = client.publish(topic, message)
    # Check publish status
    status = result[0]
    if status == 0:
        print(f"message lancé vers {topic}")
    else:
        print(f"Failed to send message to topic {TOPIC}")
    msg_count += 1
        

def subscribe(client: mqtt_client, topic: str):
    def on_message(client, userdata, msg):
        print(f"Received `{msg.payload.decode()}` from `{msg.topic}` topic")
        if (msg.topic=="auth/user/"):
            message_json=json.loads(msg.payload.decode())
            user=message_json["user"]
            password=message_json["password"]
            ID=message_json["ID"]

        if (msg.topic==f"auth/user/{CLIENT_ID}/"):
            print("Message reçu depuis auth/user/ID/")

        if (msg.topic=="db/"):

            ID = "A remplacer quand on aura le format des paquets"
            
            if 'db is present':
                # send db 
                print("TODO: send DB")
                publish(client,f"db/{ID}")

            else:
                '''db non presente'''
                payload = json.dumps({'DB' : "Empty"})
                publish(client,f"db/{ID}",payload)
        if (msg.tpoic == f"db/{CLIENT_ID}"):
            ''
    client.subscribe(topic)
    client.on_message = on_message

def premiere_connexion(client):
    # On envoie notre ID au serveur.
    publish(client,"auth/user/",CLIENT_ID)
    publish(client,"db/",CLIENT_ID)


def run():
    """Main function to run MQTT client"""
    client = connect_mqtt()
    subscribe(client, TOPIC)
    subscribe(client,TOPIC_ID)      
    client.loop_forever()


if __name__ == '__main__':
    run()