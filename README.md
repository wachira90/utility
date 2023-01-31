# utility
Utility help and support all

## javascript genpassword 

````

function generatePassword(length) {
  var charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*",
      retVal = "";
  for (var i = 0, n = charset.length; i < length; ++i) {
    retVal += charset.charAt(Math.floor(Math.random() * n));
  }
  return retVal;
}

var password = generatePassword(16);
console.log(password);
````

## shell genpassword

````
#!/bin/bash
# Generate random number between 0.001 and 4
RANDOM_NUMBER=$(awk -v min=0.001 -v max=4 'BEGIN{srand(); print (min+rand()*(max-min))}')
# Format the number to 3 decimal places
FORMATTED_NUMBER=$(printf "%.3f" $RANDOM_NUMBER)
echo $FORMATTED_NUMBER
````

## ufw firewall syn flood protect

````
ufw enable

ufw default deny incoming

ufw allow established

ufw allow <port number>/<protocol>

ufw limit <port number>/<protocol>
````

## check http code with delay

````
#!/bin/bash
while true; do
    status=$(curl -s -o /dev/null -w "%{http_code}" https://www.sirivatana.co.th)
    if [ $status -eq 200 ]; then
        echo "OK $(date +'%Y-%m-%d %T')"
    else
        echo "NOT OK $(date +'%Y-%m-%d %T')"
    fi
    RDNUM=$(awk -v min=0.001 -v max=6 'BEGIN{srand(); print (min+rand()*(max-min))}')
    TIME_SLEEP=$(printf "%.3f" $RDNUM)
    echo $TIME_SLEEP
    sleep $TIME_SLEEP
done
````
