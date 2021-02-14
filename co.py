import socket
import json
import sys
import ssl

HOST = "10.0.0.10"
PORT = 5042

ctx = ssl.SSLContext(ssl.PROTOCOL_TLS)
ctx.verify_mode = ssl.CERT_REQUIRED
ctx.load_verify_locations("/etc/logstash/logstash.pem")
ctx.load_cert_chain(
    certfile="/etc/logstash/logstash.pem", keyfile="/etc/logstash/logstash.key"
)

csock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

scsock = ctx.wrap_socket(csock)
scsock.connect((HOST, PORT))

msg = {"@message": "python test message", "@tags": ["python", "test"]}

scsock.sendall(json.dumps(msg))
scsock.send("\n")

scsock.close()
sys.exit(0)
