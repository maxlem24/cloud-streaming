import psutil
from ping3 import ping

def fonction_qui_va_chech():
    if message.topic == "auth/zone":
        info_decodne = json.loads(msg.payload.decode())
        ID = info_decodne["ID"]
        info_dumb = get_information_voulu()
        # Les info voulu sont ce que vous considérez comme important, il va juste falloir me les communiquer sous cette forme 
        # info dumb = {
        # 
        # info 1 : oeoeoe 
        # info 2 : dyugeyufgeu
        # ...
        #  }
        json_info = json.dumps(info_dumb)
        envoyer(client,f"auth/zone/{ID}"json_info)




# POUR CLIENT


# LE CLIENT DOIT ENVOYER SON ADRESSE IP POUR LE PING
def fonction_ping_request():
    if message.topic == "video/ping/request":
        info_decodne = json.loads(msg.payload.decode())
        ID = info_decodne["ID"]

        cpu_percent = psutil.cpu_percent(interval=1)  # % d'utilisation CPU sur 1 seconde
        print(f"CPU utilisé : {cpu_percent} %")
        disk = psutil.disk_usage('C:\\')
        total_gb = disk.total / (1024**3)
        used_gb = disk.used / (1024**3)
        free_gb = disk.free / (1024**3)
        percent = disk.percent

        print(f"Stockage total : {total_gb:.2f} Go")
        print(f"Utilisé : {used_gb:.2f} Go")
        print(f"Libre : {free_gb:.2f} Go")
        print(f"Pourcentage utilisé : {percent} %")
        payload = {
            "cpu_percent" : cpu_percent,
            "disk left" : free_gb,
        }
        json_payload = json.dumps(payload)
        envoyer(client,f"/video/ping/request/{ID}")
