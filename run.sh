#!/bin/bash
DOCKER_BUILDKIT=1
docker-compose --project-name web -f ./docker-compose.yml up --build
