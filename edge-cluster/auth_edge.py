

import json
from paho.mqtt import client as mqtt_client
import uuid
from supabase import create_client, Client
import jwt
import subprocess
import requests
import os

url: str = "https://ipbcjhqfquwyitrxnemq.supabase.co/"
key: str = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlwYmNqaHFmcXV3eWl0cnhuZW1xIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA0MTY4NzcsImV4cCI6MjA3NTk5Mjg3N30.rk6zV-GfcClHuykQ4QJ7fURztFy9JlQBP84V_u3I8rw"
supabase: Client = create_client(url, key)

# MQTT Configuration
BROKER = os.getenv("MQTT_BROKER", "localhost")
PORT = 1883
EDGE_ID = str(uuid.uuid4())  # Unique ID for this edge cluster
TOPIC_ID = f"auth/user/{EDGE_ID}/"
DB_NAME = 'edge_cluster.db'

JAR_PATH = "cloud_signature-1.0-SNAPSHOT-jar-with-dependencies.jar"  # chemin vers votre jar (ajustez si besoin)


def run_jar(args: list, timeout: int = 10) -> str | None:
    """Run java -jar <JAR_PATH> <args...> and return stdout (str) or None on error."""
    cmd = ["java", "-jar", JAR_PATH] + args
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout, check=False)
        if proc.returncode != 0:
            print(f"jar error rc={proc.returncode} stderr={proc.stderr.strip()}")
            return None
        return proc.stdout.strip()
    except Exception as e:
        print(f"failed to run jar: {e}")
        return None

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
            client_id=message_json["ID"]
            #récupérer les paramètres de la zone
            code=run_jar(["id",client_id])
            msg_a_envoyer={"parametre":code,"status":"ok"}
            message_json=json.dumps(msg_a_envoyer)
            publish(client,f"auth/zone/{client_id}", message_json)
        if (msg.topic=="auth/user"):
            message_json=json.loads(msg.payload.decode())
            jwt=message_json["ownerId"]
            try:    
                response = supabase.auth.get_claims(jwt)
                client_id=response["claims"]["sub"]
                code=run_jar(["identification",client_id])
                msg_a_envoyer={"status":"ok","ownerbase64":code}
                publish(client,f"auth/user/{client_id}", json.dumps(msg_a_envoyer))
            except Exception as e:
                print(e)
    
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

if __name__ == '__main__':
    run()