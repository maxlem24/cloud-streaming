import json
import sqlite3
import aiosqlite

DB_NAME = 'edge_cluster.db'

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
    