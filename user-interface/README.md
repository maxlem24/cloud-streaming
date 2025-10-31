# Interface Graphique

### Romain et Abla

# 🎬 TW'INSA

Une desktop App de streaming moderne inspirée de Pinterest et des principes de design nouveau.


![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)
![MQTT](https://img.shields.io/badge/MQTT-660066?style=for-the-badge&logo=mqtt&logoColor=white)

## 📋 Description

Le développement d'une interface de streaming offrant une expérience utilisateur fluide et moderne pour accéder à du contenu multimédia. Développée avec Flutter, elle rassemble une interface inspirée de Pinterest avec des fonctionnalités de streaming avancées.

## ✨ Fonctionnalités

- 🎨 **Interface utilisateur moderne** : Design inspiré de Pinterest avec une mise en page fluide et esthétique
- 🔐 **Authentification sécurisée** : Système de connexion via Supabase
- 📡 **Communication temps réel** : Intégration MQTT pour la synchronisation instantanée entre le frontend et le backend
- 🎥 **Streaming cloud** : Lecture de contenu multimédia en streaming et live 
- 🎯 **Interface et Navigation intuitive** : Expérience utilisateur simplifiée 

## 🛠️ Technologies utilisées

### Frontend
- **Flutter** - Framework de développement d'interface utilisateur
- **Dart** - Langage de programmation

### Backend & Services
- **Supabase** - Backend as a Service pour l'authentification et la base de données
- **MQTT** - Protocole de messagerie pour la communication temps réel entre le frontend et le backend

### Design
- Inspirations : Pinterest, design moderne et minimaliste, d'autres plateformes de live/stream
- Principes : Interface épurée, navigation fluide, expérience visuelle engageante

## 📦 Lancement

### Prérequis
- Flutter SDK (version 3.35.6 ou supérieure)
- Dart SDK (3.9.2)
- Un compte Supabase 


### Étapes de Lancement

1. Installer les dépendances
```bash
flutter pub get
```

2. Configuration des variables d'environnement
Créer un fichier `.env` à la racine du projet :
```env
SUPABASE_URL=votre_url_supabase
SUPABASE_ANON_KEY=votre_cle_supabase
```

3. Configuration du Mqtt

Modifier la variable `const host= <adresse_ip>` dans le fichier `services
/app_mqtt_service.dart` avec celle de votre réseau qui permet de vous connecter au Service Mqtt. <br>
Ou sinon la fixer sur le `.env` comme le servce Supabase.


4. Lancer l'application
```bash
flutter run
```

## 🚀 Utilisation

1. **Connexion** : Créer un compte ou se connecter via l'interface Supabase
2. **Navigation** : Explorer le contenu disponible avec l'interface inspirée de Pinterest
3. **Streaming** : Sélectionner un média pour commencer le streaming
4. **Temps réel** : Les mises à jour sont synchronisées instantanément via MQTT

## 🏗️ Services Intégrés

### Communication Frontend-Backend

```
┌─────────────────┐         MQTT          ┌─────────────────┐
│                 │◄─────────────────────►│                 │
│Flutter Desktop  │   (Port 1883)         │  Backend / Edge │
│  App (Client)   │   Pub/Sub Topics      │    Servers /    │
│                 │                       │ Sgnature        │
│                 │                       │                 │
│ - AppMqttService│                       │  - video/liste  │
│ - MqttService   │                       │  - edge/ping    │
│                 │                       │                 │
│                 │    Supabase Auth      │                 │
│  - AuthService  │◄─────────────────────►│  PostgreSQL DB  │
│                 │   (REST API)          │                 │
└─────────────────┘                       └─────────────────┘
```

### 🔐 Supabase - Authentification et Gestion Utilisateurs

La desktop App utilise **Supabase** comme backend-as-a-service pour gérer l'ensemble du cycle d'authentification SignIN LogIn et les clefs d'authentification qu'on utilisera par la suite:

**Fonctionnalités implémentées :**
- **Inscription** (`signUpWithEmail`) : Création de compte avec email, username et mot de passe
- **Connexion** (`signInWithPassword`) : Authentification sécurisée avec gestion de session
- **Déconnexion** (`signOut`) : Fermeture propre de la session utilisateur
- **Réinitialisation mot de passe** (`resetPasswordForEmail`) : Récupération de compte par email
- **Rafraîchissement de session** (`refreshSession`) : Maintien de la session active
- **Mise à jour profil** (`updateUser`) : Modification des informations utilisateur


### 📡 MQTT - Communication Temps Réel

Le protocole **MQTT** (Message Queuing Telemetry Transport) est utilisé pour la communication bidirectionnelle entre le client Flutter et les serveurs edge de streaming.

**Architecture du système MQTT :**

#### 1. **MqttService** 
Service wrapper autour de `mqtt_client` qui gère la connexion brute :

```dart
class MqttService {
  final String host;        // Adresse du broker 
  final int port;           // Port MQTT (défaut: 1883)
  final String clientId;    // Identifiant unique du client
  final bool log;           // Permettre d'afficher tous les logs sur le terminal de test
}
```

**Fonctionnalités :**
- Connexion/Déconnexion au broker MQTT
- Publication de messages sur des topics
- Souscription à des topics avec streaming de données
- Gestion automatique des callbacks (onConnected, onDisconnected, etc.)

#### 2. **AppMqttService** 
Service de haut niveau qui orchestr e l'ensemble de la logique streaming :

## Workflow de récupération des vidéos :

1. **Initialisation** (`initAndConnect`)
   - Récupération du token utilisateur (ou génération d'un ID guest)
   - Connexion au broker MQTT
   - Configuration du listener global pour tous les messages

2. **Sélection du meilleur Edge** (`refreshBestEdge`)
   - Ping de tous les serveurs edge disponibles via `edge/ping`
   - Calcul du temps de réponse pour chaque serveur
   - Sélection automatique du serveur le plus rapide selon les critères voulues (`chooseBestEdge.dart`)
   - Mise en cache du meilleur edge dans SharedPreferences

3. **Récupération des vidéos** (`refreshVideos`)
   ```
   Client                    Broker MQTT              Edge Server
     |                            |                        |
     |-- SUBSCRIBE -------------->|                        |
     |   video/liste/edge_id/     |                        |
     |   client_id                |                        |
     |                            |                        |
     |-- PUBLISH ---------------->|---FORWARD------------->|
     |   video/liste/edge_id      |                        |
     |   {"client_id": "xxx"}     |                        |
     |                            |                        |
     |<-------------------------- |<------RESPONSE---------|
     |   [liste des videos/live]  |                        |
   ```

4. **Parsing et classification**
   - Décodage JSON de la réponse
   - Création d'objets `VideoItem` pour chaque vidéo
   - Séparation automatique : vidéos live vs VOD
   - Notification des listeners (UI) via `notifyListeners()`

**Topics MQTT utilisés :**
- `video/liste/{edge_id}` : Publication pour demander la liste des vidéos
- `video/liste/{edge_id}/{client_id}` : Réception de la réponse personnalisée
- `edge/ping` : Découverte et sélection des serveurs edge


## 🎥 Streaming en Direct (Live)

L'application implémente un système complet de streaming vidéo en temps réel basé sur MQTT, permettant à la fois la diffusion et la réception de flux live.

### 📡 Architecture du Streaming Live

```
┌──────────────┐         MQTT           ┌──────────────┐
│   Streamer   │───────────────────────►│  Edge Server │
│   (GoLive)   │  live/upload/{edge_id} │              │
│              │                        │              │
│  - Capture   │                        │  - Storage   │
│  - Signature │                        │              │
│  - Chunking  │                        │              │
└──────────────┘                        └──────┬───────┘
                                               │
                                               │ live/watch/{edge_id}/ {video_id}
                                               │
                                       ┌──────▼───────┐
                                       │   Viewers    │
                                       │ (LiveViewer) │
                                       │              │
                                       │  - Receive   │
                                       │  - Merge     │
                                       │  - Display   │
                                       └──────────────┘
```

### 🎬 Côté Streamer (GoLive)

**Workflow de diffusion :**

1. **Initialisation**
   ```dart
   // Connexion MQTT
   await _mqtt.initAndConnect();
   await _mqtt.refreshBestEdge();
   
   // Initialisation camera
   await camera.initialize();
   
   // Récupération de l'identifiant owner en base64
   await _initOwnerId();
   ```
   Cet initialisation prend également en compte la créaton de l'ID de signature spécifique à l'utilisateur qu'on envoie via Mqtt pour avoir la base64  `String base64_topic = "auth/user/${auth.sub}";` sur le topic. 
   Sur la fonction `_initOwnerId()`, le streamer envoie son ID sur le topic `auth/user`.

2. **Message de démarrage du stream**
   ```json
   Topic: live/upload/{edge_id}
   Payload: {
     "video_id": "1234",
     "end": 0,
     "streamer_nom": "Username", 
     "category": "live",
     "description": "Live de Username sur Twinsa",
     "thumbnail": 012456,
     "video_nom": "Live de Username sur Twinsa",
     "streamer_id": "jwt_token"
   }
   ```

3. **Capture et envoi des frames** (1 FPS)
   - Capture d'une image via la caméra
   - Signature (chiffrement Backend) de l'image avec `Signature.owner_sign()`
   - Division de la signature en 8 paquets
   - Envoi séquentiel de chaque paquet

4. **Structure d'un paquet de frame**
   ```json
   Topic: live/upload/{edge_id}
   Payload: {
     "video_id": "1234",
     "end": 0,
     "chunk_part": 42,           // Numéro de frame
     "chunk": "signature_data",  // Partie recup de la signature
     "packet_index": 0,          // Index du paquet (0-7)
     "total_packets": 8          // Total de paquets par frame
   }
   ```

5. **Message de fin de stream**
   ```json
   Payload: {
     "video_id": "1234",
     "end": 1
   }
   ```

**Sécurité et signatures :**
- Chaque frame est signée via `Signature.owner_sign()`
- La signature est divisée en 8 chunks pour respecter les limites MQTT
- L'owner_base64 est récupéré au démarrage pour l'authentification

### 📺 Côté Viewer (LiveViewer)

**Workflow de réception :**

1. **Connexion au stream**
   ```json
   Topic: live/watch/{edge_id}
   Payload: {
     "video_id": "1234",
     "client_id": "viewer_token",
     "action": "watch"
   }
   ```

2. **Souscription au flux**
   ```
   Topic: live/watch/{edge_id}/{video_id}
   ```
   - Bien évidement le `edge_id` utilisé est celui recupéré sur l'objet `VideoItem` 

3. **Réception et reconstruction des frames**
   ```dart
   // Stockage temporaire des paquets par frame
   Map<int, List<String>> _framePackets = {};
   
   // Accumulation des 8 paquets d'une frame
   for each packet received:
     packets.add(chunkData);
     
   // Quand 8 paquets reçus -> reconstruction
   if (packets.length == 8) {
     fullSignature = packets.join('\n');
     imagePath = await Signature.client_merge(sigFile);
     displayImage(imagePath);
   }
   ```

4. **Affichage temps réel**
   - Les frames sont affichées dès leur reconstruction complète
   - Utilisation de `gaplessPlayback: true` pour fluidité
   - Stats en temps réel : nombre de frames et paquets reçus

**Gestion des frames :**
- Chaque frame nécessite 8 paquets complets
- Les paquets sont stockés temporairement dans `_framePackets`
- Une fois les 8 paquets reçus, la signature est reconstituée.
- La frame est ensuite merge via `Signature.client_merge()` et est affichée



