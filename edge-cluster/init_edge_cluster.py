import json
import random
import threading
import time
from paho.mqtt import client as mqtt_client
import datetime




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

    client.subscribe(topic)
    print(f"On s'est abonnée au topic {topic}")
    client.on_message = on_message



# Cette fonction, étant appelé une première fois, on peut définir le on_message comme on veut
# Une fois cela fait, on va redéfinir le on_message via la fonction subscribe
   
dernier_message = None



def get_database(client,topic,message):
    timestamp_actuel = int(time.time())    
    result = client.publish(topic, message)
    # Check publish status
    status = result[0]
    if status == 0:
        print(f"message lancé vers {topic}")
    else:
        print(f"Failed to send message to topic {TOPIC}")

    # Partie Database reçu après 5 secondes

    msg_event = threading.Event()
    def message_debut(client,topic,message):
        if (message.topic == f"db/{CLIENT_ID}"):
            print("Message reçu, on a une DB")
            dernier_message = message.payload.decode()
            didIReceiveMyDatabase = True   
        msg_event.set()            
    client.subscribe(f"db/{CLIENT_ID}")
    client.on_message = message_debut

    message_arrive = msg_event.wait(timeout=5)
    if message_arrive:
        print(f"Message reçu: {dernier_message}")
        # -> faire ton "autre chose" ici
    else:
        print("Aucun message reçu dans les 5 secondes.")
    # -> faire ton "truc" ici

    

            
    



def premiere_connexion(client):
    # On envoie notre ID au serveur.
    publish(client,"auth/user/",CLIENT_ID)
    get_database(client,"db/",CLIENT_ID)
    


def run():
    """Main function to run MQTT client"""
    client = connect_mqtt()
    premiere_connexion(client)      
    subscribe(client, TOPIC)
    subscribe(client,TOPIC_ID)
    client.loop_forever()



if __name__ == '__main__':
    run()