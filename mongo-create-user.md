# mongo create user

mongo 4.4.17

ssh -L 27017:localhost:27017 wachira@1.2.3.4 -p 22

```sh
docker exec -it mongodb mongo

use admin

# for login

db.auth("admin", "xxxxxxxxxxxxx")

use admin

db.createUser({
  user: "admin",
  pwd: "xxxxxxxxxxaaaaaaaaa",
  roles: [ { role: "userAdminAnyDatabase", db: "admin" }, "readWriteAnyDatabase" ]
})
```
