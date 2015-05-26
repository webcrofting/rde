#!/bin/bash


function init(){

  if [ -f docker-compose.yml ]; then
    echo ""
    echo "== Error =="
    echo "Detected already existing docker-compose.yml."
    echo "If you want to create a new one please delete it first."
    echo "==========="
    echo ""
    exit 1
  fi

  echo "creating Dockerfile ..."
  cat > Dockerfile <<EOF

FROM rails

RUN addgroup --gid $(id -g) rails
RUN useradd --uid $(id -u) --gid $(id -g) --home-dir /usr/src/app rails

EOF
  echo "creating docker compose file ..."
  cat > docker-compose.yml <<EOF
postgres:
  image: postgres
  volumes:
    - "/srv/docker/rde/postgres-data$(pwd):/var/lib/postgresql/data"
  environment:
    POSTGRES_PASSWORD: rails_db
    POSTGRES_USER: rails_db

rails:
  build: .
  working_dir: /usr/src/app
  user: "$(id -u):$(id -g)"
  volumes:
    - ".:/usr/src/app"
  env_file:
    - .env
  links:
    - postgres
EOF

  echo "creating .env file for your local environment variables ..."

  touch .env

}



function create(){

  if [ ! -f docker-compose.yml ]; then
    echo "No docker-compose.yml found."
    echo "Calling init ..."
    init
  fi

  echo "creating new rails app ... "

  $SUDO_DOCKER docker-compose run --no-deps --rm rails rails new -B .

  echo "adjusting database.yml ... "
  cat > config/database.yml <<EOF
default: &default
  host: <%= ENV["DB_HOST"] %>
  adapter: postgresql
  encoding: unicode
  pool: 5
  database: rails_db
  username: rails_db
  password: rails_db

development:
  <<: *default

test:
  adapter: sqlite3
  pool: 5
  timeout: 5000
  database: db/test.sqlite3

production:
  <<: *default
EOF

  echo "adjusting Gemfile ..."

  sed -i "s/^gem 'sqlite3'$/gem 'pg'/g" Gemfile

  echo "updating bundle ..."
  $SUDO_DOCKER docker-compose run --no-deps --rm rails bundle install

  echo "initializing database ..."
  $SUDO_DOCKER docker-compose run --rm rails rake db:migrate

}

function bundle() {
  $SUDO_DOCKER docker-compose run --no-deps --rm -u "root:root" rails bundle install --system

}

function run() {
  echo "$1 $2"
  shift
  echo $@
  $SUDO_DOCKER docker-compose run --rm rails $@

}

function start() {
  $SUDO_DOCKER docker-compose up
}


function usage() {
  cat <<EOF

Usage: ${0} {init|create|run|start|help}

init:   Creates a docker-compose.yml

create: Bootstraps a new rails app in the current
        directory and sets up database access for
        the rails app.

run:    Runs a command inside the docker container.
        (Useful eg. for running rake db:migrate )

start:  Starts the rails app

bundle: Installs new Gems and commits container

help:   Displays this usage message

EOF

}


case "$1" in
        init)
                init
        ;;
        create)
                create
        ;;
        run)
                run $@
        ;;
        start)
                start
        ;;
        bundle)
                bundle
        ;;
        help)
                usage
        ;;
        *)
                usage
        ;;
esac
