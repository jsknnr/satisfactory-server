# satisfactory-server

Run Satisfactory dedicated server in a container. Optionally includes helm chart for running in Kubernetes.

**Disclaimer:** This is not an official image. No support, implied or otherwise is offered to any end user by the author or anyone else. Feel free to do what you please with the contents of this repo.
## Usage

The processes within the container do **NOT** run as root. Everything runs as the user steam (gid:10000/uid:10000 by default). If you exec into the container, you will drop into `/home/steam` as the steam user. Satisfactory will be installed to `/home/steam/satisfactory`. Any persistent volumes should be mounted to `/home/steam/satisfactory` and be owned by 10000:10000. If you need to run as a different GID/UID you can build your own image and set the build arguments for CONTAINER_GID and CONTAINER_UID to specify to new values.

### Ports
Server to client is game port UDP, but the server manager also needs TCP. So which ever port you use for Game Port needs both TCP and UDP.

| Port | Protocol | Default |
| ---- | -------- | ------- |
| Game Port | UDP & TCP | 7777 |
| Query Port | UDP | 15777 |
| Beacon Port | UDP | 15000 |


### Environment Variables

| Name | Description | Default | Required |
| ---- | ----------- | ------- | -------- |
| GAME_PORT | Port for server connections. | 7777 | False |
| QUERY_PORT | Port for query of server. | 15777 | False |
| BEACON_PORT | Port for the beacon? | 15000 | False |
| MULTIHOME | Address for server to listen on. You likely won't need to change this. | 0.0.0.0 | False |

### Docker

To run the container in Docker, run the following command:

```bash
docker volume create satisfactory-persistent-data
docker run \
  --detach \
  --name satisfactory-server \
  --mount type=volume,source=satisfactory-persistent-data,target=/home/steam/satisfactory \
  --publish 7777:7777/udp \
  --publish 7777:7777/tcp \
  --publish 15777:15777/udp \
  --publish 15000:15000/udp \
  --env=GAME_PORT=7777 \
  --env=QUERY_PORT=15777 \
  --env=BEACON_PORT=15000 \
  --env=MULTIHOME=0.0.0.0 \
  sknnr/satisfactory-server:latest
```

### Docker Compose

To use Docker Compose, either clone this repo or copy the `compose.yaml` file out of the `container` directory to your local machine. Edit the compose file to change the environment variables to the values you desire and then save the changes. Once you have made your changes, from the same directory that contains the compose and the env files, simply run:

```bash
docker-compose up -d
```

To bring the container down:

```bash
docker-compose down
```

compose.yaml file:
```yaml
services:
  satisfactory:
    image: sknnr/satisfactory-server:latest
    ports:
      - "7777:7777/udp"
      - "7777:7777/tcp"
      - "15777:15777/udp"
      - "15000:15000/udp"
    environment:
      GAME_PORT: "7777"
      QUERY_PORT: "15777"
      BEACON_PORT: "15000"
      MULTIHOME: "0.0.0.0"
    volumes:
      - satisfactory-persistent-data:/home/steam/satisfactory
    stop_grace_period: 90s

volumes:
  satisfactory-persistent-data:
```

### Podman

To run the container in Podman, run the following command:

```bash
podman volume create satisfactory-persistent-data
podman run \
  --detach \
  --name satisfactory-server \
  --mount type=volume,source=satisfactory-persistent-data,target=/home/steam/satisfactory \
  --publish 7777:7777/udp \
  --publish 7777:7777/tcp \
  --publish 15777:15777/udp \
  --publish 15000:15000/udp \
  --env=GAME_PORT=7777 \
  --env=QUERY_PORT=15777 \
  --env=BEACON_PORT=15000 \
  --env=MULTIHOME=0.0.0.0 \
  sknnr/satisfactory-server:latest
```

### Kubernetes

I've built a Helm chart and have included it in the `helm` directory within this repo. Modify the `values.yaml` file to your liking and install the chart into your cluster. Be sure to create and specify a namespace as I did not include a template for provisioning a namespace.

## Troubleshooting

### Connectivity

If you are having issues connecting to the server once the container is deployed, I promise the issue is not with this image. You need to make sure that the ports are open on your router as well as the container host where this container image is running. You will also have to port-forward the game-port and query-port from your router to the private IP address of the container host where this image is running. After this has been done correctly and you are still experiencing issues, your internet service provider (ISP) may be blocking the ports and you should contact them to troubleshoot.

### Storage

I recommend having Docker or Podman manage the volume that gets mounted into the container. However, if you absolutely must bind mount a directory into the container you need to make sure that on your container host the directory you are bind mounting is owned by 10000:10000 by default (`chown -R 10000:10000 /path/to/directory`). If the ownership of the directory is not correct the container will not start as the server will be unable to persist the savegame.
