
Définition : 

Twinsa : Nom de l'application
Streamer : Personne qui diffuse une vidéo sur un edge 
Client : Personne qui se connecte à un edge pour voir la diffusion d'un stream (Utilisateur)
Publisher : Service / Personne qui envoie des messages sur un topic spécifique
Subscriber : Service / Personne qui reçoit des messages en s'abonnant à un topic
Topic : Canal de communication où les publishers envoient des messages et le subscribers s’abonnent pour recevoir uniquement les informations qui les concernent
Edge : Permet de stocker et de diffuser par morceaux une vidéo du streamer et contient les topics
Broker : Serveur central qui filtre les messages et assure la liaison entre les publishers et les subscribers
MQTT : Protocole de communication qui permet de faire communiquer le client, le streamer, le broker et le edge


Fonctionnement : 

Streamer :
1. Le streamer se connecte/crée un compte depuis l'application.
2. Une requête est envoyée au edge via le broker
3. Le streamer reçoit une liste de edge disponible
4. Le streamer choisit une vidéo à diffuser sur le edge le plus proche et le plus adéquat pour streamer
6. Le streamer publie et envoie la vidéo sur le edge le plus adéquat 
8. La vidéo est stockée en morceaux sur le edge

Client : 
1. Le client choisit une vidéo à regarder depuis l'application
2. Une requête est envoyée au edge via le broker
3. Le client reçoit une liste de edge disponible
4. Le client demande la liste de vidéo au edge et choisit une vidéo
5. Le edge lui renvoie le edge le plus proche et le plus adéquat pour la vidéo
7. Le client s'abonne au topic du edge le plus adéquat
9. Le edge renvoie en boucle la vidéo par morceau au client

