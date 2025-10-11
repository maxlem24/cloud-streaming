# Quand le streamer demare un live : 
# Premier message (démarage du live)
# publish(client,f"live/upload/{EDGE_ID}", json.dumps({"live":True,"video_id":live_id, "video_nom":"live_nom", "streamer_id":streamer_id, "streamer_nom":streamer_nom, "category":category, "description":description, "thumbnail":thumbnail, "signature":signature, "end":0}))

# N messages de diffusion du live : 
# publish(client,f"live/upload/{EDGE_ID}", json.dumps({"video_id":live_id, "signature":signature, "end":0, "chunk":chunk, "chunk_part":N}))

# Dernier message (fin du live):
# publish(client,f"live/upload/{EDGE_ID}", json.dumps({"video_id":live_id, "signature":signature, "end":1}))