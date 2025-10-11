    subscribe(client, "auth/zone")  
    subscribe(client, "auth/user")  


        if (msg.topic=="auth/user"):
            message_json=json.loads(msg.payload.decode())
            user=message_json["user"]
            password=message_json["password"]
            ID=message_json["ID"]

        if (msg.topic=="auth/zone"):
            # on reçoi : ID
            message_json=json.loads(msg.payload.decode())
            ID=message_json["ID"]
            #VERIF niveau bdd le user
            msg_a_envoyer={"param1":"param... A REMPLIR######################","status":"ok"}
            message_json=json.dumps(msg_a_envoyer)
            publish(client,f"auth/zone/{ID}", message_json)