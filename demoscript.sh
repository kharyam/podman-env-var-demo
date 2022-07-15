#!/bin/bash

# Demo the Red Hat repo
# https://catalog.redhat.com/software/containers/explore
# Search for postgresql image

# Customization to demo-magic script to change the prompt text
PROMPT_STRING="Container EnvVars"

POSTGRESQL_IMAGE=registry.redhat.io/rhel8/postgresql-12:latest
POSTGRESQL_USER=bob
POSTGRESQL_PASSWORD=securepassword123
POSTGRESQL_DATABASE=demodb

REDHAT_REGISTRY_USERNAME=${REDHAT_REGISTRY_USERNAME:="PLEASE_SET_REGISTRY_USERNAME"}
REDHAT_REGISTRY_PASSWORD=${REDHAT_REGISTRY_PASSWORD:="PLEASE_SET_REGISTRY_PASSWORD"}

POD_NAME=application-pod
CONTAINER_NAME=psql-demo
VM_IP="$(hostname -I | awk '{print $1}') hostname"

# Use demo magic script (https://github.com/paxtonhare/demo-magic) to simulate typing in the terminal via its 'pe' command
. ~/bin/demo-magic.sh

# Pre-cleanup
podman stop $CONTAINER_NAME
podman rmi $POSTGRESQL_IMAGE nextcloud
podman pod rm $POD_NAME
sudo dnf install -y jq postgresql neofetch
clear
neofetch

pe "podman images"

pe "podman login registry.redhat.io -u $REDHAT_REGISTRY_USERNAME -p $REDHAT_REGISTRY_PASSWORD"

pe "podman pull $POSTGRESQL_IMAGE"

pe "podman images"

pe "podman inspect $POSTGRESQL_IMAGE | jq '.[0].Config.Env'"

# Get the env config using go template instead of jq
#pe "podman inspect $POSTGRESQL_IMAGE -f '{{range .Config.Env}}{{println .}}{{end}}'"

pe "podman inspect $POSTGRESQL_IMAGE | jq '.[0].Config.ExposedPorts'"

pe "podman pod create --name $POD_NAME -p 5432:5432 -p 8080:80"

pe "podman pod ls"

pe "podman run --name $CONTAINER_NAME --pod $POD_NAME --rm -d -e POSTGRESQL_USER=$POSTGRESQL_USER -e POSTGRESQL_PASSWORD=$POSTGRESQL_PASSWORD -e POSTGRESQL_DATABASE=$POSTGRESQL_DATABASE $POSTGRESQL_IMAGE"

pe "podman logs $CONTAINER_NAME"

pe "psql postgresql://$POSTGRESQL_USER:$POSTGRESQL_PASSWORD@localhost:5432/$POSTGRESQL_DATABASE -c 'CREATE TABLE example (id SERIAL PRIMARY KEY, first_name VARCHAR(255), last_name VARCHAR(255) );'"

pe "psql postgresql://$POSTGRESQL_USER:$POSTGRESQL_PASSWORD@localhost:5432/$POSTGRESQL_DATABASE -c \"INSERT INTO example (first_name, last_name) VALUES ('John','Doe')\""

pe "podman run -it --rm --name nextcloud --pod $POD_NAME -e POSTGRES_DB=$POSTGRESQL_DATABASE -e POSTGRES_USER=$POSTGRESQL_USER -e POSTGRES_PASSWORD=$POSTGRESQL_PASSWORD -e POSTGRES_HOST=localhost -e NEXTCLOUD_ADMIN_USER=admin -e NEXTCLOUD_ADMIN_PASSWORD=admin -e NEXTCLOUD_TRUSTED_DOMAINS=$VM_IP nextcloud"

pe "podman stop $CONTAINER_NAME" 

pe "podman pod stop $POD_NAME" 

pe "podman pod rm $POD_NAME" 

pe "# 🎉🎉 All Done! 🎉🎉"
