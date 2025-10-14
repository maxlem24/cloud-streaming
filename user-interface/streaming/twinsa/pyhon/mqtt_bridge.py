# mqtt_bridge.py
import argparse, struct, sys, time
from paho.mqtt import client as mqtt_client

def read_exact(n: int) -> bytes:
    buf = bytearray()
    r = sys.stdin.buffer.read
    while len(buf) < n:
        chunk = r(n - len(buf))
        if not chunk:
            raise EOFError("stdin closed")
        buf.extend(chunk)
    return bytes(buf)

def connect(broker: str, port: int, client_id: str):
    cli = mqtt_client.Client(client_id=client_id, clean_session=True)
    # Pas d'auth pour le test; ajoute .username_pw_set si besoin
    def on_connect(c, u, flags, rc):
        if rc == 0:
            print("MQTT connected", file=sys.stderr, flush=True)
        else:
            print(f"MQTT connect failed rc={rc}", file=sys.stderr, flush=True)
    cli.on_connect = on_connect
    cli.connect(broker, port, keepalive=20)
    cli.loop_start()
    return cli

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--broker", default="10.207.130.234")
    ap.add_argument("--port", type=int, default=1883)
    ap.add_argument("--topic", default="cam/1/frame")
    ap.add_argument("--qos", type=int, default=0)
    args = ap.parse_args()

    client = connect(args.broker, args.port, f"py-bridge-{int(time.time()*1000)}")

    try:
        while True:
            # entête 12 octets: int64 timestamp, int32 taille (big-endian)
            header = read_exact(12)
            ts, size = struct.unpack(">qI", header)  # big-endian: >, q=int64, I=uint32
            payload = read_exact(size)
            # publish bytes bruts (JPEG)
            res = client.publish(args.topic, payload, qos=args.qos, retain=False)
            # optionnel: vérifier res.rc == 0
    except EOFError:
        pass
    finally:
        client.loop_stop()
        client.disconnect()

if __name__ == "__main__":
    main()
