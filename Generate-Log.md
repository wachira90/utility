# Python script that auto-generates synthetic logs simultaneously

**JSON (ndjson)**, **pipe-delimited**, and **CSV** formats.

```python
#!/usr/bin/env python3
import argparse, csv, io, json, logging, os, random, socket, string, sys, time
from datetime import datetime
from logging.handlers import RotatingFileHandler

# ---------- Synthetic event generator ----------
USERS   = ["alice", "bob", "charlie", "dora", "eve"]
ACTIONS = ["login", "logout", "read", "write", "delete", "search"]
STATUSES= ["OK", "WARN", "ERROR"]

def rand_ip():
    return ".".join(str(random.randint(1, 254)) for _ in range(4))

def make_event():
    return {
        "user": random.choice(USERS),
        "action": random.choice(ACTIONS),
        "status": random.choices(STATUSES, weights=[85, 10, 5])[0],
        "latency_ms": random.randint(2, 900),
        "ip": rand_ip(),
        "host": socket.gethostname(),
        "trace_id": "".join(random.choices(string.ascii_lowercase + string.digits, k=16)),
    }

# ---------- Custom formatters ----------
class JsonFormatter(logging.Formatter):
    def format(self, record: logging.LogRecord) -> str:
        base = {
            "ts": datetime.utcfromtimestamp(record.created).isoformat(timespec="milliseconds") + "Z",
            "level": record.levelname,
            "message": record.getMessage(),
        }
        ev = getattr(record, "event", {})
        base.update(ev if isinstance(ev, dict) else {})
        return json.dumps(base, ensure_ascii=False)

class PipeFormatter(logging.Formatter):
    # Example: ts|level|message|key1=value1|key2=value2
    def format(self, record: logging.LogRecord) -> str:
        ts = datetime.utcfromtimestamp(record.created).isoformat(timespec="milliseconds") + "Z"
        parts = [ts, record.levelname, record.getMessage()]
        ev = getattr(record, "event", {})
        if isinstance(ev, dict):
            for k, v in ev.items():
                parts.append(f"{k}={v}")
        return "|".join(str(p) for p in parts)

class CSVFormatter(logging.Formatter):
    """
    Writes CSV with stable columns (header on first write).
    """
    def __init__(self, fields, file_handle):
        super().__init__()
        self.fields = fields
        self.file_handle = file_handle
        self.writer = csv.DictWriter(self.file_handle, fieldnames=self.fields, extrasaction="ignore")
        # Write header only if file is empty
        try:
            if self.file_handle.tell() == 0 and (not getattr(self.file_handle, "name", None) or os.path.getsize(self.file_handle.name) == 0):
                self.writer.writeheader()
        except Exception:
            # Fallback: try writing header once
            if self.file_handle.tell() == 0:
                self.writer.writeheader()

    def format(self, record: logging.LogRecord) -> str:
        # We'll return a CSV line; actual writing is done in handler.emit via this formatter
        ts = datetime.utcfromtimestamp(record.created).isoformat(timespec="milliseconds") + "Z"
        ev = getattr(record, "event", {})
        row = {"ts": ts, "level": record.levelname, "message": record.getMessage()}
        if isinstance(ev, dict):
            row.update(ev)
        # Render to an in-memory string (so handler can just write it)
        buf = io.StringIO()
        writer = csv.DictWriter(buf, fieldnames=self.fields, extrasaction="ignore")
        writer.writerow(row)
        return buf.getvalue().rstrip("\n")

# ---------- Handlers ----------
def make_rotating_file_handler(path, formatter):
    os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
    handler = RotatingFileHandler(path, maxBytes=5_000_000, backupCount=3, encoding="utf-8")
    handler.setFormatter(formatter)
    return handler

def build_logger(base_path: str):
    logger = logging.getLogger("loggen")
    logger.setLevel(logging.INFO)
    logger.handlers.clear()

    # JSON (ndjson)
    json_handler = make_rotating_file_handler(f"{base_path}.jsonl", JsonFormatter())
    logger.addHandler(json_handler)

    # Pipe-delimited
    pipe_handler = make_rotating_file_handler(f"{base_path}.pipe", PipeFormatter())
    logger.addHandler(pipe_handler)

    # CSV
    csv_path = f"{base_path}.csv"
    # Open underlying stream so we can let CSVFormatter manage the header
    csv_stream = open(csv_path, "a", encoding="utf-8", newline="")
    csv_fields = ["ts", "level", "message", "user", "action", "status", "latency_ms", "ip", "host", "trace_id"]
    csv_formatter = CSVFormatter(csv_fields, csv_stream)

    class CSVStreamHandler(logging.Handler):
        def emit(self, record):
            line = csv_formatter.format(record)
            csv_stream.write(line + "\n")
            csv_stream.flush()

    csv_handler = CSVStreamHandler()
    logger.addHandler(csv_handler)

    # Also mirror to stdout as JSON for quick inspection
    stdout_handler = logging.StreamHandler(sys.stdout)
    stdout_handler.setFormatter(JsonFormatter())
    logger.addHandler(stdout_handler)

    return logger

# ---------- Main loop ----------
def main():
    ap = argparse.ArgumentParser(description="Auto-generate logs in JSON, pipe, and CSV simultaneously.")
    ap.add_argument("--base-path", default="logs/app", help="Base path for output files (no extension).")
    ap.add_argument("--count", type=int, default=100, help="Number of events to generate. Use -1 for infinite.")
    ap.add_argument("--interval", type=float, default=0.1, help="Seconds between events (e.g., 0.05 = 20 eps).")
    ap.add_argument("--message", default="event", help="Message string for the log record.")
    args = ap.parse_args()

    logger = build_logger(args.base_path)
    i = 0
    try:
        while args.count < 0 or i < args.count:
            event = make_event()
            logger.info(args.message, extra={"event": event})
            i += 1
            if args.interval > 0:
                time.sleep(args.interval)
    except KeyboardInterrupt:
        pass

if __name__ == "__main__":
    main()
```

