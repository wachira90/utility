# check folder if exist

## shell script

```
#!/bin/bash
path=$1
if [ -d "$path" ]; then
  echo "OK"
else
  echo "DEAD"
fi
```

## check command

```
./script.sh /path/to/check
```

This script uses the -d option of the test command (which is equivalent to [ -d ]) to check if the specified path is a directory. You can use the -e option to check if the path exists, regardless of whether it's a file or a directory.

```
if [ -e "$path" ]; then
  echo "OK"
else
  echo "DEAD"
fi
```
