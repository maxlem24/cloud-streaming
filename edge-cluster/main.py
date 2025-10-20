import code
import json
import paho.mqtt.client as mqtt_client
import sqlite3
import psutil
import shutil
import datetime
import uuid
import subprocess
import asyncio
import aiosqlite
from concurrent.futures import ThreadPoolExecutor
import time
import sys
import platform
import os

sys.stdout.reconfigure(line_buffering=True)

# MQTT Configuration
BROKER = os.getenv("MQTT_BROKER", "localhost")
PORT = 1883
EDGE_ID = str(uuid.uuid4())  # Unique ID for this edge cluster
DB_NAME = 'edge_cluster.db'
chiffrement_init=False


JAR_PATH = "cloud_signature-1.0-SNAPSHOT-jar-with-dependencies.jar"  # chemin vers votre jar (ajustez si besoin)


async def run_jar(args: list, timeout: int = 10):
    #print(f"lancement du jar,{args}")
    cmd = ["java", "-jar", JAR_PATH] + args
    proc = await asyncio.create_subprocess_exec(
        *cmd,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE
    )
    try:
        stdout, stderr = await asyncio.wait_for(proc.communicate(), timeout=timeout)
        if stderr:
            print(f"Error running jar: {stderr.decode()}")
        print("jar fini")
        stdout_str = stdout.decode().strip()
        if not stdout_str:
            return "X"
        return stdout_str
    except asyncio.TimeoutError:
        proc.kill()
        await proc.wait()
        return "X"

