"""
TODO: envoyer le status de l'edge cluster
File who sent the data off the edge cluster to a specific
Usage CPU
Usage memory
Usage disk space
Latence en envoyant l'heure d'envoi

L'edge client envoie une requête dans:
Publish video/request/ping

l'edge cluster doit répondre dans:
Send data to topic video/request/ping/ID
whith ID the id of the edge cluster

"""


import random
import time
from paho.mqtt import client as mqtt_client
import json
import psutil
import shutil
import datetime
import uuid

# MQTT Configuration
BROKER = '10.207.130.234'
PORT = 1883
TOPIC = "/python/mqtt"
CLIENT_ID = f'python-mqtt-{random.randint(0, 1000)}'
EDGE_CLUSTER_ID = str(uuid.uuid4())  # Unique ID for this edge cluster

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
            "edge_cluster_id": EDGE_CLUSTER_ID,
            "cpu_usage_percent": cpu_usage,
            "memory_usage": memory_usage,
            "disk_usage": disk_info,
            "timestamp": timestamp,
            "status": "ok"
        }
        
        return status_data
        
    except Exception as e:
        return {
            "edge_cluster_id": EDGE_CLUSTER_ID,
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
    Topic format: video/request/ping/{EDGE_CLUSTER_ID}
    """
    topic = f"video/request/ping/{EDGE_CLUSTER_ID}"
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

def subscribe(client: mqtt_client, topic: str):
    def on_message(client, userdata, msg):
        print(f"Received `{msg.payload.decode()}` from `{msg.topic}` topic")
        
        # Get current system status
        status_data = get_system_status()
        
        # Save to JSON file
        save_status_to_json(status_data)
        
        # Publish status data to the correct topic
        publish_status(client, status_data)

    client.subscribe(topic)
    client.on_message = on_message

def run():
    client = connect_mqtt()
    
    # Subscribe to ping requests
    subscribe(client, "video/request/ping")
    
    client.loop_start()
    
    print(f"Edge Cluster ID: {EDGE_CLUSTER_ID}")
    print("Listening for ping requests on topic: video/request/ping")
    print(f"Will respond on topic: video/request/ping/{EDGE_CLUSTER_ID}")
    
    while True:
        time.sleep(1)

    

if __name__ == '__main__':
    run()
