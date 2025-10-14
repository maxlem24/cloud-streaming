import json
from paho.mqtt import client as mqtt_client
import sqlite3
import psutil
import shutil
import datetime
import uuid

# MQTT Configuration
BROKER = '192.168.2.54'
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
    
def get_system_status():
    """
    Gather system status data: CPU, memory, disk usage and current timestamp
    Returns a dictionary with all the status information
    """
    try:
        # CPU usage percentage
        cpu_usage = psutil.cpu_percent(interval=1)
        
        # Memory usage
        memory = psutil.virtual_memory()
        memory_usage = {
            "total": memory.total,
            "available": memory.available,
            "percent": memory.percent,
            "used": memory.used
        }
        
        # Disk usage
        disk_usage = shutil.disk_usage("C:\\")  # Windows C: drive
        disk_info = {
            "total": disk_usage.total,
            "used": disk_usage.used,
            "free": disk_usage.free,
            "percent": (disk_usage.used / disk_usage.total) * 100
        }
        
        # Current timestamp for latency calculation
        timestamp = datetime.datetime.now().isoformat()
        
        status_data = {
            "edge_id": EDGE_ID,
            "cpu_usage_percent": cpu_usage,
            "memory_usage": memory_usage,
            "disk_usage": disk_info,
            "timestamp": timestamp,
            "status": "ok"
        }
        
        return status_data
        
    except Exception as e:
        return {
            "edge_id": EDGE_ID,
            "error": str(e),
            "timestamp": datetime.datetime.now().isoformat(),
            "status": "error"
        }

def save_status_to_json(status_data, filename="edge_status.json"):
    """
    Save status data to a JSON file
    """
    try:
        with open(filename, 'w') as json_file:
            json.dump(status_data, json_file, indent=4)
        print(f"Status data saved to {filename}")
        return True
    except Exception as e:
        print(f"Error saving to JSON file: {e}")
        return False

def publish_status(client, status_data):
    """
    Publish status data to the correct MQTT topic
    Topic format: video/request/ping/{EDGE_ID}
    """
    topic = f"video/request/ping/{EDGE_ID}"
    message_json = json.dumps(status_data)
    
    try:
        result = client.publish(topic, message_json)
        status = result[0]
        if status == 0:
            print(f"Status data sent to topic `{topic}`")
        else:
            print(f"Failed to send status data to topic {topic}")
        return status == 0
    except Exception as e:
        print(f"Error publishing status: {e}")
        return False
    
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

def db_get_chunk(video_id,chunk_id):
    """Retrieve a streamer by its ID"""
    connection = sqlite3.connect(DB_NAME)
    cursor = connection.cursor()

    cursor.execute('SELECT * FROM chunk WHERE video_id = ? AND id = ?', (video_id, chunk_id))
    chunk = cursor.fetchone()

    connection.close()
    return chunk