### What it does

* Generates synthetic events and writes them to:

  * `logs/app.jsonl` (newline-delimited JSON)
  * `logs/app.pipe` (pipe-delimited lines like `ts|level|message|key=value|...`)
  * `logs/app.csv` (CSV with a stable header)
* Also mirrors JSON to stdout for quick tailing.

### Run it

```bash
python3 log_gen.py --base-path logs/app --count 500 --interval 0.05 --message "audit"
# Infinite stream at ~10 events/sec:
python3 log_gen.py --count -1 --interval 0.1
```

### Sample outputs

**JSON (ndjson)**

```
{"ts":"2025-11-21T03:12:45.123Z","level":"INFO","message":"audit","user":"alice","action":"login","status":"OK","latency_ms":42,"ip":"10.23.5.77","host":"ip-10-0-1-5","trace_id":"b8d4e2ac91d3f4af"}
```

**Pipe**

```
2025-11-21T03:12:45.123Z|INFO|audit|user=alice|action=login|status=OK|latency_ms=42|ip=10.23.5.77|host=ip-10-0-1-5|trace_id=b8d4e2ac91d3f4af
```

**CSV**

```
ts,level,message,user,action,status,latency_ms,ip,host,trace_id
2025-11-21T03:12:45.123Z,INFO,audit,alice,login,OK,42,10.23.5.77,ip-10-0-1-5,b8d4e2ac91d3f4af
```

If you want this to plug into an existing app instead of generating synthetic events, I can swap the generator out and wire the formatters/handlers into your app’s logger.


# Timezone Asia/Bangkok

Here’s the **full script** updated to stamp events in **Asia/Bangkok** (UTC+07:00) by default, and with a `--timezone` flag if you want to override it.

