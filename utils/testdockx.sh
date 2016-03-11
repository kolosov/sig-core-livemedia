#!/bin/bash

docker build --rm -t xclock1 -f /home/Dockerfile .
docker run -ti --rm -e DISPLAY=$DISPLAY -v /tmp/.X11-unix/:/tmp/.X11-unix xclock1
