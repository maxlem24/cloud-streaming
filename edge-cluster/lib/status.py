import psutil
import shutil
import datetime
import platform
import json

def get_system_status(edge_id: str) -> dict:
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
            "edge_id": edge_id,
            "cpu_usage_percent": cpu_usage,
            "memory_usage": memory_usage,
            "disk_usage": disk_info,
            "timestamp": timestamp,
            "status": "ok"
        }
        
        return status_data
        
    except Exception as e:
        return {
            "edge_id": edge_id,
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
