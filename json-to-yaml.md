# JSON TO YAML 

**Python example** that reads a JSON file and converts it to YAML, then saves it to a `.yaml` file.

---

### ✅ **Python Script: `json_to_yaml.py`**

```python
import json
import yaml

# Input and output file paths
json_file = "input.json"
yaml_file = "output.yaml"

# Read JSON file
with open(json_file, "r") as jf:
    data = json.load(jf)

# Convert and write YAML file
with open(yaml_file, "w") as yf:
    yaml.dump(data, yf, sort_keys=False, default_flow_style=False)

print(f"Converted {json_file} → {yaml_file}")
```

---

### 📦 **Requirements**

Install PyYAML if not already available:

```bash
pip install pyyaml
```

---

### 🧩 **Example Input (`input.json`):**

```json
{
  "apiVersion": "v1",
  "kind": "Pod",
  "metadata": {
    "name": "nginx-pod",
    "labels": {
      "app": "nginx"
    }
  },
  "spec": {
    "containers": [
      {
        "name": "nginx",
        "image": "nginx:latest",
        "ports": [
          { "containerPort": 80 }
        ]
      }
    ]
  }
}
```

### 🧾 **Generated Output (`output.yaml`):**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
  labels:
    app: nginx
spec:
  containers:
    - name: nginx
      image: nginx:latest
      ports:
        - containerPort: 80
```

---

Would you like me to modify this script to **accept command-line arguments** (e.g., `python json_to_yaml.py input.json output.yaml`)?
