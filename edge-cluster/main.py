import json
import random
import time
from paho.mqtt import client as mqtt_client
import sqlite3

# MQTT Configuration
BROKER = 'localhost'
PORT = 1883
CLIENT_ID = f'python-mqtt-{random.randint(0, 1000)}'
TOPIC_DB = f"db/"
TOPIC_DB_ID = f"db/{CLIENT_ID}/"
TOPIC_ID = f"auth/user/{CLIENT_ID}/"
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
    
def db_add_chunk(video_id, chunk_id, part):
    """Add a chunk to the database"""
    connection = sqlite3.connect(DB_NAME)
    cursor = connection.cursor()
    
    cursor.execute('''
        INSERT INTO chunk (id, video_id, part) VALUES (?, ?, ?)
    ''', (chunk_id, video_id, part))
    
    connection.commit()
    connection.close()
    
def db_add_video(video_id, title, description, category, live, edges, thumbnail, streamer_id):
    """Add a video to the database"""
    connection = sqlite3.connect(DB_NAME)
    cursor = connection.cursor()
    
    cursor.execute('''
        INSERT INTO video (id, title, description, category, live, edges, thumbnail, streamer_id) 
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ''', (video_id, title, description, category, live, edges, thumbnail, streamer_id))

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
    
def db_remove_streamer(streamer_id):
    """Remove a streamer and their associated videos and chunks from the database (videos and chunks deleted automatically via CASCADE)"""
    connection = sqlite3.connect(DB_NAME)
    cursor = connection.cursor()
    
    cursor.execute("PRAGMA foreign_keys = ON")
    cursor.execute('DELETE FROM streamer WHERE id = ?', (streamer_id,))
    
    connection.commit()
    connection.close()
    
def db_import(body) :
    for s in body["streamers"]:
        print(s)
        db_add_streamer(s["id"], s["name"])
    for v in body["videos"] :
        db_add_video(v["id"], v["title"], v["description"], v["category"], v["edges"], v["thumbnail"], s["id"])
        
def db_get_video_by_id(video_id):
    """Retrieve a video by its ID"""
    connection = sqlite3.connect(DB_NAME)
    cursor = connection.cursor()
    
    cursor.execute('SELECT * FROM video WHERE id = ?', (video_id,))
    video = cursor.fetchone()
    
    connection.close()
    return video

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

def db_get_streamer_by_id(streamer_id):
    """Retrieve a streamer by its ID"""
    connection = sqlite3.connect(DB_NAME)
    cursor = connection.cursor()
    
    cursor.execute('SELECT * FROM streamer WHERE id = ?', (streamer_id,))
    streamer = cursor.fetchone()
    
    connection.close()
    return streamer

def db_export():
    """Export the entire database content as JSON-compatible dicts"""
    connection = sqlite3.connect(DB_NAME)
    cursor = connection.cursor()

    # Streamers
    cursor.execute('SELECT id, name, created_at FROM streamer')
    streamers = [
        {"id": row[0], "name": row[1], "created_at": row[2]}
        for row in cursor.fetchall()
    ]

    # Videos
    cursor.execute('SELECT id, title, description, category, live, edges, thumbnail, streamer_id, created_at FROM video')
    videos = [
        {
            "id": row[0],
            "title": row[1],
            "description": row[2],
            "category": row[3],
            "live": row[4],
            "edges": row[5],
            "thumbnail": row[6],
            "streamer_id": row[7],
            "created_at": row[8]
        }
        for row in cursor.fetchall()
    ]

    # Chunks
    cursor.execute('SELECT id, video_id, part FROM chunk')
    chunks = [
        {"id": row[0], "video_id": row[1], "part": row[2]}
        for row in cursor.fetchall()
    ]

    db_content = {
        "streamers": streamers,
        "videos": videos,
        "chunks": chunks
    }

    connection.close()
    return db_content
        
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
        time.sleep(1)
        if (msg.topic=="auth/user/"):
            message_json=json.loads(msg.payload.decode())
            user=message_json["user"]
            password=message_json["password"]
            ID=message_json["ID"]
        if (msg.topic==f"auth/user/{CLIENT_ID}/"):
            print("Message reçu depuis auth/user/ID/")
        if (msg.topic=="db/"):
            db_content = db_export()
            db_json = json.dumps(db_content)
            message_json=json.loads(msg.payload.decode())
            ID = message_json["ID"]
            print(ID)
            print(message_json)
            if db_content["streamers"]:
                # send db 
                print("Envoie de la DB faite")
                publish(client,f"db/{ID}/",db_json)
            else:
                print("On a pas de DB donc ff on envoie que c'est empty")
                payload = json.dumps({'streamers' : "Empty"})
                publish(client,f"db/{ID}/",payload)
        if (msg.topic == f"db/{CLIENT_ID}/"):
            print("AAAAAAAAAAAAAAAAAAAAA")
            message_json=json.loads(msg.payload.decode())
            if message_json['streamers'] == "Empty":
                print("On ne fait rien, car on a reçu une BDD vide")
            else:
                db_import(message_json)
    client.subscribe(topic)
    print(f"On est souscrit au topic {topic}")
    client.on_message = on_message

def premiere_connexion(client):
    # On envoie notre ID au serveur.
    payload = {
        'ID' : CLIENT_ID,
    }
    payload_ID = json.dumps(payload)
    publish(client,"auth/user/",payload_ID)
    publish(client,"db/",payload_ID)


def run():
    """Main function to run MQTT client"""

    client = connect_mqtt()
    db_setup()  
    premiere_connexion(client)
    subscribe(client, TOPIC_DB)
    subscribe(client, TOPIC_DB_ID)
    subscribe(client,TOPIC_ID)      

    # db_add_streamer("streamer22", "Streamer One")
    client.loop_forever()
    # db_add_video("video1", "Video One", "Description of Video One", "Category1", 1, "edge1,edge2", "thumbnail1.jpg", "streamer1")


    print(db_export())

if __name__ == '__main__':
    run()