```python
#!/usr/bin/env python3
import argparse
import csv
import io
import json
import logging
import os
import random
import socket
import string
import sys
import time
import atexit
from datetime import datetime
from logging.handlers import RotatingFileHandler

# Standard library timezone (Python 3.9+)
from zoneinfo import ZoneInfo

# ---------- Synthetic event generator ----------
USERS   = ["alice", "bob", "charlie", "dora", "eve"]
ACTIONS = ["login", "logout", "read", "write", "delete", "search"]
STATUSES= ["OK", "WARN", "ERROR"]

def rand_ip():
    return ".".join(str(random.randint(1, 254)) for _ in range(4))

def make_event():
    return {
        "user": random.choice(USERS),
        "action": random.choice(ACTIONS),
        "status": random.choices(STATUSES, weights=[85, 10, 5])[0],
        "latency_ms": random.randint(2, 900),
        "ip": rand_ip(),
        "host": socket.gethostname(),
        "trace_id": "".join(random.choices(string.ascii_lowercase + string.digits, k=16)),
    }

# ---------- Custom formatters with timezone ----------
def ts_from_record(record: logging.LogRecord, tz: ZoneInfo) -> str:
    """
    Return ISO 8601 timestamp with milliseconds and numeric offset,
    e.g. 2025-11-21T10:12:45.123+07:00
    """
    return datetime.fromtimestamp(record.created, tz).isoformat(timespec="milliseconds")

class JsonFormatter(logging.Formatter):
    def __init__(self, tz: ZoneInfo):
        super().__init__()
        self.tz = tz

    def format(self, record: logging.LogRecord) -> str:
        base = {
            "ts": ts_from_record(record, self.tz),
            "level": record.levelname,
            "message": record.getMessage(),
        }
        ev = getattr(record, "event", {})
        if isinstance(ev, dict):
            base.update(ev)
        return json.dumps(base, ensure_ascii=False)

class PipeFormatter(logging.Formatter):
    # Example: ts|level|message|key1=value1|key2=value2
    def __init__(self, tz: ZoneInfo):
        super().__init__()
        self.tz = tz

    def format(self, record: logging.LogRecord) -> str:
        parts = [ts_from_record(record, self.tz), record.levelname, record.getMessage()]
        ev = getattr(record, "event", {})
        if isinstance(ev, dict):
            for k, v in ev.items():
                parts.append(f"{k}={v}")
        return "|".join(str(p) for p in parts)

class CSVFormatter(logging.Formatter):
    """
    Produces CSV lines (header is handled once in constructor).
    """
    def __init__(self, fields, file_handle, tz: ZoneInfo):
        super().__init__()
        self.fields = fields
        self.file_handle = file_handle
        self.tz = tz
        self.writer = csv.DictWriter(self.file_handle, fieldnames=self.fields, extrasaction="ignore")
        # Write header only if the file is empty
        try:
            if self.file_handle.tell() == 0 and (
                not getattr(self.file_handle, "name", None) or os.path.getsize(self.file_handle.name) == 0
            ):
                self.writer.writeheader()
        except Exception:
            if self.file_handle.tell() == 0:
                self.writer.writeheader()

    def format(self, record: logging.LogRecord) -> str:
        row = {
            "ts": ts_from_record(record, self.tz),
            "level": record.levelname,
            "message": record.getMessage(),
        }
        ev = getattr(record, "event", {})
        if isinstance(ev, dict):
            row.update(ev)

        buf = io.StringIO()
        writer = csv.DictWriter(buf, fieldnames=self.fields, extrasaction="ignore")
        writer.writerow(row)
        return buf.getvalue().rstrip("\n")

# ---------- Handlers ----------
def make_rotating_file_handler(path, formatter):
    os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
    handler = RotatingFileHandler(path, maxBytes=5_000_000, backupCount=3, encoding="utf-8")
    handler.setFormatter(formatter)
    return handler

def build_logger(base_path: str, tz: ZoneInfo):
    logger = logging.getLogger("loggen")
    logger.setLevel(logging.INFO)
    logger.handlers.clear()

    # JSON (ndjson)
    json_handler = make_rotating_file_handler(f"{base_path}.jsonl", JsonFormatter(tz))
    logger.addHandler(json_handler)

    # Pipe-delimited
    pipe_handler = make_rotating_file_handler(f"{base_path}.pipe", PipeFormatter(tz))
    logger.addHandler(pipe_handler)

    # CSV
    csv_path = f"{base_path}.csv"
    os.makedirs(os.path.dirname(csv_path) or ".", exist_ok=True)
    csv_stream = open(csv_path, "a", encoding="utf-8", newline="")
    atexit.register(lambda: csv_stream.close())
    csv_fields = ["ts", "level", "message", "user", "action", "status", "latency_ms", "ip", "host", "trace_id"]
    csv_formatter = CSVFormatter(csv_fields, csv_stream, tz)

    class CSVStreamHandler(logging.Handler):
        def emit(self, record):
            line = csv_formatter.format(record)
            csv_stream.write(line + "\n")
            csv_stream.flush()

    csv_handler = CSVStreamHandler()
    logger.addHandler(csv_handler)

    # Mirror to stdout as JSON (same timezone)
    stdout_handler = logging.StreamHandler(sys.stdout)
    stdout_handler.setFormatter(JsonFormatter(tz))
    logger.addHandler(stdout_handler)

    return logger

# ---------- CLI / Main ----------
def parse_args():
    ap = argparse.ArgumentParser(description="Auto-generate logs in JSON, pipe, and CSV with timezone-aware timestamps.")
    ap.add_argument("--base-path", default="logs/app", help="Base path for output files (no extension).")
    ap.add_argument("--count", type=int, default=100, help="Number of events to generate. Use -1 for infinite.")
    ap.add_argument("--interval", type=float, default=0.1, help="Seconds between events (e.g., 0.05 = 20 eps).")
    ap.add_argument("--message", default="event", help="Message string for the log record.")
    ap.add_argument(
        "--timezone",
        default="Asia/Bangkok",
        help="IANA timezone name (default: Asia/Bangkok). Examples: UTC, Asia/Singapore, Europe/Berlin",
    )
    return ap.parse_args()

def main():
    args = parse_args()
    try:
        tz = ZoneInfo(args.timezone)
    except Exception as e:
        print(f"Failed to load timezone '{args.timezone}': {e}", file=sys.stderr)
        print("Falling back to UTC.", file=sys.stderr)
        tz = ZoneInfo("UTC")

    logger = build_logger(args.base_path, tz)

    i = 0
    try:
        while args.count < 0 or i < args.count:
            event = make_event()
            logger.info(args.message, extra={"event": event})
            i += 1
            if args.interval > 0:
                time.sleep(args.interval)
    except KeyboardInterrupt:
        pass

if __name__ == "__main__":
    main()
```

### Run it

```bash
# Default: Asia/Bangkok (+07:00)
python3 log_gen_tz.py --count 5

# Override TZ if needed
python3 log_gen_tz.py --timezone UTC --count 3
```

### Example output (stdout JSON)

```
{"ts":"2025-11-21T10:12:45.123+07:00","level":"INFO","message":"event","user":"alice","action":"login","status":"OK","latency_ms":42,"ip":"10.23.5.77","host":"ip-10-0-1-5","trace_id":"b8d4e2ac91d3f4af"}
```

This updates **all** formats (JSONL, pipe, CSV, and stdout) to include the proper `+07:00` offset for **Asia/Bangkok**.



