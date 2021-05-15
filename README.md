# Active-Actove Geo-Distributed Multiplayer top-down arcade shooter

[Redis Labs "Build on Redis" 2021 hackathon](https://hackathons.redislabs.com/hackathons/build-on-redis-hackathon) participation project.

World`s first Active-Active Geo-Distributed* Multiplayer top-down arcade shooter. App is made to showcase Redis and Redis Labs modules and their capabilities. This game is literally built on Redis!** 

*Fully supporting Active-Active Geo-Distributed redis infrastructure once deployed using Redis Labs deployments.

**Most of game event interactions are handled by calling RedisGears functions.

Join the arena, avoid projectiles by moving around and dominate others by landing hits!

<a><img src="docs/game_view.png" width="33%" height="auto"></a>
<a><img src="docs/game_view_2.png" width="33%" height="auto"></a>
<a><img src="docs/game_view_3.png" width="33%" height="auto"></a>

---

## How it Works?
### Architecture

<a><img src="docs/game_data_loop.png" width="98.5%" height="auto"></a>
<a><img src="docs/redis_player_commands.png" width="49%" width="49%" height="auto"></a>
<a><img src="docs/redis_database_setup.png" width="49%" height="auto"></a>

Application stack consists of three main components:
* JavaScript client:
    - uses phaser 3 game engine for rendering and physics simulations;
    - captures user inputs and sends inputs to the backend;
* Node.js backend:
    - Serves as a WebServer;
    - Provides a WebSocket server;
    - Enables Redis API;
    - Ensures User -> Redis -> User event communication;
* Redis:
    - Uses RedisGears to define game functions (functionality);
    - Uses RediSearch to enable robust querying experience;
    - Stores game state (enables data decoupling from node.js backend);
    - Validates user inputs (using RedisGears functions);
    - Provides Game API (again, RedisGears).

## RedisGears function list:

- create_new_game ("CommandReader"):
    - Called
    - Return
- create_new_user ("CommandReader"):
    - Called
    - Return
- find_game ("CommandReader"):
    - Called
    - Return
- join_game ("CommandReader"):
    - Called
    - Return
- leave_game ("CommandReader"):
    - Called
    - Return
- user_authorized ("CommandReader"):
    - Called
    - Return
- player_actions ("StreamReader"):
    - Called
    - Return


## RediSearch

Used to find available games:
```
FT.CREATE GAME ON HASH PREFIX 1 GAME: SCHEMA owner TEXT secret TEXT private NUMERIC SORTABLE playercount NUMERIC SORTABLE

FT.CREATE USER ON HASH PREFIX 1 USER: SCHEMA name TEXT settings TEXT secret TEXT
```

```
FT.SEARCH "GAME" "(@playercount:[0 1000])" SORTBY playercount DESC LIMIT 0 1
```


## Running locally


### Prerequisites

- docker
- docker-compose


### Running
Run following commands from the online_game directory
```
docker-compose up
```

access online WebServer via http://127.0.0.1:8080


### Debuging / Troubleshooting
If you are connected to the game, but player charecter is not showing then you most likeley don't have a connection to the WebSocket server ws://127.0.0.1:8002.

If you are being kicked out of the game, then congratulations, you most likely have found a bug,


**General steps**

To fully reset the states:
Try removing the redis dump.rdb located in `./redis/redis_data/dump.rdb`.
```
rm redis/redis_data/dump.rdb
```
or 

```
sudo rm redis/redis_data/dump.rdb

```
then run start up containers
```
docker-compose up --build
```


**Other troubleshooting**

Perhaps ports `8080` or `8082` are already registered. You can change port mapping in `docker-compose.yaml` to, for example, `8081:8080` and `8083:8002`. 

```
  backend:
    build:
      dockerfile: ./dockerfiles/Dockerfile_node_backend
      context: .
    environment:
      - NODE_ENV=development
    volumes: 
      - ./game_conf.json:/game_config/game_conf.json
    ports:
      - 8080:8080
      - 8082:8082
    restart: always
```

### Cleanup

Run following commands to clean up your running environment.
```
docker-compose down
rm redis/redis_data/dump.rdb
```
or 

```
docker-compose down
sudo rm redis/redis_data/dump.rdb

```
