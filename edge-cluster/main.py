import json
import paho.mqtt.client as mqtt_client
import sqlite3
import psutil
import shutil
import datetime
import uuid
import asyncio
import aiosqlite
from concurrent.futures import ThreadPoolExecutor
import sys
import platform
import os

# POUR AFFICHAGE SUR DOCKER
sys.stdout.reconfigure(line_buffering=True)

# ASYNC
executor = ThreadPoolExecutor(max_workers=5)
loop = None

# MQTT Configuration
BROKER = os.getenv("MQTT_BROKER", "localhost")
PORT = 1883
EDGE_ID = str(uuid.uuid4())  # Unique ID for this edge cluster
DB_NAME = 'edge_cluster.db'
JAR_PATH = "cloud_signature-1.0-SNAPSHOT-jar-with-dependencies.jar" 
chiffrement_init=False

async def run_jar(args: list, timeout: int = 10) -> str:
    """Lancer le JAR avec des arguments spécifiques.

    Args:
        args (list): Les arguments à passer au JAR sous forme de liste.
        timeout (int): Le délai d'attente en secondes (10 par défaut).

    Returns:
        str | None: La sortie standard du JAR sous forme de chaîne, ou un message d'erreur en cas d'échec.
    """

    cmd = ["java", "-jar", JAR_PATH] + args
    proc = await asyncio.create_subprocess_exec(
        *cmd,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE
    )
    try:
        stdout, stderr = await asyncio.wait_for(proc.communicate(), timeout=timeout)
        if stderr:
            print(f"Erreur du jar: {stderr.decode()}")
        print("Jar exécuté avec succès")
        stdout_str = stdout.decode().strip()
        if not stdout_str:
            return "Erreur: sortie vide du jar"
        return stdout_str
    except asyncio.TimeoutError:
        proc.kill()
        await proc.wait()
        return "Erreur: timeout"
    except Exception as e:
        return f"Échec de l'exécution du jar: {e}"

async def db_setup() -> None:
    """Initialiser la base de données SQLite et créer les tables si elles n'existent pas.
    
    Returns:
        None
    """
    async with aiosqlite.connect(DB_NAME) as connection:
        cursor = await connection.cursor()
        
        # Activer les clés étrangères
        await cursor.execute("PRAGMA foreign_keys = ON")
        
        # Créer table "streamer"
        await cursor.execute('''
            CREATE TABLE IF NOT EXISTS streamer (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
            )
        ''')

        # Créer table "video"
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

        # Créer table "chunk"
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

async def db_add_chunk(chunk_id: str, video_id: str, chunk_nb: int, part: str) -> None:
    """Ajoute un chunk à la base de données.
    
    Args:
        chunk_id (str): L'ID unique du chunk.
        video_id (str): L'ID de la vidéo associée.
        chunk_nb (int): Le numéro du chunk.
        part (str): Le contenu du chunk.    
    """
    async with aiosqlite.connect(DB_NAME) as connection:
        cursor = await connection.cursor()
        
        await cursor.execute('''
            INSERT INTO chunk (id, video_id, chunk_nb, part) VALUES (?, ?, ?, ?)
        ''', (chunk_id, video_id, chunk_nb, part))
        
        await connection.commit()

async def db_add_video(video_id: str, title: str, description: str, category: str, live: bool, edges: str, thumbnail: str, streamer_id: str) -> None:
    """Ajouter une vidéo à la base de données
    
    Args:
        video_id (str): L'ID unique de la vidéo.
        title (str): Le titre de la vidéo.
        description (str): La description de la vidéo.
        category (str): La catégorie de la vidéo.
        live (bool): Indique si c'est un live ou non.
        edges (str): Les ID des edges clusters contenant la vidéo séparés par des virgules.
        thumbnail (str): Le chemin vers la miniature de la vidéo.
        streamer_id (str): L'ID du streamer associé à la vidéo.
    
    """
    async with aiosqlite.connect(DB_NAME) as connection:
        cursor = await connection.cursor()
        
        await cursor.execute('''
            INSERT INTO video (id, title, description, category, live, edges, thumbnail, streamer_id) 
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ''', (video_id, title, description, category, live, edges, thumbnail, streamer_id))

        await connection.commit()