async def db_setup(): 
    """Initialize SQLite database and create tables if they don't exist"""
    async with aiosqlite.connect(DB_NAME) as connection:
        cursor = await connection.cursor()
        
        # Enable foreign key constraints
        await cursor.execute("PRAGMA foreign_keys = ON")
        await cursor.execute('''
            CREATE TABLE IF NOT EXISTS streamer (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
            )
        ''')

        await cursor.execute('''
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

        await cursor.execute('''
            CREATE TABLE IF NOT EXISTS chunk (
                id TEXT PRIMARY KEY,
                video_id TEXT NOT NULL ,
                chunk_nb INTEGER NOT NULL,
                part INTEGER NOT NULL,
                FOREIGN KEY (video_id) REFERENCES video(id) ON DELETE CASCADE
            )
        ''')
        
        await connection.commit()

async def db_add_chunk(chunk_id, video_id, chunk_nb, part):
    """Add a chunk to the database"""
    async with aiosqlite.connect(DB_NAME) as connection:
        cursor = await connection.cursor()
        
        await cursor.execute('''
            INSERT INTO chunk (id, video_id, chunk_nb, part) VALUES (?, ?, ?, ?)
        ''', (chunk_id, video_id, chunk_nb, part))
        
        await connection.commit()
    
async def db_add_video(video_id, title, description, category, live, edges, thumbnail, streamer_id):
    """Add a video to the database"""
    async with aiosqlite.connect(DB_NAME) as connection:
        cursor = await connection.cursor()
        
        await cursor.execute('''
            INSERT INTO video (id, title, description, category, live, edges, thumbnail, streamer_id) 
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ''', (video_id, title, description, category, live, edges, thumbnail, streamer_id))

        await connection.commit()

async def db_add_streamer(streamer_id, name):
    """Add a streamer to the database"""
    async with aiosqlite.connect(DB_NAME) as connection:
        cursor = await connection.cursor()
        
        await cursor.execute('''
            INSERT INTO streamer (id, name) VALUES (?, ?)
        ''', (streamer_id, name))
        
        await connection.commit()
    
async def db_remove_video(video_id):
    """Remove a video and its associated chunks from the database (chunks deleted automatically via CASCADE)"""
    async with aiosqlite.connect(DB_NAME) as connection:
        cursor = await connection.cursor()
        
        await cursor.execute("PRAGMA foreign_keys = ON")
        await cursor.execute('DELETE FROM video WHERE id = ?', (video_id,))
        
        await connection.commit()
    
async def db_remove_streamer(streamer_id):
    """Remove a streamer and their associated videos and chunks from the database (videos and chunks deleted automatically via CASCADE)"""
    async with aiosqlite.connect(DB_NAME) as connection:
        cursor = await connection.cursor()
        
        await cursor.execute("PRAGMA foreign_keys = ON")
        await cursor.execute('DELETE FROM streamer WHERE id = ?', (streamer_id,))
        
        await connection.commit()
    
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
        mount = "C:\\" if platform.system() == "Windows" else "/"
        disk_usage = shutil.disk_usage(mount)
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

async def db_import(body):
    for s in body["streamers"]:
        print(s)
        await db_add_streamer(s["id"], s["name"])
    for v in body["videos"]:
        await db_add_video(v["id"], v["title"], v["description"], v["category"], v["edges"], v["thumbnail"], s["id"])
        
async def db_get_video_by_id(video_id):
    """Retrieve a video by its ID"""
    async with aiosqlite.connect(DB_NAME) as connection:
        cursor = await connection.cursor()
        
        await cursor.execute('SELECT * FROM video WHERE id = ?', (video_id,))
        video = await cursor.fetchone()
        
        return video

async def db_add_video_edges(video_id, edges):
    """Update the edges of a video"""
    async with aiosqlite.connect(DB_NAME) as connection:
        cursor = await connection.cursor()
        
        # get the current edges
        await cursor.execute('SELECT edges FROM video WHERE id = ?', (video_id,))
        result = await cursor.fetchone()
        current_edges = result[0] if result else None
        if current_edges:
            current_edges_list = current_edges.split(',')
            new_edges_list = edges.split(',')
            updated_edges_list = list(set(current_edges_list + new_edges_list))
            edges = ','.join(updated_edges_list)
        
        await cursor.execute('UPDATE video SET edges = ? WHERE id = ?', (edges, video_id))
        
        await connection.commit()
    
async def db_remove_video_edges(video_id, edges):
    """Remove specific edges from a video"""
    async with aiosqlite.connect(DB_NAME) as connection:
        cursor = await connection.cursor()
        
        # get the current edges
        await cursor.execute('SELECT edges FROM video WHERE id = ?', (video_id,))
        result = await cursor.fetchone()
        current_edges = result[0] if result else None
        if current_edges:
            current_edges_list = current_edges.split(',')
            edges_to_remove = edges.split(',')
            updated_edges_list = [edge for edge in current_edges_list if edge not in edges_to_remove]
            edges = ','.join(updated_edges_list)
        
        await cursor.execute('UPDATE video SET edges = ? WHERE id = ?', (edges, video_id))
        
        await connection.commit()

async def db_get_streamer_by_id(streamer_id):
    """Retrieve a streamer by its ID"""
    async with aiosqlite.connect(DB_NAME) as connection:
        cursor = await connection.cursor()
        
        await cursor.execute('SELECT * FROM streamer WHERE id = ?', (streamer_id,))
        streamer = await cursor.fetchone()
        
        return streamer

async def db_get_chunk(video_id, chunk_id):
    """Retrieve a chunk by its ID"""
    async with aiosqlite.connect(DB_NAME) as connection:
        cursor = await connection.cursor()

        await cursor.execute('SELECT * FROM chunk WHERE video_id = ? AND id = ?', (video_id, chunk_id))
        chunk = await cursor.fetchone()

        return chunk

def db_export_videos():
    """Export only the videos table as JSON-compatible dicts"""
    connection = sqlite3.connect(DB_NAME)
    cursor = connection.cursor()

    # Videos
    cursor.execute('SELECT id, title, description, category, live, edges, thumbnail, streamer_id, created_at FROM video')
    videos = [{"id": row[0],"title": row[1],"description": row[2],"category": row[3],"live": row[4],"edges": row[5],"thumbnail": row[6],"streamer_id": row[7],"created_at": row[8]}for row in cursor.fetchall()]

    connection.close()
    
    json_videos = json.dumps(videos)
    
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

# Global executor for blocking operations
executor = ThreadPoolExecutor(max_workers=5)

# Global event loop reference
loop = None

async def connect_mqtt():
    """Connect to MQTT broker"""
    def on_connect(client, userdata, flags, rc):
        if rc == 0:
            print("Connected to MQTT Broker!")
            #fonctions subscribe mises ici, car quand le code paho est surchargé, il relance la connection, et il faut resubscribe du coup (on aurait et devrait mettre un on_disconnect() aussi pour handle correctement et proprement)
            client.subscribe("db")
            client.subscribe(f"db/{EDGE_ID}")
            client.subscribe(f"auth/zone/{EDGE_ID}")
            client.subscribe("video/request/ping")
            client.subscribe(f"live/upload/{EDGE_ID}")
            client.subscribe(f"video/upload/{EDGE_ID}")
            client.subscribe("db/update")
            client.subscribe(f"video/liste/{EDGE_ID}")
            client.subscribe(f"video/watch/{EDGE_ID}")
            print("Subscribed to all topics")
        else:
            print("Failed to connect, return code %d\n", rc)

    client = mqtt_client.Client()
    client.on_connect = on_connect
    client.on_message = on_message
    
    # Connect in a thread to avoid blocking
    await loop.run_in_executor(executor, client.connect, BROKER, PORT)
    client.loop_start()
    return client

def publish(client, topic, message):
    """Publish messages to MQTT topic"""
    result = client.publish(topic, message)
    status = result[0]
    if status == 0:
        print(f"Send `{message[0:100]}` to topic `{topic[0:100]}`")
    else:
        print(f"Failed to send message to topic {topic} : {result}")

def on_message(client, userdata, msg):
    """Handle incoming MQTT messages by scheduling async handler"""
    global loop
    if loop:
        asyncio.run_coroutine_threadsafe(handle_message(client, msg), loop)

async def handle_message(client, msg):
    """Async handler for MQTT messages"""
    global chiffrement_init
    print(f"Received `{msg.payload.decode()[0:100]}` from `{msg.topic[0:100]}` topic")
    
    if (msg.topic == "video/request/ping"):
        CLIENT_ID=json.loads(msg.payload.decode())["client_id"]
        # Get current system status
        status_data = get_system_status()
        
        # Save to JSON file
        save_status_to_json(status_data)
        
        # Publish status data to the correct topic
        publish(client, f"video/request/ping/{CLIENT_ID}", json.dumps(status_data))

    if(msg.topic==f"video/liste/{EDGE_ID}"):
        #partie edge de get_videos
        message_json=json.loads(msg.payload.decode())
        client_id=message_json["client_id"]
        videoslist = await loop.run_in_executor(executor, db_export_videos)
        publish(client,f"video/liste/{EDGE_ID}/{client_id}", videoslist)
        
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
            chunk=await db_get_chunk(video_id,chunk_part)
            if(not chunk):
                publish(client,f"video/watch/{EDGE_ID}/{client_id}", json.dumps({"video_nom":video_nom,"video_id":video_id,"end":"1"}))
            publish(client,f"video/watch/{EDGE_ID}/{client_id}", json.dumps({"video_nom":video_nom,"video_id":video_id,"chunk_part":chunk_part,"chunk":chunk,"end":"0"}))

    if (msg.topic==f"live/upload/{EDGE_ID}"):
        print("paquet reçuuuuuuuuuuuuuuuuuuuuuuuuu")
        message_json=json.loads(msg.payload.decode())
        live_id=message_json["video_id"]
        end = message_json["end"]
        try:
            streamer_id=message_json["streamer_id"]
        except Exception as e:
            streamer_id=None
        if(streamer_id):
            print("partie 1")
            streamer_nom=message_json["streamer_nom"]
            category=message_json["category"]
            description=message_json["description"]
            thumbnail=message_json["thumbnail"]
            live_nom=message_json["video_nom"]
            if(await db_get_streamer_by_id(streamer_id)==None):
                await db_add_streamer(streamer_id, streamer_nom)
                publish(client,f"db/update", json.dumps({"status":"ajout","live":True,"video_id":live_id,"video_nom":live_nom,"category":category,"streamer_id":streamer_id,"streamer_nom":streamer_nom,"description":description,"thumbnail":thumbnail,"EDGE_ID":EDGE_ID}))
            await db_add_video(live_id, live_nom, description, category, True, EDGE_ID, thumbnail, streamer_id)
        else:
            print("partie 2")
            if(end == 1 or end=="1"):
                publish(client,f"db/update", json.dumps({"status":"suppression","video_id":live_id, "EDGE_ID":EDGE_ID}))
                await db_remove_video(live_id)
                print("suppression de la vidéo")
            try:
                chunk=message_json["chunk"]
                chunk_part=message_json["chunk_part"]
                print("chunk reçu:",chunk_part)
                if(chiffrement_init):
                    print("lancement préjar : chunk_part=",chunk_part)
                    verif=await run_jar(["fog","verify",chunk])
                    print(f"verif chunk live: {verif}")
                    if (verif=="nonono"):
                        print("chunk corrompu, on le rejette")
                    else:
                        publish(client,f"live/watch/{EDGE_ID}/{live_id}", json.dumps({"chunk":chunk, "chunk_part":chunk_part}))
                        #print(chunk)
                        #exit()
                else:
                    print("erreur chiffrement pas initialisé, on peut pas recevoir de vidéo")
            except Exception as e:
                chunk=None
                chunk_part=None
                #problemes, les chunk ont pas été recu
                
    if (msg.topic==f"auth/zone/{EDGE_ID}"):      
        message_json=json.loads(msg.payload.decode())
        parametre=message_json["parametre"]
        await run_jar(["fog","init",EDGE_ID,parametre])
        chiffrement_init=True
        print("init du chiffrement fait")

    if(msg.topic==f"video/upload/{EDGE_ID}"):
        # partie edge de send_video et video_received
        message_json=json.loads(msg.payload.decode())
        video_id=message_json["video_id"]
        end=message_json["end"]
        try:
            category=message_json["category"]
            thumbnail=message_json["thumbnail"]
            streamer_id=message_json["streamer_id"]
            streamer_nom=message_json["streamer_nom"]
            description=message_json["description"]
            video_nom=message_json["video_nom"]
        except Exception as e:
            streamer_id=None
            streamer_nom=None
            category=None
            thumbnail=None
            description=None
            video_nom=None

        if (streamer_id and description and streamer_nom and category and thumbnail):
            print("partie 1")
            ##vérif si streamer existe, dans quel cas on ajoute vidéo et publie, sinon rajoute streamer avant
            streamer_exist=True if await db_get_streamer_by_id(streamer_id) else False
            if(not streamer_exist):
                await db_add_streamer(streamer_id, streamer_nom)

            await db_add_video(video_id, video_nom, description, category, False, EDGE_ID, thumbnail, streamer_id)
            publish(client,f"video/upload/{EDGE_ID}/{streamer_id}", json.dumps({"video_id":video_id,"EDGE_ID":EDGE_ID}))
        else:
            print("partie 2")
            #vérif video existe dans bdd
            chunk=message_json["chunk"]
            chunk_part=message_json["chunk_part"] #combien t ieme chunk
            video_exist=True if await db_get_video_by_id(video_id) else False
            if(not video_exist):
                print(f"erreur, vidéo non trouvée dans bdd : nom={video_nom}, ID={video_id}")
            if(end=="1"):
                #pas besoin de vérif si on a tous les chunks (le streamer envoie le chunk d'apres que s'il a le ack d'avant)
                if (chiffrement_init):
                    verif1=await run_jar(["fog","verify",chunk])
                    await db_add_chunk(str(uuid.uuid4()),video_id, chunk_part, chunk)
                    verif2=True  # db_add_chunk doesn't return a value in async version
                    if (not verif2 or verif1=="X"):
                        print(f"erreur lors de l'ajout du chunk dans la bdd\n video_id={video_id}, chunk_part={chunk_part}\n ou chunk corrompu (signature ayant raté la vérification)")
                    else: 
                        publish(client,f"db/update", json.dumps({"status":"ajout","live":False,"video_id":video_id,"video_nom":video_nom,"category":category,"streamer_id":streamer_id,"streamer_nom":streamer_nom,"description":description,"thumbnail":thumbnail,"EDGE_ID":EDGE_ID}))
                else:
                    print("erreur chiffrement pas initialisé, on peut pas recevoir de vidéo")
            else:
                await db_add_chunk(str(uuid.uuid4()),video_id, chunk_part, chunk)
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
            if(await db_get_streamer_by_id(streamer_id)==None):
                await db_add_streamer(streamer_id, streamer_nom)
            if(await db_get_video_by_id(video_id)==None):
                await db_add_video(video_id, video_nom, description, category, live, EDGE2_ID, thumbnail, streamer_id)
            else:
                await db_add_video_edges(video_id, EDGE2_ID)
        else:
            if(await db_get_video_by_id(video_id)!=None):
                await db_remove_video(video_id)

    if (msg.topic=="db"):
        db_content = await loop.run_in_executor(executor, db_export)
        db_json = json.dumps(db_content)
        message_json=json.loads(msg.payload.decode())
        EDGE2_ID = message_json["ID"]
        print(EDGE2_ID)
        print(message_json)
        if db_content["streamers"]:
            # send db 
            print("Envoie de la DB faite")
            publish(client,f"db/{EDGE2_ID}",db_json)
        else:
            print("On a pas de DB donc ff on envoie que c'est empty")
            payload = json.dumps({'streamers' : "Empty"})
            publish(client,f"db/{EDGE2_ID}",payload)
            
    if (msg.topic == f"db/{EDGE_ID}"):
        message_json=json.loads(msg.payload.decode())
        if message_json['streamers'] == "Empty":
            print("On ne fait rien, car on a reçu une BDD vide")
        else:
            await db_import(message_json)

def premiere_connexion(client):
    # On envoie notre ID au serveur.
    payload = {
        'ID' : EDGE_ID,
    }
    payload_ID = json.dumps(payload)
    publish(client,"auth/zone",payload_ID)

    publish(client,"db",payload_ID)



async def run():
    """Main async function to run MQTT client"""
    global loop
    loop = asyncio.get_running_loop()
    
    await db_setup()
    client = await connect_mqtt()
    premiere_connexion(client)
    print(f"Edge Cluster ID: {EDGE_ID}")
    
    # Keep the event loop running
    try:
        while True:
            await asyncio.sleep(1)
    except KeyboardInterrupt:
        print("Shutting down...")
        client.loop_stop()
        client.disconnect()

if __name__ == '__main__':
    asyncio.run(run())