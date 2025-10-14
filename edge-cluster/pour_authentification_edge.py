if __name__ == '__main__':
    run()

import json
from paho.mqtt import client as mqtt_client
import sqlite3
import psutil
import shutil
import datetime
import uuid

# MQTT Configuration
BROKER = '10.246.146.52'
PORT = 1883
EDGE_ID = str(uuid.uuid4())  # Unique ID for this edge cluster
TOPIC_ID = f"auth/user/{EDGE_ID}/"
DB_NAME = 'edge_cluster.db'


def db_setup(): 
    """Initialize SQLite database and create tables if they don't exist"""
    connection = sqlite3.connect(DB_NAME)
    cursor = connection.cursor()
    
    # Enable foreign key constraints
    cursor.execute("PRAGMA foreign_keys = ON")
    
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS streamer (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
        )
    ''')

    cursor.execute('''
        CREATE TABLE IF NOT EXISTS video (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            description TEXT,
            category TEXT NOT NULL,
            live BOOLEAN NOT NULL DEFAULT 0,
            edges TEXT NOT NULL,
            thumbnail TEXT NOT NULL,
            streamer_id TEXT NOT NULL,
            created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (streamer_id) REFERENCES streamer(id) ON DELETE CASCADE
        )
    ''')

    cursor.execute('''
        CREATE TABLE IF NOT EXISTS chunk (
            id TEXT PRIMARY KEY,
            video_id TEXT NOT NULL ,
            part INTEGER NOT NULL,
            FOREIGN KEY (video_id) REFERENCES video(id) ON DELETE CASCADE
        )
    ''')
    
    connection.commit()
    connection.close()

def db_add_streamer(streamer_id, name):
    """Add a streamer to the database"""
    connection = sqlite3.connect(DB_NAME)
    cursor = connection.cursor()
    
    cursor.execute('''
        INSERT INTO streamer (id, name) VALUES (?, ?)
    ''', (streamer_id, name))
    
    connection.commit()
    connection.close()
    
def db_remove_video(video_id):
    """Remove a video and its associated chunks from the database (chunks deleted automatically via CASCADE)"""
    connection = sqlite3.connect(DB_NAME)
    cursor = connection.cursor()
    
    cursor.execute("PRAGMA foreign_keys = ON")
    cursor.execute('DELETE FROM video WHERE id = ?', (video_id,))
    
    connection.commit()
    connection.close()


def db_add_video_edges(video_id, edges):
    """Update the edges of a video"""
    connection = sqlite3.connect(DB_NAME)
    cursor = connection.cursor()
    
    # get the current edges
    cursor.execute('SELECT edges FROM video WHERE id = ?', (video_id,))
    current_edges = cursor.fetchone()[0]
    if current_edges:
        current_edges_list = current_edges.split(',')
        new_edges_list = edges.split(',')
        updated_edges_list = list(set(current_edges_list + new_edges_list))
        edges = ','.join(updated_edges_list)
    
    cursor.execute('UPDATE video SET edges = ? WHERE id = ?', (edges, video_id))
    
    connection.commit()
    connection.close()
    
def db_remove_video_edges(video_id, edges):
    """Remove specific edges from a video"""
    connection = sqlite3.connect(DB_NAME)
    cursor = connection.cursor()
    
    # get the current edges
    cursor.execute('SELECT edges FROM video WHERE id = ?', (video_id,))
    current_edges = cursor.fetchone()[0]
    if current_edges:
        current_edges_list = current_edges.split(',')
        edges_to_remove = edges.split(',')
        updated_edges_list = [edge for edge in current_edges_list if edge not in edges_to_remove]
        edges = ','.join(updated_edges_list)
    
    cursor.execute('UPDATE video SET edges = ? WHERE id = ?', (edges, video_id))
    
    connection.commit()
    connection.close()


def db_get_chunk(video_id,chunk_id):
    """Retrieve a streamer by its ID"""
    connection = sqlite3.connect(DB_NAME)
    cursor = connection.cursor()

    cursor.execute('SELECT * FROM chunk WHERE video_id = ? AND id = ?', (video_id, chunk_id))
    chunk = cursor.fetchone()

    connection.close()
    return chunk


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
            user=message_json["user"]
            password=message_json["password"]
            ID=message_json["ID"]
            #VERIF niveau bdd le user
            verif=True #a modifier!
            if verif:
                msg_a_envoyer={"status":"ok"}
            else:
                msg_a_envoyer={"status":"notok"}
            publish(client,f"auth/user/{ID}", json.dumps(msg_a_envoyer))
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