async def db_add_streamer(streamer_id: str, name: str) -> None:
    """Ajouter un streamer à la base de données
    
    Args:
        streamer_id (str): L'ID unique du streamer.
        name (str): Le nom du streamer.

    """
    async with aiosqlite.connect(DB_NAME) as connection:
        cursor = await connection.cursor()
        
        await cursor.execute('''
            INSERT INTO streamer (id, name) VALUES (?, ?)
        ''', (streamer_id, name))
        
        await connection.commit()
    
async def db_remove_video(video_id: str) -> None:
    """Supprimer une vidéo et ses chunks associés de la base de données (chunks supprimés automatiquement via CASCADE).
    
    Args:
        video_id (str): L'ID unique de la vidéo à supprimer.
    
    Returns:
        None
    """
    async with aiosqlite.connect(DB_NAME) as connection:
        cursor = await connection.cursor()
        
        await cursor.execute("PRAGMA foreign_keys = ON")
        await cursor.execute('DELETE FROM video WHERE id = ?', (video_id,))
        
        await connection.commit()
    
async def db_remove_streamer(streamer_id: str) -> None:
    """Supprimer un streamer et ses vidéos et chunks associés de la base de données (vidéos et chunks supprimés automatiquement via CASCADE).
    
    Args:
        streamer_id (str): L'ID unique du streamer à supprimer.
    
    Returns:
        None
    """
    async with aiosqlite.connect(DB_NAME) as connection:
        cursor = await connection.cursor()
        
        await cursor.execute("PRAGMA foreign_keys = ON")
        await cursor.execute('DELETE FROM streamer WHERE id = ?', (streamer_id,))
        
        await connection.commit()
    
