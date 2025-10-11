###squelette de code (vidéo) pour aider à comprendre le fonctionnement du client, et comment/quoi il communique au edge

###############################
#Le streamer envoie et reçoit des json uniquement
###############################

###demande de liste video
publish(client,f"video/liste/{EDGE_ID}", json.dumps({"client_ID":CLIENT_ID}))
    ###reception de la liste video
    ##reçoit json contenant des vidéos sur "video/liste/{EDGE_ID}/{client_ID}":
    {
        "id": "video1",
        "title": "Ma première vidéo",
        "description": "Description de la vidéo",
        "category": "Gaming",
        "live": 0,
        "edges": "edge1,edge2",
        "thumbnail": "thumb1.jpg",
        "streamer_id": "streamer1",
        "created_at": "2025-10-11T10:30:00"
    }




###upload de vidéo
# en 2 temps, au début pour initier la connexion, puis chunk par chunk 


    #au début, il y a pas chunk, chunk part: 
    #apres, il y a pas id_streamer, streamer_nom,category,thumbnail,description
    #init=1 au début =0 apres, et end=1 à la fin =0 avant

    #pour résumé au débu : video_ID, video_nom, description, category, thumbnail, init=1,end="0", streamer_id, streamer_nom
    #pour résumé apres : video_ID, video_nom, chunk, chunk_part, init=0,end="0


    ###reçoit ack sur "video/upload/{EDGE_ID}/{video_ID}", quil vérifie avant de renvoyer le chunk d'apres:
    {
        "video_ID": "video1",
        "EDGE_ID": "edge1"
    }


    #a partir du message 2 (les chunks), ack reçus:
    {
        "video_ID": "video1",
        "chunk_part": "1",
        "EDGE_ID": "edge1"
    }


###visionnage de vidéo (demande de visionnage)
    # en 3 temps, init, envoi et end
    #init=1 au début =0 apres, et end="1" à la fin ="0" avant
    #pour résumé au débu : client_ID, video_ID, init="1"
    #pour résumé apres : client_ID, video_ID, chunk_part, init="0"   ===> noter que ici, chunk part c'est le dernier reçu
    #pour résumé à la fin : client_ID, video_ID, init="0"

    #reçoit : 
        #au debut : {"video_nom": "video1", "video_ID": "video1", "chunk_part": "0", "end": "0"}
        #apres : {"video_nom": "video1", "video_ID": "video1", "chunk": "chunk1", "chunk_part": "N", "end": "0"}
        #à la fin : {"video_nom": "video1", "video_ID": "video1", "end": "1"}
    