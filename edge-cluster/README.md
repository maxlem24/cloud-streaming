# Gestion des Edges
### Corentin, Baptiste et Thomas

# Comment récupérer le docker mosquitto : 
```bash
docker run -it -p 1883:1883 -v ./mosquitto/config:/mosquitto/config eclipse-mosquitto
```
Le fichier mosquitto.conf est dans le dossier (faut regarder au dessus)