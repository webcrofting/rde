# Rails [Docker|Development] Environment

A simple shell script that creates a Rails Docker Evironment with a Postgres Database

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

### ... bundle

- rde.sh bundle (it rebuilds the docker image)

### ... migrate

- rde.sh run rake db:migrate

### ... generate

- rde.sh run rails g whateveryouwant


## But I want ...

Open a pull request if you care. Or create an issue if you don't care that much.
