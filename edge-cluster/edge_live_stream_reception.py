import random
import time
from paho.mqtt import client as mqtt_client
import json

# MQTT Configuration
BROKER = '10.207.130.234'
PORT = 1883
TOPIC = "/python/mqtt"
EDGE_ID = f'python-mqtt-{random.randint(0, 1000)}'


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
        if (msg.topic==f"live/upload/{EDGE_ID}"):
            message_json=json.loads(msg.payload.decode())
            id_live=message_json["id_live"]
            signature=message_json["signature"]
            #faire des trucs avec la signature (voir avec Maxime)
            end = message_json["end"]
            if(end == 1):
                publish(client,f"live/db/update", json.dumps({"status":"fin","type":"live","id_live":id_live, "EDGE_ID":EDGE_ID}))
                #mettre à jour la bdd locale pour dire que le live id_live est terminé
            try:
                id_streamer=message_json["id_streamer"]
            except:
                id_streamer=None
            if(id_streamer):
                "partie 1"
                nom_streamer=message_json["nom_streamer"]
                category=message_json["category"]
                #TODO :
                #Regarder si id_streamer est dans la bdd
                #Si non le créer dans la bdd avec nom_streamer
                publish(client,f"live/db/update", json.dumps({"status":"ajout","type":"live","id_live":id_live, "EDGE_ID":EDGE_ID, "id_streamer":id_streamer, "nom_streamer":nom_streamer, "category":category}))
                #update la bdd locale pour dire que le live id_live est pris en charge par moi meme
            else:
                "partie 2"
                try:
                    chunk=message_json["chunk"]
                    chunk_part=message_json["chunk_ID"]
                    publish(client,f"live/watch/{EDGE_ID}/{id_live}", json.dumps({"status":"ok", "chunk":chunk, "chunk_part":chunk_part}))
                except:
                    chunk=None
                    chunk_part=None
                    #problemes, les chunk ont pas été recu
            
            
        if (msg.topic==f"live/db/update"):
            message_json=json.loads(msg.payload.decode())
            id_live=message_json["id_live"]
            EDGE_ID2=message_json["EDGE_ID"]
            #mettre à jour la bdd locale pour dire que le live est pris en charge par l'edge EDGE_ID2

        
  


    client.subscribe(topic)
    client.on_message = on_message


def run():
    # on reçoi : user, password, ID
    
    client = connect_mqtt()
    client.loop_forever()
    
    subscribe(client, f"auth/user/")
    


if __name__ == '__main__':
    run()
