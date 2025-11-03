import json
from paho.mqtt import client as mqtt_client
import uuid
from supabase import create_client
import subprocess
import os

# MQTT Configuration
BROKER = os.getenv("MQTT_BROKER", "localhost")
PORT = 1883
EDGE_ID = str(uuid.uuid4())  # Unique ID for this edge cluster
DB_NAME = 'edge_cluster.db'
JAR_PATH = "cloud_signature-1.0-SNAPSHOT-jar-with-dependencies.jar"  # chemin vers votre jar (ajustez si besoin)

# Supabase configuration
SUPABASE_URL = os.getenv("SUPABASE_URL", "")
SUPABASE_KEY = os.getenv("SUPABASE_KEY", "")
supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

def run_jar(args: list, timeout: int = 10) -> str | None:
    """Lancer le JAR avec des arguments spécifiques.

    Args:
        args (list): Les arguments à passer au JAR sous forme de liste.
        timeout (int): Le délai d'attente en secondes (10 par défaut).

    Returns:
        str | None: La sortie standard du JAR sous forme de chaîne, ou None en cas d'échec.
    """
    cmd = ["java", "-jar", JAR_PATH] + args
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout, check=False)
        if proc.returncode != 0:
            print(f"Erreur du jar rc={proc.returncode} stderr={proc.stderr.strip()}")
            return None
        return proc.stdout.strip()
    except Exception as e:
        print(f"Erreur lors de l'exécution du jar: {e}")
        return None

def connect_mqtt() -> mqtt_client.Client:
    """Se connecter au broker MQTT.
    
    Returns:
        mqtt_client.Client: Le client MQTT connecté.
    """
    def on_connect(client, userdata, flags, rc):
        if rc == 0:
            print("Connected to MQTT Broker!")
        else:
            print("Failed to connect, return code %d\n", rc)

    client = mqtt_client.Client()
    client.on_connect = on_connect
    client.on_message = message_handler

    subscribe_to_topics(client)

    client.connect(BROKER, PORT)
    return client

def subscribe_to_topics(client):
    client.subscribe("auth/zone")
    client.subscribe("auth/user")
    print("Tous les topics souscrits")

def publish(client: mqtt_client.Client, topic: str, message: str) -> None:
    """Publier des messages sur un topic MQTT.
    
    Args:
        client (mqtt_client.Client): Le client MQTT.
        topic (str): Le topic sur lequel publier.
        message (str): Le message à publier.
    
    Returns:
        None
    """
    result = client.publish(topic, message)
    status = result[0]
    if status == 0:
        print(f"Message `{message}` envoyé au topic `{topic}`")
    else:
        print(f"Erreur lors de l'envoi du message à {topic}")

def handle_auth_zone(client: mqtt_client.Client, msg) -> None:
    """Traiter l'authentification de la zone.
    
    Args:
        client (mqtt_client.Client): Le client MQTT.
        msg: Le message reçu.
    
    Returns:
        None
    """
    message_json = json.loads(msg.payload.decode())
    client_id = message_json["ID"]
    code = run_jar(["id", client_id])
    msg_a_envoyer = {"parametre": code, "status": "ok"}
    message_json = json.dumps(msg_a_envoyer)
    publish(client, f"auth/zone/{client_id}", message_json)

def handle_auth_user(client: mqtt_client.Client, msg) -> None:
    """Traiter l'authentification de l'utilisateur.
    
    Args:
        client (mqtt_client.Client): Le client MQTT.
        msg: Le message reçu.
    
    Returns:
        None
    """
    message_json = json.loads(msg.payload.decode())
    jwt = message_json["ownerId"]
    
    try:
        response = supabase.auth.get_claims(jwt)
        client_id = response["claims"]["sub"]
        code = run_jar(["identification", client_id])
        msg_a_envoyer = {"status": "ok", "ownerbase64": code}
        publish(client, f"auth/user/{client_id}", json.dumps(msg_a_envoyer))
    except Exception as e:
        print(f"Erreur lors de l'authentification de l'utilisateur: {e}")

def message_handler(client: mqtt_client.Client, userdata, msg) -> None:
    """Gérer les messages MQTT entrants.
    
    Args:
        client (mqtt_client.Client): Le client MQTT.
        userdata: Les données utilisateur.
        msg: Le message reçu.
    
    Returns:
        None
    """
    print(f"Received `{msg.payload.decode()}` from `{msg.topic}` topic")
    
    if msg.topic == "auth/zone":
        handle_auth_zone(client, msg)
    
    elif msg.topic == "auth/user":
        handle_auth_user(client, msg)

def run() -> None:
    """Fonction principale pour exécuter le client MQTT.
    
    Returns:
        None
    """
    client = connect_mqtt()
    print(f"Edge Cluster ID: {EDGE_ID}")
    client.loop_forever()

if __name__ == '__main__':
    run()