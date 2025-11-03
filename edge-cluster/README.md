# Edge Cluster

## 📋 Table des matières

- [Description](#-description)
- [Auteurs](#-auteurs)
- [Architecture](#-architecture)
- [Prérequis](#-prérequis)
- [Installation](#-installation)
- [Configuration](#-configuration)
- [Structure de la base de données](#-structure-de-la-base-de-données)
- [Topics MQTT](#-topics-mqtt)
- [Fonctionnalités](#-fonctionnalités)
- [Utilisation avec Docker](#-utilisation-avec-docker)

---

## 📖 Description

Le module **Edge Cluster** est un composant distribué d'un système de streaming vidéo. Il gère le stockage et la distribution de vidéos et de streams en direct via MQTT, et exploite les fonctionnalités de chiffrement et de vérification de signatures fournis par la partie SIS.

Chaque edge cluster :

- Stocke les vidéos et métadonnées dans une base SQLite locale
- Communique avec d'autres edges via MQTT pour synchroniser les données
- Vérifie l'intégrité des chunks vidéo à l'aide de signatures cryptographiques (via JAR)
- Répond aux requêtes de streaming en temps réel

---

## 👥 Auteurs

- Baptiste SALTEL
- Corentin PHILLIPE
- Thomas MENU
- Alban DELUCHE
- Elouan SAGNARD
- Tristan DUCRAUX

---

## 🏗️ Architecture

Le système est composé de deux composants principaux :

### 1. **main.py** - Serveur principal de l'Edge Cluster

Edge "classique", gère l'ensemble des opérations de streaming, stockage et synchronisation. Il peut y en avoir autant que nécessaire dans le cluster :

- Réception et stockage des vidéos et lives
- Distribution des vidéos aux clients
- Synchronisation entre edges
- Vérification cryptographique des chunks

### 2. **auth_edge.py** - Serveur d'authentification

Edge dédié à l'authentification, un par zone (cluster d'edges) :

- Authentification des zones (edges)
- Vérification des utilisateurs via Supabase
- Génération de paramètres cryptographiques

### Bibliothèques (`lib/`)

- **db.py** : Gestion de la base de données SQLite (CRUD sur streamers, vidéos, chunks)
- **status.py** : Collecte des métriques système (CPU, mémoire, disque)

---

## 🔧 Prérequis

- **Python 3.13+**
- **Java 21** (OpenJDK)
- **JAR de signature** : `cloud_signature-1.0-SNAPSHOT-jar-with-dependencies.jar` (doit être présent dans le répertoire)
- **Broker MQTT** (Mosquitto recommandé)
- **Compte Supabase** (pour l'authentification)

---

## 📥 Installation

### 1. Cloner le projet

```bash
cd edge-cluster
```

### 2. Installer les dépendances Python

```bash
pip install -r requirements.txt
```

### 3. Configurer le broker MQTT

Un broker MQTT existant est nécessaire pour la communication entre les edges et les clients. Il doit suivre la configuration précisée par le fichier `mosquitto.conf` à la racine du projet. La partie suivante explique comment lancer un broker Mosquitto manuellement, mais il est possible de le déployer avec le docker compose situé à la racine du projet.

#### Option 1 : Docker (recommandé)

```bash
docker run -it -p 1883:1883 -v ./mosquitto/config:/mosquitto/config eclipse-mosquitto
```

Le fichier `mosquitto.conf` se trouve dans le dossier parent.

#### Option 2 : Installation locale

Installer Mosquitto selon votre système d'exploitation.

---

## ⚙️ Configuration

### Supabase

Supabase est utilisé pour l'authentification des utilisateurs. Côté edge, c'est l'edge d'authentification qui interagit avec Supabase : son objectif est de vérifier que les streamers sont bien authentifiés avant de leur donner leurs paramètres cryptographiques uniques qui leur permettront de signer leurs chunks vidéo.

Ce choix a été fait afin d'avoir une solution d'authentification robuste et rapide pour la première version du projet, mais il est possible de remplacer cette partie par un autre système d'authentification si nécessaire.

1. Créer un compte puis un projet Supabase.

2. Obtenir l'URL et la clé API.

### Variables d'environnement

Créer un fichier `.env` ou définir les variables suivantes :

```bash
# MQTT
MQTT_BROKER=localhost        # Adresse du broker MQTT

# Supabase (pour auth_edge.py)
SUPABASE_URL=https://votre-projet.supabase.co
SUPABASE_KEY=votre_cle_supabase
```

### Fichiers requis

- **JAR de signature** : `cloud_signature-1.0-SNAPSHOT-jar-with-dependencies.jar`
  - Utilisé pour les opérations cryptographiques
  - Doit être dans le même répertoire que `main.py`

---

## 🗄️ Structure de la base de données

La base de données SQLite (`edge_cluster.db`) unique à chaque edge contient trois tables :

### Table `streamer`

```sql
CREATE TABLE streamer (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
)
```

### Table `video`

```sql
CREATE TABLE video (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    category TEXT NOT NULL,
    live BOOLEAN NOT NULL DEFAULT 0,
    edges TEXT NOT NULL,                    -- Liste d'IDs d'edges (séparés par virgules)
    thumbnail TEXT NOT NULL,
    streamer_id TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (streamer_id) REFERENCES streamer(id) ON DELETE CASCADE
)
```

### Table `chunk`

```sql
CREATE TABLE chunk (
    id TEXT PRIMARY KEY,
    video_id TEXT NOT NULL,
    chunk_nb INTEGER NOT NULL,
    part INTEGER NOT NULL,
    FOREIGN KEY (video_id) REFERENCES video(id) ON DELETE CASCADE
)
```

**Fonctionnement :**

- Les vidéos sont divisées en **chunks** pour optimiser le streaming
- Chaque vidéo référence les **edges** qui la stockent
- La suppression d'un streamer supprime automatiquement ses vidéos et chunks (CASCADE)

---

## 📡 Topics MQTT

### Topics souscrits par `main.py`

| Topic                    | Description                             |
| ------------------------ | --------------------------------------- |
| `db`                     | Demandes d'export de base de données    |
| `db/{EDGE_ID}`           | Réception d'une BDD d'un autre edge     |
| `db/update`              | Notifications de mise à jour de BDD     |
| `auth/zone/{EDGE_ID}`    | Réception des paramètres de chiffrement |
| `video/request/ping`     | Requêtes de statut système              |
| `video/liste/{EDGE_ID}`  | Requêtes de liste de vidéos             |
| `video/watch/{EDGE_ID}`  | Requêtes de visionnage de vidéo         |
| `video/upload/{EDGE_ID}` | Upload de vidéos (VOD)                  |
| `live/upload/{EDGE_ID}`  | Upload de streams en direct             |

### Topics publiés par `main.py`

| Topic                                  | Description                               |
| -------------------------------------- | ----------------------------------------- |
| `auth/zone`                            | Demande de paramètres de chiffrement      |
| `db`                                   | Demande de synchronisation de BDD         |
| `db/update`                            | Notification d'ajout/suppression de vidéo |
| `video/request/ping/{client_id}`       | Réponse avec statut système               |
| `video/liste/{EDGE_ID}/{client_id}`    | Liste des vidéos disponibles              |
| `video/watch/{EDGE_ID}/{client_id}`    | Chunks vidéo pour lecture                 |
| `video/upload/{EDGE_ID}/{streamer_id}` | Confirmation d'upload                     |
| `live/watch/{EDGE_ID}/{live_id}`       | Diffusion de chunks de live               |

### Topics pour `auth_edge.py`

| Topic                   | Type         | Description                           |
| ----------------------- | ------------ | ------------------------------------- |
| `auth/zone`             | Souscription | Authentification de zones             |
| `auth/user`             | Souscription | Authentification d'utilisateurs       |
| `auth/zone/{client_id}` | Publication  | Paramètres cryptographiques pour zone |
| `auth/user/{client_id}` | Publication  | Identifiant chiffré pour utilisateur  |

---

## 🚀 Fonctionnalités

### 1. **Gestion des vidéos (VOD)**

- **Upload** : Réception de chunks signés et vérifiés
- **Stockage** : Sauvegarde dans SQLite avec métadonnées
- **Streaming** : Distribution séquentielle des chunks aux clients
- **Synchronisation** : Partage des métadonnées entre edges

### 2. **Streaming en direct (Live)**

- Réception de chunks en temps réel
- Vérification de signature pour chaque chunk
- Redistribution immédiate aux spectateurs
- Suppression automatique à la fin du live

### 3. **Authentification et sécurité**

- **Authentification des zones** : Génération d'identifiants uniques via JAR
- **Authentification des utilisateurs** : Validation JWT via Supabase
- **Vérification des chunks** : Signature cryptographique pour garantir l'intégrité

### 4. **Synchronisation distribuée**

- Partage automatique de la BDD entre edges au démarrage
- Mise à jour en temps réel via `db/update`
- Gestion des edges multiples pour une même vidéo

### 5. **Monitoring**

- Collecte de métriques système (CPU, RAM, disque)
- Réponse aux requêtes de ping avec statut complet
- Export JSON des métriques

---

## 📝 Workflow typique

### 1. Démarrage d'un edge

```
Démarrage → Génération EDGE_ID → Connexion MQTT
    ↓
Demande d'authentification (auth/zone)
    ↓
Réception des paramètres de chiffrement
    ↓
Synchronisation BDD avec autres edges (db)
    ↓
Prêt à recevoir/servir du contenu
```

### 2. Upload d'une vidéo

```
Streamer → video/upload/{EDGE_ID} (métadonnées)
    ↓
Edge crée streamer + vidéo dans BDD
    ↓
Streamer → video/upload/{EDGE_ID} (chunks signés)
    ↓
Edge vérifie signature + stocke chunks
    ↓
Edge → db/update (notification aux autres edges)
```

### 3. Visionnage d'une vidéo

```
Client → video/watch/{EDGE_ID} (init=1, video_id)
    ↓
Edge → video/watch/{EDGE_ID}/{client_id} (métadonnées)
    ↓
Client → video/watch/{EDGE_ID} (chunk_part++)
    ↓
Edge → video/watch/{EDGE_ID}/{client_id} (chunk)
    ↓
... répète jusqu'à end=1
```

---

## 🔍 Commandes utiles

### Lancer le serveur principal

```bash
python main.py
```

### Lancer le serveur d'authentification

```bash
python auth_edge.py
```

### Consulter la base de données

```bash
sqlite3 edge_cluster.db "SELECT * FROM video;"
```
