# check repo new update

shell script that checks if a Git repository has updates and prints "Update" or "No update" accordingly:

## shell script

````
#!/bin/bash

# change directory to the repository
cd /path/to/repo

# fetch updates from remote
git fetch

# check if there are updates
UPSTREAM=${1:-'@{u}'}
LOCAL=$(git rev-parse @)
REMOTE=$(git rev-parse "$UPSTREAM")
BASE=$(git merge-base @ "$UPSTREAM")

if [ $LOCAL = $REMOTE ]; then
    echo "No update"
elif [ $LOCAL = $BASE ]; then
    echo "Update"
else
    echo "Diverged"
fi
````

## bat script

````
@echo off

rem change directory to the repository
cd /path/to/repo

rem fetch updates from remote
git fetch

rem check if there are updates
set "UPSTREAM=%1"
if not defined UPSTREAM set "UPSTREAM=@{u}"

for /f "delims=" %%a in ('git rev-parse @') do set "LOCAL=%%a"
for /f "delims=" %%a in ('git rev-parse "%UPSTREAM%"') do set "REMOTE=%%a"
for /f "delims=" %%a in ('git merge-base @ "%UPSTREAM%"') do set "BASE=%%a"

if "%LOCAL%" == "%REMOTE%" (
    echo No update
) else if "%LOCAL%" == "%BASE%" (
    echo Update
) else (
    echo Diverged
)
````