def get_system_status() -> dict:
    """Collecter les données d'état du système : CPU, mémoire, utilisation du disque et horodatage actuel.
    
    Returns:
        dict: Un dictionnaire contenant toutes les informations d'état du système.
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

def save_status_to_json(status_data: dict, filename: str = "edge_status.json") -> bool:
    """Sauvegarder les données d'état dans un fichier JSON.
    
    Args:
        status_data (dict): Les données d'état à sauvegarder.
        filename (str): Le nom du fichier JSON (par défaut: "edge_status.json").
    
    Returns:
        bool: True si la sauvegarde a réussi, False sinon.
    """
    try:
        with open(filename, 'w') as json_file:
            json.dump(status_data, json_file, indent=4)
        print(f"Fichier JSON sauvegardé : {filename}")
        return True
    
    except Exception as e:
        print(f"Erreur lors de la sauvegarde du fichier JSON : {e}")
        return False

async def db_import(body: dict) -> None:
    """Importer les données de streamers et vidéos dans la base de données.
    
    Args:
        body (dict): Un dictionnaire contenant les listes 'streamers' et 'videos'.
    
    Returns:
        None
    """
    for s in body["streamers"]:
        await db_add_streamer(s["id"], s["name"])
    for v in body["videos"]:
        await db_add_video(v["id"], v["title"], v["description"], v["category"], v["edges"], v["thumbnail"], s["id"])
        
async def db_get_video_by_id(video_id: str) -> tuple | None:
    """Récupérer une vidéo par son ID.
    
    Args:
        video_id (str): L'ID unique de la vidéo.
    
    Returns:
        tuple | None: Un tuple contenant les données de la vidéo, ou None si non trouvée.
    """
    async with aiosqlite.connect(DB_NAME) as connection:
        cursor = await connection.cursor()
        
        await cursor.execute('SELECT * FROM video WHERE id = ?', (video_id,))
        video = await cursor.fetchone()
        
        return video

async def db_add_video_edges(video_id: str, edges: str) -> None:
    """Mettre à jour les edges d'une vidéo en ajoutant de nouveaux edges.
    
    Args:
        video_id (str): L'ID unique de la vidéo.
        edges (str): Les nouveaux edges à ajouter (séparés par des virgules).
    
    Returns:
        None
    """
    async with aiosqlite.connect(DB_NAME) as connection:
        cursor = await connection.cursor()
        
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
    
async def db_remove_video_edges(video_id: str, edges: str) -> None:
    """Supprimer des edges spécifiques d'une vidéo.
    
    Args:
        video_id (str): L'ID unique de la vidéo.
        edges (str): Les edges à supprimer (séparés par des virgules).
    
    Returns:
        None
    """
    async with aiosqlite.connect(DB_NAME) as connection:
        cursor = await connection.cursor()
        
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

async def db_get_streamer_by_id(streamer_id: str) -> tuple | None:
    """Récupérer un streamer par son ID.
    
    Args:
        streamer_id (str): L'ID unique du streamer.
    
    Returns:
        tuple | None: Un tuple contenant les données du streamer, ou None si non trouvé.
    """
    async with aiosqlite.connect(DB_NAME) as connection:
        cursor = await connection.cursor()
        
        await cursor.execute('SELECT * FROM streamer WHERE id = ?', (streamer_id,))
        streamer = await cursor.fetchone()
        
        return streamer

async def db_get_chunk(video_id: str, chunk_id: str) -> tuple | None:
    """Récupérer un chunk par son ID.
    
    Args:
        video_id (str): L'ID de la vidéo associée.
        chunk_id (str): L'ID unique du chunk.
    
    Returns:
        tuple | None: Un tuple contenant les données du chunk, ou None si non trouvé.
    """
    async with aiosqlite.connect(DB_NAME) as connection:
        cursor = await connection.cursor()

        await cursor.execute('SELECT * FROM chunk WHERE video_id = ? AND id = ?', (video_id, chunk_id))
        chunk = await cursor.fetchone()

        return chunk

def db_export_videos() -> str:
    """Exporter uniquement la table des vidéos sous forme de dictionnaires compatibles JSON.
    
    Returns:
        str: Les vidéos au format JSON.
    """
    connection = sqlite3.connect(DB_NAME)
    cursor = connection.cursor()

    # Videos
    cursor.execute('SELECT id, title, description, category, live, edges, thumbnail, streamer_id, created_at FROM video')
    videos = [{"id": row[0],"title": row[1],"description": row[2],"category": row[3],"live": row[4],"edges": row[5],"thumbnail": row[6],"streamer_id": row[7],"created_at": row[8]}for row in cursor.fetchall()]

    connection.close()
    
    json_videos = json.dumps(videos)
    
    return json_videos

def db_export() -> dict:
    """Exporter l'intégralité de la base de données (sauf chunks) sous forme de dictionnaires compatibles JSON.
    
    Returns:
        dict: Un dictionnaire contenant les streamers, vidéos et chunks.
    """
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

    db_content = {
        "streamers": streamers,
        "videos": videos,
    }

    connection.close()
    return db_content

def subscribe_to_topics(client):
    client.subscribe("db")
    client.subscribe(f"db/{EDGE_ID}")
    client.subscribe(f"auth/zone/{EDGE_ID}")
    client.subscribe("video/request/ping")
    client.subscribe(f"live/upload/{EDGE_ID}")
    client.subscribe(f"video/upload/{EDGE_ID}")
    client.subscribe("db/update")
    client.subscribe(f"video/liste/{EDGE_ID}")
    client.subscribe(f"video/watch/{EDGE_ID}")
    print("Tous les topics souscrits")

async def connect_mqtt() -> mqtt_client.Client:
    """Se connecter au broker MQTT.
    
    Returns:
        mqtt_client.Client: Le client MQTT connecté.
    """
    
    def on_connect(client, userdata, flags, rc):
        if rc == 0:
            print("Connected to MQTT Broker!")
            
            #fonctions subscribe mises ici, car quand le code paho est surchargé, il relance la connection, et il faut resubscribe du coup (on aurait et devrait mettre un on_disconnect() aussi pour handle correctement et proprement)
            subscribe_to_topics(client)
        else:
            print("Failed to connect, return code %d\n", rc)

    client = mqtt_client.Client()
    client.on_connect = on_connect
    client.on_message = on_message
    
    # Connect in a thread to avoid blocking
    await loop.run_in_executor(executor, client.connect, BROKER, PORT)
    client.loop_start()
    return client

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
        # Ici on limite l'affichage pour éviter les gros messages
        print(f"Message `{message[0:100] + '...' if len(message) > 100 else ''}` envoyé au topic `{topic[0:100] + '...' if len(topic) > 100 else ''}`")
    else:
        print(f"Échec de l'envoi du message à {topic} : {result}")

def on_message(client: mqtt_client.Client, userdata, msg) -> None:
    """Gérer les messages MQTT entrants de manière asynchrone.
    
    Args:
        client (mqtt_client.Client): Le client MQTT.
        userdata: Les données utilisateur.
        msg: Le message reçu.
    
    Returns:
        None
    """
    global loop
    if loop:
        asyncio.run_coroutine_threadsafe(message_handler(client, msg), loop)

async def handle_video_request_ping(client: mqtt_client.Client, msg) -> None:
    """Traiter les demandes de ping pour obtenir le statut du système.
    
    Args:
        client (mqtt_client.Client): Le client MQTT.
        msg: Le message reçu.
    
    Returns:
        None
    """
    client_id = json.loads(msg.payload.decode())["client_id"]
    status_data = get_system_status()
    save_status_to_json(status_data)
    publish(client, f"video/request/ping/{client_id}", json.dumps(status_data))

async def handle_video_liste(client: mqtt_client.Client, msg) -> None:
    """Traiter les demandes de liste de vidéos.
    
    Args:
        client (mqtt_client.Client): Le client MQTT.
        msg: Le message reçu.
    
    Returns:
        None
    """
    message_json = json.loads(msg.payload.decode())
    client_id = message_json["client_id"]
    video_list = await loop.run_in_executor(executor, db_export_videos)
    publish(client, f"video/liste/{EDGE_ID}/{client_id}", video_list)

async def handle_video_watch(client: mqtt_client.Client, msg) -> None:
    """Traiter les demandes de visionnage de vidéo.
    
    Args:
        client (mqtt_client.Client): Le client MQTT.
        msg: Le message reçu.
    
    Returns:
        None
    """
    message_json = json.loads(msg.payload.decode())
    client_id = message_json["client_id"]
    init = message_json["init"]
    video_id = message_json["video_id"]
    
    video = await db_get_video_by_id(video_id)
    
    if not video:
        print("Vidéo non trouvée dans la base de données")
        publish(client, f"video/watch/{EDGE_ID}/{client_id}", json.dumps({"video_id": video_id, "end": "1"}))
        return

    video_title = video["title"]

    # Dans le cas où ce sont les metadatas de la vidéos (le premier message)
    if init == "1":
        publish(client, f"video/watch/{EDGE_ID}/{client_id}", json.dumps({"video_title": video_title, "video_id": video_id, "chunk_part": "0", "end": "0"}))
    else:
        chunk_part = int(message_json["chunk_part"]) + 1
        chunk = await db_get_chunk(video_id, chunk_part)
        if not chunk:
            publish(client, f"video/watch/{EDGE_ID}/{client_id}", json.dumps({"video_title": video_title, "video_id": video_id, "end": "1"}))
        else :
            publish(client, f"video/watch/{EDGE_ID}/{client_id}", json.dumps({"video_title": video_title, "video_id": video_id, "chunk_part": chunk_part, "chunk": chunk, "end": "0"}))

async def handle_live_upload(client: mqtt_client.Client, msg) -> None:
    """Traiter les uploads de live streaming.
    
    Args:
        client (mqtt_client.Client): Le client MQTT.
        msg: Le message reçu.
    
    Returns:
        None
    """
    global chiffrement_init
    
    message_json = json.loads(msg.payload.decode())
    live_id = message_json["video_id"]
    end = message_json["end"]
    print("Paquet live reçu", end)
    
    try:
        streamer_id = message_json["streamer_id"]
    except Exception:
        streamer_id = None
    
    # Si il y a un streamer_id, c'est que c'est le premier message avec les metadatas du live
    if streamer_id:
        streamer_nom = message_json["streamer_nom"]
        category = message_json["category"]
        description = message_json["description"]
        thumbnail = message_json["thumbnail"]
        live_nom = message_json["video_nom"]
        
        if await db_get_streamer_by_id(streamer_id) is None:
            await db_add_streamer(streamer_id, streamer_nom)
            publish(client, "db/update", json.dumps({"status": "ajout", "live": True, "video_id": live_id, "video_nom": live_nom, "category": category, "streamer_id": streamer_id, "streamer_nom": streamer_nom, "description": description, "thumbnail": thumbnail, "EDGE_ID": EDGE_ID}))
        await db_add_video(live_id, live_nom, description, category, True, EDGE_ID, thumbnail, streamer_id)
        
    # Morceau de live reçu
    else:
        
        try:
            chunk = message_json["chunk"].trim()
            chunk_part = message_json["chunk_part"]
            print("Chunk reçu: ", chunk_part)
            
            if chiffrement_init:
                print("Lancement préjar : chunk_part=", chunk_part)
                verif = await run_jar(["fog", "verify", chunk])
                print(f"Verification chunk live: {verif}")
                
                if verif == "nonono":
                    print("Chunk corrompu : rejetté.")
                else:
                    publish(client, f"live/watch/{EDGE_ID}/{live_id}", json.dumps({"chunk": chunk, "chunk_part": chunk_part}))
                    
            else:
                print("Erreur chiffrement pas initialisé, on ne peut pas recevoir de vidéo")
                
        except Exception:
            chunk = None
            chunk_part = None
            
        # Si fin de vidéo
        if end == 1 or end == "1":
            publish(client, "db/update", json.dumps({"status": "suppression", "video_id": live_id, "EDGE_ID": EDGE_ID}))
            await db_remove_video(live_id)
            print(f"Live {live_id} terminé et supprimé de la BDD")

async def handle_auth_zone(client: mqtt_client.Client, msg) -> None:
    """Traiter l'authentification de la zone.
    
    Args:
        client (mqtt_client.Client): Le client MQTT.
        msg: Le message reçu.
    
    Returns:
        None
    """
    
    global chiffrement_init
    message_json = json.loads(msg.payload.decode())
    parametre = message_json["parametre"]
    
    await run_jar(["fog", "init", EDGE_ID, parametre])
    chiffrement_init = True
    print("Initialisation du chiffrement terminée.")

async def handle_video_upload(client: mqtt_client.Client, msg) -> None:
    """Traiter les uploads de vidéo.
    
    Args:
        client (mqtt_client.Client): Le client MQTT.
        msg: Le message reçu.
    
    Returns:
        None
    """
    
    global chiffrement_init
    message_json = json.loads(msg.payload.decode())
    video_id = message_json["video_id"]
    end = message_json["end"]
    
    try:
        category = message_json["category"]
        thumbnail = message_json["thumbnail"]
        streamer_id = message_json["streamer_id"]
        streamer_nom = message_json["streamer_nom"]
        description = message_json["description"]
        video_nom = message_json["video_nom"]
    except Exception:
        streamer_id = None
        streamer_nom = None
        category = None
        thumbnail = None
        description = None
        video_nom = None

    # Si on a les metadatas de la vidéo (premier message)
    if streamer_id and description and streamer_nom and category and thumbnail:
        streamer_exist = await db_get_streamer_by_id(streamer_id) is not None
        
        if not streamer_exist:
            await db_add_streamer(streamer_id, streamer_nom)

        await db_add_video(video_id, video_nom, description, category, False, EDGE_ID, thumbnail, streamer_id)
        publish(client, f"video/upload/{EDGE_ID}/{streamer_id}", json.dumps({"video_id": video_id, "EDGE_ID": EDGE_ID}))
    
    # Sinon, c'est un morceau de vidéo
    else:
        chunk = message_json["chunk"]
        chunk_part = message_json["chunk_part"]
        video_exist = await db_get_video_by_id(video_id) is not None

        if not video_exist:
            print(f"Erreur, vidéo non trouvée dans BDD : nom={video_nom}, ID={video_id}")

        # Si fin de vidéo
        if end == "1":
            if chiffrement_init:
                verif1 = await run_jar(["fog", "verify", chunk])
                await db_add_chunk(str(uuid.uuid4()), video_id, chunk_part, chunk)
                
                # On vérifie que le chunk final est correct
                # Si elle l'est pas :
                if verif1 == "X":
                    print(f"Erreur lors de l'ajout du chunk dans la BDD\n video_id={video_id}, chunk_part={chunk_part}\n ou chunk corrompu (signature ayant raté la vérification)")
                else:
                    publish(client, "db/update", json.dumps({"status": "ajout", "live": False, "video_id": video_id, "video_nom": video_nom, "category": category, "streamer_id": streamer_id, "streamer_nom": streamer_nom, "description": description, "thumbnail": thumbnail, "EDGE_ID": EDGE_ID}))
            else:
                print("Erreur chiffrement pas initialisé, on ne peut pas recevoir de vidéo")
        else:
            await db_add_chunk(str(uuid.uuid4()), video_id, chunk_part, chunk)
            publish(client, f"video/upload/{EDGE_ID}/{streamer_id}", json.dumps({"status": "ok", "video_id": video_id, "chunk_part": chunk_part, "EDGE_ID": EDGE_ID}))

async def handle_db_update(client: mqtt_client.Client, msg) -> None:
    """Traiter les mises à jour de la base de données.
    
    Args:
        client (mqtt_client.Client): Le client MQTT.
        msg: Le message reçu.
    
    Returns:
        None
    """
    message_json = json.loads(msg.payload.decode())
    status = message_json["status"]
    video_id = message_json["video_id"]
    
    if status == "ajout":
        video_nom = message_json["video_nom"]
        category = message_json["category"]
        EDGE2_ID = message_json["EDGE_ID"]
        streamer_id = message_json["streamer_id"]
        streamer_nom = message_json["streamer_nom"]
        live = message_json["live"]
        description = message_json["description"]
        thumbnail = message_json["thumbnail"]
        
        # On a jamais vu ce streamer ? On l'ajoute
        if await db_get_streamer_by_id(streamer_id) is None:
            await db_add_streamer(streamer_id, streamer_nom)
        
        # On a jamais vu cette vidéo ? On l'ajoute
        if await db_get_video_by_id(video_id) is None:
            await db_add_video(video_id, video_nom, description, category, live, EDGE2_ID, thumbnail, streamer_id)
        # Sinon on met juste à jour les edges
        else:
            await db_add_video_edges(video_id, EDGE2_ID)
    # Si c'est pas ajout c'est une suppression
    else:
        if await db_get_video_by_id(video_id) is not None:
            await db_remove_video(video_id)

async def handle_db_request(client: mqtt_client.Client, msg) -> None:
    """Traiter les demandes d'export de la base de données.
    
    Args:
        client (mqtt_client.Client): Le client MQTT.
        msg: Le message reçu.
    
    Returns:
        None
    """
    db_content = await loop.run_in_executor(executor, db_export)
    db_json = json.dumps(db_content)
    message_json = json.loads(msg.payload.decode())
    EDGE2_ID = message_json["ID"]
    
    # Si on a des streamers dans la BDD, on envoie tout, sinon on envoie juste que c'est vide
    if db_content["streamers"]:
        publish(client, f"db/{EDGE2_ID}", db_json)
    else:
        payload = json.dumps({'streamers': ""})
        publish(client, f"db/{EDGE2_ID}", payload)

async def handle_db_receive(client: mqtt_client.Client, msg) -> None:
    """Traiter la réception d'une base de données.
    
    Args:
        client (mqtt_client.Client): Le client MQTT.
        msg: Le message reçu.
    
    Returns:
        None
    """
    message_json = json.loads(msg.payload.decode())

    # Si on reçoit une DB l'importer
    if message_json['streamers'] != "":
        await db_import(message_json)

async def message_handler(client: mqtt_client.Client, msg) -> None:
    """Traitement des messages selon le topic.
    
    Args:
        client (mqtt_client.Client): Le client MQTT.
        msg: Le message reçu.
    
    Returns:
        None
    """
    
    # On limite l'affichage pour éviter les gros messages
    print(f"Message `{msg.payload.decode()[0:100] + '...' if len(msg.payload.decode()) > 100 else ''}` du topic `{msg.topic[0:100] + '...' if len(msg.topic) > 100 else ''}` reçu")
    
    if msg.topic == "video/request/ping":
        await handle_video_request_ping(client, msg)
    
    elif msg.topic == f"video/liste/{EDGE_ID}":
        await handle_video_liste(client, msg)
    
    elif msg.topic == f"video/watch/{EDGE_ID}":
        await handle_video_watch(client, msg)
    
    elif msg.topic == f"live/upload/{EDGE_ID}":
        await handle_live_upload(client, msg)
    
    elif msg.topic == f"auth/zone/{EDGE_ID}":
        await handle_auth_zone(client, msg)
    
    elif msg.topic == f"video/upload/{EDGE_ID}":
        await handle_video_upload(client, msg)
    
    elif msg.topic == "db/update":
        await handle_db_update(client, msg)
    
    elif msg.topic == "db":
        await handle_db_request(client, msg)
    
    elif msg.topic == f"db/{EDGE_ID}":
        await handle_db_receive(client, msg)

def premiere_connexion(client: mqtt_client.Client) -> None:
    """Envoyer l'ID de l'edge cluster au serveur lors de la première connexion.
    
    Args:
        client (mqtt_client.Client): Le client MQTT.
    
    Returns:
        None
    """
    # On envoie notre ID au serveur.
    payload_ID = json.dumps({
        'ID' : EDGE_ID,
    })
    # Récupération des paramètres de chiffrement de la zone
    publish(client,"auth/zone",payload_ID)
    # Interroger les autres edges pour récupérer la base de données
    publish(client,"db",payload_ID)

async def run() -> None:
    """Fonction principale asynchrone pour exécuter le client MQTT.
    
    Returns:
        None
    """
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
        print("Fermeture de l'edge...")
        client.loop_stop()
        client.disconnect()

if __name__ == '__main__':
    asyncio.run(run())