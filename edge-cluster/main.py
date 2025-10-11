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
CLIENT_ID = str(uuid.uuid4())
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
            id_live=message_json["id_live"]
            signature=message_json["signature"]
            #faire des trucs avec la signature (voir avec Maxime)
            end = message_json["end"]
            if(end == 1):
                publish(client,f"live/db/update", json.dumps({"status":"suppression","type":"live","id_live":id_live, "EDGE_ID":EDGE_ID}))
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
                    publish(client,f"live/watch/{EDGE_ID}/{id_live}", json.dumps({"chunk":chunk, "chunk_part":chunk_part}))
                except:
                    chunk=None
                    chunk_part=None
                    #problemes, les chunk ont pas été recu
        #TODO
        # if (msg.topic==f"auth/zone/{EDGE_ID}"):      
  
  
        if(msg.topic==f"video/upload/{EDGE_ID}"):
            # partie edge de send_video et video_received
            message_json=json.loads(msg.payload.decode())
            video_ID=message_json["video_ID"]
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
                db_add_video(video_ID, video_nom, description, category, 0, EDGE_ID, thumbnail, streamer_id)
                publish(client,f"video/upload/{EDGE_ID}/{video_ID}", json.dumps({"video_ID":video_ID,"EDGE_ID":EDGE_ID}))
            else:
                "partie 2"
                
                chunk=message_json["chunk"]
                chunk_part=message_json["chunk_part"] #combien t ieme chunk
                video_exist=True if db_get_video_by_id(video_ID) else False
                if(not video_exist):
                    print("erreur, vidéo non trouvée dans bdd : ID={video_ID}")
                if(end=="1"):
                    #pas besoin de vérif si on a tous les chunks (le streamer envoie le chunk d'apres que s'il a le ack d'avant)
                    verif_chunk=db_add_chunk(video_ID, f"{chunk_part}", chunk)
                    if (not verif_chunk):
                        print(f"erreur lors de l'ajout du chunk dans la bdd\n video_ID={video_ID}, chunk_part={chunk_part}")
                    else: 
                        publish(client,f"db/update", json.dumps({"status":"ajout","type":"video","video_ID":video_ID,"EDGE_ID":CLIENT_ID}))
                    
                else:
                    verif_chunk=db_add_chunk(video_ID, f"{chunk_part}", chunk)
                    if (not verif_chunk):
                        print(f"erreur lors de l'ajout du chunk dans la bdd\n video_ID={video_ID}, chunk_part={chunk_part}")
                    publish(client,f"video/upload/{EDGE_ID}/{streamer_id}", json.dumps({"video_ID":video_ID,"chunk_part":chunk_part,"EDGE_ID":EDGE_ID}))
        if(msg.topic==f"db/update"):
            message_json=json.loads(msg.payload.decode())
            video_ID=message_json["video_ID"]
            video_nom=message_json["video_nom"]
            category=message_json["category"]
            EDGE2_ID=message_json["EDGE2_ID"]
            status=message_json["status"]
            if(status=="ajout" and message_json["type"]=="video"):
                db_add_video_edges(video_ID, EDGE2_ID)
            elif(status=="suppression" and message_json["type"]=="video"):
                db_remove_video_edges(video_ID, EDGE2_ID)
        if(msg.topic==f"video/liste/{EDGE_ID}"):
            #partie edge de get_videos
            message_json=json.loads(msg.payload.decode())
            client_ID=message_json["client_ID"]
            videoslist=db_export_videos()
            ### mettre en liste de listes ([video nom 1,id1, category, streamers, edges qui l'ont...]...)
            publish(client,f"video/liste/{EDGE_ID}/{client_ID}", json.dumps({"liste_videos":videoslist}))
        if(msg.topic==f"video/watch/{EDGE_ID}"):
            #partie edge de watch_video()
            message_json=json.loads(msg.payload.decode())
            client_ID=message_json["client_ID"]
            init=message_json["init"]
            video_ID=message_json["video_ID"]
            if(init=="1"):
                publish(client,f"video/watch/{EDGE_ID}/{client_ID}", json.dumps({"video_nom":video_nom,"video_ID":video_ID,"chunk_part":"0","end":"0"}))
            else:
                chunk_part=int(message_json["chunk_part"])+1
                chunk=db_get_chunk(video_ID,chunk_part)
                if(not chunk):
                    publish(client,f"video/watch/{EDGE_ID}/{client_ID}", json.dumps({"video_nom":video_nom,"video_ID":video_ID,"end":"1"}))
                publish(client,f"video/watch/{EDGE_ID}/{client_ID}", json.dumps({"video_nom":video_nom,"video_ID":video_ID,"chunk_part":chunk_part,"chunk":chunk,"end":"0"}))


        if (msg.topic=="db/"):
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
    publish(client,"auth/zone/",payload_ID)
    publish(client,"db/",payload_ID)


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

    subscribe(client, "video/upload/{EDGE_ID}")

    subscribe(client, "db/update")
    subscribe(client, f"video/liste/{EDGE_ID}")
    subscribe(client, f"video/watch/{EDGE_ID}")
    
    print(f"Edge Cluster ID: {EDGE_ID}")


    client.loop_forever()

    #db_add_streamer("streamer1", "Streamer One")
    #db_add_video("video1", "Video One", "Description of Video One", "Category1", 1, "edge1,edge2", "thumbnail1.jpg", "streamer1")

if __name__ == '__main__':
    run()