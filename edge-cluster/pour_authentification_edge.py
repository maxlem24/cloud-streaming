if __name__ == '__main__':
    run()

import json
from paho.mqtt import client as mqtt_client
import uuid
from supabase import create_client, Client
import jwt

url: str = "https://ipbcjhqfquwyitrxnemq.supabase.co/"
key: str = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlwYmNqaHFmcXV3eWl0cnhuZW1xIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA0MTY4NzcsImV4cCI6MjA3NTk5Mjg3N30.rk6zV-GfcClHuykQ4QJ7fURztFy9JlQBP84V_u3I8rw"
supabase: Client = create_client(url, key)

# MQTT Configuration
BROKER = '10.246.146.52'
PORT = 1883
EDGE_ID = str(uuid.uuid4())  # Unique ID for this edge cluster
TOPIC_ID = f"auth/user/{EDGE_ID}/"
DB_NAME = 'edge_cluster.db'

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
    result = client.publish(topic, message)
    status = result[0]
    if status == 0:
        print(f"Send `{message}` to topic `{topic}`")
    else:
        print(f"Failed to send message to topic {topic}")


def subscribe(client: mqtt_client, topic: str):
    def on_message(client, userdata, msg):
        print(f"Received `{msg.payload.decode()}` from `{msg.topic}` topic")
        if (msg.topic=="auth/zone"):
            # on reçoi : ID
            message_json=json.loads(msg.payload.decode())
            ID=message_json["ID"]
            #récupérer les paramètres de la zone
            msg_a_envoyer={"param1":"param... A REMPLIR######################","status":"ok"}
            message_json=json.dumps(msg_a_envoyer)
            publish(client,f"auth/zone/{ID}", message_json)
        if (msg.topic=="auth/user"):
            message_json=json.loads(msg.payload.decode())
            jwt=message_json["jwt"]
            try:
                response = supabase.auth.get_claims(jwt)
                client_id=response["claims"]["sub"]
                #lancer jar de maxime
                msg_a_envoyer={"status":"ok"}
            except Exception as e:
                msg_a_envoyer={"status":"notok"}

            publish(client,f"auth/user/{client_id}", json.dumps(msg_a_envoyer))
    client.subscribe(topic)
    print(f"On est souscrit au topic {topic}")
    client.on_message = on_message
            
        
    client.subscribe(topic)
    print(f"On est souscrit au topic {topic}")
    client.on_message = on_message


def run():
    """Main function to run MQTT client"""

    client = connect_mqtt()
    
    subscribe(client, "auth/zone")  
    subscribe(client, "auth/user")  
    
    print(f"Edge Cluster ID: {EDGE_ID}")

    client.loop_forever()
