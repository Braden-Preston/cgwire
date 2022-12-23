# Kitsu Development

Any time you are going to start development, source the `setup` file. This will fully bootstrap an environment for you to work with. Some services like `postgres` are hosted in docker, but `kitsu` and `zou` will be hosted from your local machine and routed through `nginx`.

```bash
source setup.sh
```

To begin active development, source the `setup` file again. This will set the environment from the `.env` file in the root directory.


**Initialize a new postgres container database**

```bash
sudo docker exec -it cgwire_postgres_1 psql -c 'CREATE DATABASE zoudb;' -U postgres
python zou/zou/cli.py clear-db
python zou/zou/cli.py init-db
python zou/zou/cli.py init-data
```