def db_export_videos():
    """Export only the videos table as JSON-compatible dicts"""
    connection = sqlite3.connect(DB_NAME)
    cursor = connection.cursor()

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

    connection.close()
    
    json_videos = json.dumps(videos, indent=4)
    
    return json_videos

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
        if (msg.topic == "video/request/ping"):
            # Get current system status
            status_data = get_system_status()
            
            # Save to JSON file
            save_status_to_json(status_data)
            
            # Publish status data to the correct topic
            publish_status(client, status_data)
            
        if (msg.topic==f"live/upload/{EDGE_ID}"):
            message_json=json.loads(msg.payload.decode())
            live_id=message_json["video_id"]
            signature=message_json["signature"]
            #faire des trucs avec la signature (voir avec Maxime)
            end = message_json["end"]
            try:
                streamer_id=message_json["streamer_id"]
            except:
                streamer_id=None
            if(streamer_id):
                "partie 1"
                streamer_nom=message_json["streamer_nom"]
                category=message_json["category"]
                description=message_json["description"]
                thumbnail=message_json["thumbnail"]
                live_nom=message_json["video_nom"]
                if(db_get_streamer_by_id(streamer_id)==None):
                    db_add_streamer(streamer_id, streamer_nom)
                publish(client,f"db/update", json.dumps({"status":"ajout","live":True,"video_id":live_id, "EDGE_ID":EDGE_ID, "streamer_id":streamer_id, "streamer_nom":streamer_nom, "category":category, "description":description, "thumbnail":thumbnail}))
                db_add_video(live_id, live_nom, description, category, True, EDGE_ID, thumbnail, streamer_id)
            else:
                "partie 2"
                if(end == 1):
                    publish(client,f"db/update", json.dumps({"status":"suppression","video_id":live_id, "EDGE_ID":EDGE_ID}))
                    db_remove_video(live_id)
                try:
                    chunk=message_json["chunk"]
                    chunk_part=message_json["chunk_ID"]

                    publish(client,f"live/watch/{EDGE_ID}/{live_id}", json.dumps({"chunk":chunk, "chunk_part":chunk_part}))
                except:
                    chunk=None
                    chunk_part=None
                    #problemes, les chunk ont pas été recu
        #TODO
        # if (msg.topic==f"auth/zone/{EDGE_ID}"):      
  
  
        if(msg.topic==f"video/upload/{EDGE_ID}"):
            # partie edge de send_video et video_received
            message_json=json.loads(msg.payload.decode())
            video_id=message_json["video_id"]
            video_nom=message_json["video_nom"]
            end=message_json["end"]
            try:
                category=message_json["category"]
                thumbnail=message_json["thumbnail"]
                streamer_id=message_json["streamer_id"]
                streamer_nom=message_json["streamer_nom"]
                description=message_json["description"]
            except:
                streamer_id=None
                streamer_nom=None
                category=None
                thumbnail=None
                description=None

            if (streamer_id and description and streamer_nom and category and thumbnail):
                "partie 1"
                ##vérif si streamer existe, dans quel cas on ajoute vidéo et publie, sinon rajoute streamer avant
                streamer_exist=True if db_get_streamer_by_id(streamer_id) else False
                if(not streamer_exist):
                    db_add_streamer(streamer_id, streamer_nom)

                db_add_video(video_id, video_nom, description, category, False, EDGE_ID, thumbnail, streamer_id)
                publish(client,f"video/upload/{EDGE_ID}/{streamer_id}", json.dumps({"video_id":video_id,"EDGE_ID":EDGE_ID}))
            else:
                "partie 2"
                #vérif video existe dans bdd
                chunk=message_json["chunk"]
                chunk_part=message_json["chunk_part"] #combien t ieme chunk
                video_exist=True if db_get_video_by_id(video_id) else False
                if(not video_exist):
                    print(f"erreur, vidéo non trouvée dans bdd : nom={video_nom}, ID={video_id}")
                if(end=="1"):
                    #pas besoin de vérif si on a tous les chunks (le streamer envoie le chunk d'apres que s'il a le ack d'avant)
   

                    verif_chunk=db_add_chunk(video_id, f"{chunk_part}", chunk)
                    if (not verif_chunk):
                        print(f"erreur lors de l'ajout du chunk dans la bdd\n video_id={video_id}, chunk_part={chunk_part}")
                    else: 
                        publish(client,f"db/update", json.dumps({"status":"ajout","live":False,"video_id":video_id,"EDGE_ID":EDGE_ID}))


                else:
                    verif_chunk=db_add_chunk(video_id, f"{chunk_part}", chunk)
                    if (not verif_chunk):

                        print(f"erreur lors de l'ajout du chunk dans la bdd\n video_id={video_id}, chunk_part={chunk_part}")
                    publish(client,f"video/upload/{EDGE_ID}/{streamer_id}", json.dumps({"status":"ok","video_id":video_id,"chunk_part":chunk_part,"EDGE_ID":EDGE_ID}))
        if(msg.topic==f"db/update"):
            message_json=json.loads(msg.payload.decode())
            status=message_json["status"]
            video_id=message_json["video_id"]
            if(status=="ajout"):
                video_nom=message_json["video_nom"]
                category=message_json["category"]
                EDGE2_ID=message_json["EDGE_ID"]
                streamer_id=message_json["streamer_id"]
                streamer_nom=message_json["streamer_nom"]
                live=message_json["live"]
                description=message_json["description"]
                thumbnail=message_json["thumbnail"]
                if(db_get_streamer_by_id(streamer_id)==None):
                    db_add_streamer(streamer_id, streamer_nom)
                if(db_get_video_by_id(video_id)==None):
                    db_add_video(video_id, video_nom, description, category, live, EDGE2_ID, thumbnail, streamer_id)
                else:
                    db_add_video_edges(video_id, EDGE2_ID)
            else:
                if(db_get_video_by_id(video_id)!=None):
                    db_remove_video(video_id)

        if(msg.topic==f"video/liste/{EDGE_ID}"):
            #partie edge de get_videos
            message_json=json.loads(msg.payload.decode())
            client_id=message_json["client_id"]
            videoslist=db_export_videos()
            ### mettre en liste de listes ([video nom 1,id1, category, streamers, edges qui l'ont...]...)
            publish(client,f"video/liste/{EDGE_ID}/{client_id}", json.dumps({"liste_videos":videoslist}))
        if(msg.topic==f"video/watch/{EDGE_ID}"):
            #partie edge de watch_video()
            message_json=json.loads(msg.payload.decode())
            client_id=message_json["client_id"]
            init=message_json["init"]
            video_id=message_json["video_id"]
            
            if(init=="1"):
                publish(client,f"video/watch/{EDGE_ID}/{client_id}", json.dumps({"video_nom":video_nom,"video_id":video_id,"chunk_part":"0","end":"0"}))

            else:
                chunk_part=int(message_json["chunk_part"])+1
                chunk=db_get_chunk(video_id,chunk_part)
                if(not chunk):
                    publish(client,f"video/watch/{EDGE_ID}/{client_id}", json.dumps({"video_nom":video_nom,"video_id":video_id,"end":"1"}))
                publish(client,f"video/watch/{EDGE_ID}/{client_id}", json.dumps({"video_nom":video_nom,"video_id":video_id,"chunk_part":chunk_part,"chunk":chunk,"end":"0"}))


        if (msg.topic=="db"):
            db_content = db_export()
            db_json = json.dumps(db_content)
            message_json=json.loads(msg.payload.decode())
            EDGE2_ID = message_json["ID"]
            print(EDGE2_ID)
            print(message_json)
            if db_content["streamers"]:
                # send db 
                print("Envoie de la DB faite")
                publish(client,f"db/{EDGE2_ID}/",db_json)
            else:
                print("On a pas de DB donc ff on envoie que c'est empty")
                payload = json.dumps({'streamers' : "Empty"})
                publish(client,f"db/{EDGE2_ID}/",payload)
        if (msg.topic == f"db/{EDGE2_ID}/"):
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
        'ID' : EDGE_ID,
    }
    payload_ID = json.dumps(payload)
    publish(client,"auth/zone",payload_ID)
    publish(client,"db",payload_ID)


def run():
    """Main function to run MQTT client"""

    client = connect_mqtt()
    db_setup()  
    premiere_connexion(client)
    subscribe(client, "db")
    subscribe(client, f"db/{EDGE_ID}")
    subscribe(client, f"auth/zone/{EDGE_ID}")
    subscribe(client, "video/request/ping")
    subscribe(client, f"live/upload/{EDGE_ID}")

    subscribe(client, f"video/upload/{EDGE_ID}")

    subscribe(client, "db/update")
    subscribe(client, f"video/liste/{EDGE_ID}")
    subscribe(client, f"video/watch/{EDGE_ID}")
    
    print(f"Edge Cluster ID: {EDGE_ID}")


    client.loop_forever()

    #db_add_streamer("streamer1", "Streamer One")
    #db_add_video("video1", "Video One", "Description of Video One", "Category1", 1, "edge1,edge2", "thumbnail1.jpg", "streamer1")

if __name__ == '__main__':
    run()