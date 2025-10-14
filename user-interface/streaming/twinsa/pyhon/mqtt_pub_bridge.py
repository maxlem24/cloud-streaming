# python/mqtt_pub_bridge.py
import sys, struct, argparse, time
from paho.mqtt import client as mqtt_client

# En-tête binaire : 12 octets = int64 (timestamp ms) + uint32 (taille frame)
HEADER_FMT = ">qI"  # big-endian: long long (8) + unsigned int (4)
HEADER_SIZE = 12

def connect(broker, port, client_id):
    cli = mqtt_client.Client(client_id=client_id)
    cli.loop_start()
    while True:
        try:
            cli.connect(broker, port, keepalive=30)
            break
        except Exception as e:
            print(f"[PUB] Connexion MQTT échouée: {e}", file=sys.stderr, flush=True)
            time.sleep(1)
    return cli

def read_exact(n):
    buf = b""
    while len(buf) < n:
        chunk = sys.stdin.buffer.read(n - len(buf))
        if not chunk:
            return None
        buf += chunk
    return buf

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--broker", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=1883)
    parser.add_argument("--topic", default="cam/1/frame")
    parser.add_argument("--client-id", default=f"py-pub-{int(time.time()*1000)}")
    args = parser.parse_args()

    cli = connect(args.broker, args.port, args.client_id)
    print(f"[PUB] Connecté à MQTT {args.broker}:{args.port}, topic={args.topic}", flush=True)

    while True:
        header = read_exact(HEADER_SIZE)
        if header is None:
            print("[PUB] Fin de stdin (arrêt)", file=sys.stderr, flush=True)
            break
        ts_ms, size = struct.unpack(HEADER_FMT, header)
        payload = read_exact(size)
        if payload is None:
            print("[PUB] Flux tronqué", file=sys.stderr, flush=True)
            break

        # Publication binaire (QoS 0)
        res = cli.publish(args.topic, payload, qos=0, retain=False)
        if res.rc != 0:
            print(f"[PUB] Publish rc={res.rc}", file=sys.stderr, flush=True)

    try:
        cli.loop_stop()
        cli.disconnect()
    except:  # noqa
        pass

if __name__ == "__main__":
    main()
