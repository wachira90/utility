# Copy permission Folder and File

* Accept `-f` for **file** and `-d` for **directory**.
* If no flag is given → default to file mode.
* Apply **permissions + ownership** from source to destination.
* Support **recursive** ownership/permission when `-d` is used.

Here’s the improved script (`script.sh`):

```bash
#!/bin/bash
# Usage:
#   ./script.sh [-f|-d] source target
#   -f : file mode (default if no flag)
#   -d : directory mode (recursive apply)

MODE="file"

# Parse option
while getopts ":fd" opt; do
  case $opt in
    f) MODE="file" ;;
    d) MODE="dir" ;;
    *) echo "Usage: $0 [-f|-d] source target"
       exit 1 ;;
  esac
done

# Shift processed options
shift $((OPTIND -1))

if [ $# -ne 2 ]; then
    echo "Usage: $0 [-f|-d] source target"
    exit 1
fi

SRC=$1
DEST=$2

# Validate existence
if [ ! -e "$SRC" ]; then
    echo "Source '$SRC' does not exist."
    exit 2
fi
if [ ! -e "$DEST" ]; then
    echo "Destination '$DEST' does not exist."
    exit 3
fi

# Get source info
PERM=$(stat -c "%a" "$SRC")
OWNER=$(stat -c "%u" "$SRC")
GROUP=$(stat -c "%g" "$SRC")

if [ "$MODE" = "file" ]; then
    chmod "$PERM" "$DEST"
    chown "$OWNER":"$GROUP" "$DEST"
    echo "Applied file perms ($PERM) and ownership ($(stat -c "%U:%G" "$SRC")) to '$DEST'"

elif [ "$MODE" = "dir" ]; then
    chmod -R "$PERM" "$DEST"
    chown -R "$OWNER":"$GROUP" "$DEST"
    echo "Applied directory perms ($PERM) and ownership ($(stat -c "%U:%G" "$SRC")) recursively to '$DEST'"
fi
```

---

### 🔹 Example Usage

```bash
# File mode (default)
./script.sh org.txt dest.txt

# Explicit file mode
./script.sh -f org.txt dest.txt

# Directory mode (recursive)
./script.sh -d /path/to/source_dir /path/to/target_dir
```

---

👉 Do you also want the **directory mode** to copy **different permissions per file/subdir** (like `cp --preserve` does), or just take the **top-level source folder permissions/ownership** and apply them everywhere recursively?
