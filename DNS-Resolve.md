## DNS Resolve

### 1. Simple curl with hostname

Just use the hostname directly in the URL:

```bash
curl http://example.com
```

---

### 2. Specify a Host header (useful for virtual hosts)

If you're hitting an IP but need to send a hostname:

```bash
curl http://1.2.3.4 -H "Host: example.com"
```

---

### 3. Resolve hostname to a specific IP (override DNS)

This is very common for testing:

```bash
curl --resolve example.com:80:1.2.3.4 http://example.com
```

For HTTPS:

```bash
curl --resolve example.com:443:1.2.3.4 https://example.com
```

---

### 4. Ignore SSL issues (self-signed, mismatched hostname)

```bash
curl -k https://example.com
```

---

### 5. Verbose output for debugging

```bash
curl -v https://example.com
```

---

### 6. Combine Host + HTTPS + custom IP (advanced test)

```bash
curl -v https://example.com \
  --resolve example.com:443:1.2.3.4
```

