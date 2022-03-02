#!/bin/bash

# Preload redis server with necessary modules, and wait for it to initialize
# daemonize while registering necessary redis gears functions before container start.
redis-server --daemonize yes \
             --loadmodule /usr/lib/redis/modules/redisearch.so \
             --loadmodule /usr/lib/redis/modules/redisgears.so \
             PythonHomeDir /opt/redislabs/lib/modules/python3 && sleep 1

# todo: persist it in the image instead of calling it here:
# Register all redis gears functions:
cat /functions/player_functions.py | redis-cli -x RG.PYEXECUTE     # StreamReader - all player actions;
cat /functions/game_functions.py | redis-cli -x RG.PYEXECUTE       # CommandReader - join game / invite / etc;
cat /functions/database_functions.py | redis-cli -x RG.PYEXECUTE   # CommandReader - new user / new game;

# REDIS SEARCH INDEXES:
redis-cli FT.CREATE GAME ON HASH PREFIX 1 GAME: SCHEMA owner TEXT secret TEXT private NUMERIC SORTABLE playercount NUMERIC SORTABLE
redis-cli FT.CREATE USER ON HASH PREFIX 1 USER: SCHEMA name TEXT settings TEXT secret TEXT 


# Persist database insertions
redis-cli save
redis-cli shutdown

# Start server normally
redis-server \
    --loadmodule /usr/lib/redis/modules/redisearch.so \
    --loadmodule /usr/lib/redis/modules/redisgears.so \
    PythonHomeDir /opt/redislabs/lib/modules/python3