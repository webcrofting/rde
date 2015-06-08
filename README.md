# Rails [Docker|Development] Environment

A simple shell script that creates a Rails Docker Environment with a Postgres Database

## Why?

Because I wanted something better than RVM to do my rails development.


## How do I ...

### ... get started

- Install [docker-compose](http://docs.docker.com/compose/)
- Copy rde.sh to your path
- Go to the directory where you want to create your rails app
- call rde.sh create
- call rde.sh start
- point your browser to localhost:3000

### ... use it for an existing project

- Go to your rails directory 
- call rde.sh init

### ... bundle

- rde.sh bundle (it rebuilds the docker image)

### ... migrate

- rde.sh run rake db:migrate

### ... generate

- rde.sh run rails g whateveryouwant

## Usage

```
Usage: rde.sh {init|create|run|start|bundle|destroy-db|help} PARAMETERS

init:       Creates a docker-compose.yml
create:     Bootstraps a new rails app in the current
            directory and sets up database access for
            the rails app.
run:        Runs a command inside the docker container.
            (Useful eg. for running rake db:migrate )
start:      Starts the rails app
bundle:     Installs new Gems and commits container
destroy-db: Destroys the database container and erases the data
help:       Displays this usage message
            Use rde.sh help COMMAND to get more detailed
            information.

```


## But I want ...

Open a pull request if you care. Or create an issue if you don't care that much.
