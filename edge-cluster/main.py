import random
import time
from paho.mqtt import client as mqtt_client

# MQTT Configuration
BROKER = '10.207.130.234'
PORT = 1883
TOPIC = "test/topic"
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

    client.subscribe(topic)
    client.on_message = on_message


def run():
    """Main function to run MQTT client"""
    client = connect_mqtt()
    
    subscribe(client, "test/topic")
    publish(client,"test/topic","AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA")
    client.loop_forever()


if __name__ == '__main__':
    run()