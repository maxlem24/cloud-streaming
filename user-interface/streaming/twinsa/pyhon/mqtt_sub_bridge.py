# python/mqtt_sub_bridge.py
import sys, struct, argparse, time
from paho.mqtt import client as mqtt_client

HEADER_FMT = ">qI"  # même header (timestamp ms + taille)
HEADER_SIZE = 12

def connect(broker, port, client_id):
    cli = mqtt_client.Client(client_id=client_id)
    cli.loop_start()
    while True:
        try:
            cli.connect(broker, port, keepalive=30)
            break
        except Exception as e:
            print(f"[SUB] Connexion MQTT échouée: {e}", file=sys.stderr, flush=True)
            time.sleep(1)
    return cli

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--broker", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=1883)
    parser.add_argument("--topic", default="cam/1/frame")
    parser.add_argument("--client-id", default=f"py-sub-{int(time.time()*1000)}")
    args = parser.parse_args()

    cli = connect(args.broker, args.port, args.client_id)
    print(f"[SUB] Connecté à MQTT {args.broker}:{args.port}, sub={args.topic}", flush=True)

    def on_message(client, userdata, msg):
        payload = msg.payload  # bytes (JPEG)
        ts_ms = int(time.time() * 1000)
        header = struct.pack(HEADER_FMT, ts_ms, len(payload))
        try:
            sys.stdout.buffer.write(header)
            sys.stdout.buffer.write(payload)
            sys.stdout.buffer.flush()
        except Exception as e:
            print(f"[SUB] Erreur écriture stdout: {e}", file=sys.stderr, flush=True)

    cli.on_message = on_message
    cli.subscribe(args.topic)

    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        pass
    finally:
        try:
            cli.loop_stop()
            cli.disconnect()
        except:  # noqa
            pass

if __name__ == "__main__":
    main()
