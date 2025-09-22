# Generate a self-signed TLS certificate 

(`server.crt`) and private key (`server.key`) for NGINX, with the **Organization Unit (OU)** set to `MyCompany`.

example:

```bash
#!/bin/bash

# Script to generate self-signed SSL/TLS certificate for NGINX
# Output: server.key (private key), server.crt (certificate)

CERT_DIR="./ssl"
CERT_KEY="${CERT_DIR}/server.key"
CERT_CRT="${CERT_DIR}/server.crt"

# Create directory if not exists
mkdir -p "$CERT_DIR"

# Generate private key and certificate
openssl req -x509 -nodes -newkey rsa:2048 \
  -keyout "$CERT_KEY" \
  -out "$CERT_CRT" \
  -days 365 \
  -subj "/C=US/ST=California/L=SanFrancisco/O=MyCompany/OU=MyCompany/CN=localhost"

echo "✅ SSL/TLS certificate and key generated:"
echo "   Private Key: $CERT_KEY"
echo "   Certificate: $CERT_CRT"
```

### 🔹 Explanation

* `rsa:2048` → generates a 2048-bit RSA private key.
* `-nodes` → no password (needed for NGINX to start without prompts).
* `-days 365` → valid for 1 year (you can adjust).
* `-subj` → sets certificate fields:

  * `C=US` → Country
  * `ST=California` → State
  * `L=SanFrancisco` → Locality
  * `O=MyCompany` → Organization
  * `OU=MyCompany` → Organizational Unit
  * `CN=localhost` → Common Name (adjust to your server’s domain if needed).

---

👉 Do you want me to extend this script so it **automatically configures NGINX** with the generated cert and key, or just keep it limited to generating the files?
