import random
import time
from paho.mqtt import client as mqtt_client
import json

# MQTT Configuration
BROKER = '192.168.2.81'
PORT = 1883
TOPIC = "auth/user/"
EDGE_ID = f'python-mqtt-{random.randint(0, 1000)}'
videoslist=[]


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
    msg_count = 0
    while True:
        time.sleep(1)
        msg = f"messages: {msg_count}"
        result = client.publish(topic, msg)
        
        # Check publish status
        status = result[0]
        if status == 0:
            print(f"Send `{msg}` to topic `{TOPIC}`")
        else:
            print(f"Failed to send message to topic {TOPIC}")
        msg_count += 1
        
        
def subscribe(client: mqtt_client, topic: str):
    def on_message(client, userdata, msg):
        print(f"Received `{msg.payload.decode()}` from `{msg.topic}` topic")
        if (msg.topic=="auth/zone"):
            # on reçoi : ID
            message_json=json.loads(msg.payload.decode())
            ID=message_json["ID"]
            #VERIF niveau bdd le user
            msg_a_envoyer={"param1":"param... A REMPLIR######################","status":"ok"}
            message_json=json.dumps(msg_a_envoyer)
            publish(client,f"auth/zone/{ID}", message_json)
        if(msg.topic==f"video/upload/{EDGE_ID}"):
            # partie edge de send_video et video_received
            message_json=json.loads(msg.payload.decode())
            video_ID=message_json["video_ID"]
            video_nom=message_json["video_nom"]
            category=message_json["category"]
            chunk=message_json["chunk"]
            chunk_part=message_json["chunk_part"] #combien t ieme chunk
            end=message_json["end"]
            try:
                streamerid=message_json["streamer_id"]
                streamer_nom=message_json["streamer_nom"]
            except:
                streamer_id=None
                streamer_nom=None

            if (streamer_id):
                "partie 1"
                ##vérif si streamer existe 
                if(not streamer_exist):
                    ##créer stremer nom et id
                    print("fill")
                ##ajouter new video au streamer
                ##avec category, video ID, video nom
                publish(client,f"video/upload/{EDGE_ID}/{streamer_id}", json.dumps({"status":"ok","video_ID":video_ID}))
            else:
                "partie 2"
                #vérif video existe dans bdd
                if(not video_exist):
                    print("erreur, vidéo nom trouvée dans bdd : nom={video_nom}, ID={video_ID}")
                if(end=="1"):
                    #vérif que tous les chunks sont là (sans trous) dans la bdd
                    if(all_chunks):
                        publish(client,f"db/update", json.dumps({"status":"ajout","video_ID":video_ID,"EDGE_ID":EDGE_ID}))
                    else:
                        #recup chunks manquants
                        publish(client,f"video/upload/{EDGE_ID}/{streamer_id}", json.dumps({"status":"error","video_ID":video_ID,"chunk_part":chunk_part}))
                else:
                    #ajouter chunk et chunk part dans bdd
                    publish(client,f"video/upload/{EDGE_ID}/{streamer_id}", json.dumps({"status":"ok","video_ID":video_ID,"chunk_part":chunk_part}))
        if(msg.topic==f"db/update"):
            message_json=json.loads(msg.payload.decode())
            video_ID=message_json["video_ID"]
            video_nom=message_json["video_nom"]
            category=message_json["category"]
            EDGE_ID2=message_json["EDGE_ID"]
            ### mettre à jour la db pr dire que le edge_id2 a la vidéo
        if(msg.topic==f"video/liste/{EDGE_ID}"):
            #partie edge de get_videos
            message_json=json.loads(msg.payload.decode())
            client_ID=message_json["client_ID"]
            ### recup la liste des videos de la bdd
            ### mettre en liste de listes ([video nom 1,id1, category, streamers, edges qui l'ont...]...)
            publish(client,f"video/liste/{EDGE_ID}/{client_ID}", json.dumps({"status":"ok","liste_videos_noms,ID":liste_videos}))
        if(msg.topic==f"video/watch/{EDGE_ID}"):
            #partie edge de watch_video()
            message_json=json.loads(msg.payload.decode())
            client_ID=message_json["client_ID"]
            init=message_json["init"]
            video_ID=message_json["video_ID"]
            
            end=message_json["end"]
            if(init=="1"):
                ### recup l'ID vidéo de la bdd
                publish(client,f"video/watch/{EDGE_ID}/{client_ID}", json.dumps({"status":"ok","video_nom":video_nom,"video_ID":video_ID,"chunk_part":"0"}))
            
            elif(end=="1"):
                video_ID=message_json["video_ID"]
                ### dire que la vidéo est finie
                publish(client,f"video/watch/{EDGE_ID}/{client_ID}", json.dumps({"status":"ok","video_nom":video_nom,"chunk_part":"end"}))
            else:
                video_ID=message_json["video_ID"]
                chunk_part=message_json["chunk_part"]
                ### recup le chunk_part de la bdd
                publish(client,f"video/watch/{EDGE_ID}/{client_ID}", json.dumps({"status":"ok","video_nom":video_nom,"chunk_part":chunk_part,"chunk":chunk}))




            

        





    client.subscribe(topic)
    client.on_message = on_message


def run():
    
    
    client = connect_mqtt()  
    subscribe(client, "video/upload/{EDGE_ID}")
    subscribe(client, "auth/zone")  
    subscribe(client, f"db/update")
    subscribe(client, f"video/liste/{EDGE_ID}")
    subscribe(client, f"video/watch/{EDGE_ID}")
    print("envoyé")
    


if __name__ == '__main__':
    run()