# Active-Active Geo-Distributed Multiplayer top-down arcade shooter


World`s first Active-Active Geo-Distributed* Multiplayer top-down arcade shooter. App is made to showcase Redis and Redis Labs modules and their capabilities. This game is literally built on Redis!** 

*Fully supporting Active-Active Geo-Distributed redis infrastructure once deployed using Redis Labs deployments.

**Most of game event interactions are handled by calling RedisGears functions.

Join the arena, avoid projectiles by moving around and dominate others by landing hits!

![game_view_1](https://github.com/VilksJanis/online_game/blob/main/docs/game_view_combo.png?raw=true)

---


## How it Works?
[Video Explanation of redis and Redis Gears functions](https://www.youtube.com/watch?v=EOwTOVoIEp4)

### Architecture

![architecture_1](https://github.com/redis-developer/online_game/blob/main/docs/game_data_loop.png?raw=true)
![architecture_2](https://github.com/redis-developer/online_game/blob/main/docs/redis_player_commands.png?raw=true)
![architecture_3](https://github.com/redis-developer/online_game/blob/main/docs/redis_database_setup.png?raw=true)

**Application stack consists of three main components:**
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

**Redis Gears functions are registered on container startup in the `redis/start_redis.sh`**

- `create_new_game` (CommandReader, args: [`user_id`], optional: [`private`, `secret`]):
    - Creates a hash (`HSET`);
    - Creates an expiry for the hash (`EXPIRE`);
    - Triggered by calling `RG.TRIGGER create_new_game USER:p1_uid 1 secret123`;
    - returns `game_id`;
- `create_new_user` (CommandReader, args: [`uid`], optional: [`settings`, `secret`]):
    - Creates a hash (`HSET`) ;
    - Creates an expiry for the hash (`EXPIRE`);
    - Triggered by calling `RG.TRIGGER create_new_user p1_uid playername '' secret123`;
    - returns `user_id`;
- `find_game` (CommandReader, optional: [`game_id`]):
    - If game_id provided then executes `FT.SEARCH` (see RediSearch bellow);
    - If game not found then trigger `create_new_game`;
    - Triggered by calling `RG.TRIGGER find_game p1_uid`;
    - returns `game_id`;
- `join_game` (CommandReader, args: [`user_id`, `game_id`]):
    - Assigns the user to the game_instance (`HSET`)
    - Increments player count of the game_instance (`HINCRBY`);
    - Triggered by calling `RG.TRIGGER join_game p1_uid g1_gid secret123`;
    - returns `game_id`;
- `leave_game` (CommandReader, args: [ `user_ud`, `game_id`]):
    - Deletes hash field (`HDEL`);
    - Decrements player count of the game instance (`HINCRBY`);
    - Triggered by calling ` RG.TRIGGER leave_game p1_uid g1_gid`;
    - returns `game_id`;
- `user_authorized` (CommandReader, args: [`user_ud`, `game_id`]):
    - Executes three (`HGET`) calls to determine if user is a part of the game instance;
    - returns `game_id`;
- `player_actions` (StreamReader, args: [`action`, `action_args`]):
    - Parses an event received from the user; 
    - Adds a state to `game_states` stream (`XADD`);
    - Publishes state change to subscribers (`PUBLISH`);
    - Triggered by calling `XADD player_actions:g1_gid action p action_args "10,100,0"`.


`player_actions` Stream Reader explained:
1. Client connects to node.js websocket server;
2. With the active connection context the user is being `SUBSCRIBE`d to the `game_id` PubSub channel;
3. From now on all channel messages the user is subscribed to (on the backend) are also forwarded to the websocket (to frontend);
4. `MESSAGE_EVENT_HANDLERS` object stores event -> function mapping, and on an incomming message one of the message event functions is being called (see function list below.)


client message event handler (`MESSAGE_EVENT_HANDLERS`):
- `p` (pose) args: [`user_id`, `x`, `y`, `orientation`]; explanation: client receives a `user_id` position update;
- `c`(click) args: [`user_id`, `x` (where it was clicked at), `y` (where it was clicked at), angle (from the player position to click position)]; explanation: client receives `user_id` click event
- `r` (respawn) args: [`user_id`, `x`, `y`]; explanation: client receives `user_id` has respawned;
- `l` (leave) args: [`user_id`]; explanation: client receives `user_id` has left the game; 
- `j` (join) args: [`user_id`, `x`, `y`]; explanation: client receives `user_id` has joined the game, and `user_id` has spawned in the (`x`, `y`) position
- `uid` (user id) args: [`is_valid`]; explanation: client receives the response weather it is possible to find 'log the user in';
- `gid` (game id) args: [`is_valid`]; explanation: client receives if the user is part of the game (is user authorized)
- `hit` args: [`user_id`]; explanation: client receives a message that `user_id` has been hit / client can remove `user_id` from rendering it;
- `score` args: ['score']; explanation client receives current score of the game.

websocket server event handler (`MESSAGE_EVENT_HANDLERS`):
- `p` (pose) args: [`socket`, `x`, `y`, `orientation`]; explanation: server receives `user_id` position update;
- `c`(click) args: [`socket`, `x` (where it was clicked at), `y` (where it was clicked at), angle (from the player position to click position)]; explanation: server receives `user_id` click event;
- `r` (respawn) args: [`socket`, `x`, `y`] ; explanation: server receives respawn request;
- `l` (leave) args: [`socket`]; explanation: server receives leave event; 
- `j` (join) args: [`socket`, `user_id`, `secret`]; explanation: server receives join request, and authorizes the user
- `uid` (user id) args: [`socket`]; explanation: server receives `user id`;
- `hit` args: [`socket`, `enemy_id`]; explanation: server receives hit event, and validates if it's possilbe;

## RediSearch
**RediSearch indexes are registered on container startup in the `redis/start_redis.sh`**

Created Redis Search indexes: 
```
FT.CREATE GAME ON HASH PREFIX 1 GAME: SCHEMA owner TEXT secret TEXT private NUMERIC SORTABLE playercount NUMERIC SORTABLE

FT.CREATE USER ON HASH PREFIX 1 USER: SCHEMA name TEXT settings TEXT secret TEXT
```

Query to find a game:
```
FT.SEARCH "GAME" "(@playercount:[0 1000])" SORTBY playercount DESC LIMIT 0 1
```


## Data 

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


**WebSocket might be working inconsistently when minimized. For best experience do not run multiple minimized instances.**

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
