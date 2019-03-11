# Developing Microservices - Node, React, and Docker

A microservices sample with nodejs/React/Postgres, monitored by New Relic and deployed on EKS.

## License

This repository is a stripped down version from https://github.com/mjhea0.

## Architecture

| Name             | Service | Container | Tech                 |
|------------------|---------|-----------|----------------------|
| Web              | Web     | web       | React, React-Router  |
| Movies API       | Movies  | movies    | Node, Express        |
| Movies DB        | Movies  | movies-db | Postgres             |
| Users API        | Users   | users     | Node, Express        |
| Users DB         | Users   | users-db  | Postgres             |

### Setup

1. Fork/Clone this repo

### Build and Run the App

#### Fire up the Containers

Build the images:

```sh
$ docker-compose build
```

Run the containers:

```sh
$ docker-compose up -d
```

#### Sanity Check

Test out the following services...

##### (1) Users - http://localhost:3002

| Endpoint        | HTTP Method | CRUD Method | Result        |
|-----------------|-------------|-------------|---------------|
| /users/ping     | GET         | READ        | `pong`        |
| /users/register | POST        | CREATE      | add a user    |
| /users/login    | POST        | CREATE      | log in a user |
| /users/user     | GET         | READ        | get user info |

##### (2) Movies - http://localhost:3004

| Endpoint      | HTTP Method | CRUD Method | Result                    |
|---------------|-------------|-------------|---------------------------|
| /movies/ping  | GET         | READ        | `pong`                    |
| /movies/user  | GET         | READ        | get all movies by user    |
| /movies       | POST        | CREATE      | add a single movie        |

##### (3) Web - http://localhost:4000

| Endpoint   | HTTP Method | CRUD Method | Result                  |
|-------------|-------------|-------------|------------------------|
| /           | GET         | READ        | render main page       |
| /login      | GET         | READ        | render login page      |
| /register   | GET         | READ        | render register page   |
| /logout     | GET         | READ        | log a user out         |
| /collection | GET         | READ        | render collection page |

##### (4) Movies Database and (5) Users Database

If Docker then get the container id from `docker ps` and then open `psql`:

```sh
$ docker exec -ti <container-id> psql -U postgres
```

If Kubernetes then get the pod id from `kubectl get pods` and then open `psql`:

```sh
$ kubectl exec -ti <pod-id> psql -U postgres
```

#### Additional Commands

To stop the containers:

```sh
$ docker-compose stop
```

To bring down the containers:

```sh
$ docker-compose down
```

To force a build:

```sh
$ docker-compose build --no-cache
```

To stop all containers:

```sh
$ docker container stop $(docker container ls -aq)
```

To remove all containers:

```sh
$ docker container rm $(docker container ls -aq)
```

To remove all images:

```sh
$ docker rmi $(docker images -q)
```

To recover space:

```sh
$ docker system prune --volumes
```
