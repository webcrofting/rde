#!/bin/bash


function init(){

  if [ -f docker-compose.yml ]; then
    if [ "$1" = "-f" ]; then
      echo "Overwriting existing Dockerfile and docker-compose.yml"
      shift
    else
      echo ""
      echo "== Error =="
      echo "Detected already existing docker-compose.yml."
      echo "If you want to create a new one please delete "
      echo "it first or use -f to force the recreation."
      echo "==========="
      echo ""
      exit 1
    fi
  fi

  if [ -f .rde.conf ]; then
    echo "Loading rde configuration ..."
    source .rde.conf
  else
    if [ -n "$1" ]; then
      PROJECTNAME=$(printf '%s' "${1}" | tr -cd '[[:alnum:]]')
    else
      PROJECTNAME=$(printf '%s' "${PWD##*/}" | tr -cd '[[:alnum:]]')
    fi

    echo "Storing rde configuration ..."
    echo "PROJECTNAME=$PROJECTNAME" > .rde.conf
  fi
  echo "Creating project with projectname: $PROJECTNAME"
  echo "Creating Dockerfile ..."
  cat > Dockerfile <<EOF

FROM rails

EXPOSE 3000

RUN addgroup --gid $(id -g) rails
RUN useradd --uid $(id -u) --gid $(id -g) --home-dir /usr/src/app rails

WORKDIR /usr/src/app
CMD rails s -b 0.0.0.0

COPY ./Gemfile* /usr/src/app/
RUN bundle install --system
RUN mkdir -p /opt/rde
RUN cp Gemfile.lock /opt/rde

EOF
  echo "Creating docker compose file ..."
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
  environment:
    DB_HOST: postgres
  env_file:
    - .env
  links:
    - postgres
  ports:
    - "3000:3000"
EOF

  echo "creating .env file for your local environment variables ..."

  touch .env
  touch Gemfile

  amend_gitignore

}

function amend_gitignore() {
  if [ -f .gitignore ]; then
    if ! grep -Fxq "Dockerfile" .gitignore ; then
      echo "Dockerfile" >> .gitignore
    fi
    if ! grep -Fxq "docker-compose.yml" .gitignore ; then
      echo "docker-compose.yml" >> .gitignore
    fi
  fi
}

function create() {

  if [ ! -f docker-compose.yml ]; then
    echo ""
    echo "== Info =="
    echo "No docker-compose.yml found."
    echo "Calling init ..."
    echo "=========="
    echo ""
    init
  fi

  if [ -d app ]; then
    echo ""
    echo "== Error =="
    echo "There seems to be a rails application already there"
    echo "Not creating new one."
    echo "==========="
    echo ""
    exit 1
  fi


  echo "creating new rails app ... "

  $SUDO_DOCKER docker-compose run --no-deps --rm rails rails new -fB .

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
  $SUDO_DOCKER docker-compose build

  echo "initializing database ..."
  $SUDO_DOCKER docker-compose run --rm rails /bin/bash -c "sleep 5 && rake db:migrate"

  amend_gitignore

}

function bundle() {
  #$SUDO_DOCKER docker-compose run --no-deps --rm -u "root:root" rails bundle install --system
  $SUDO_DOCKER docker-compose build rails
  run cp /opt/rde/Gemfile.lock .
}

function run() {
  $SUDO_DOCKER docker-compose run --rm rails $@

}

function start() {
  $SUDO_DOCKER docker-compose up
}

function destroy_db() {
  $SUDO_DOCKER docker-compose stop postgres
  $SUDO_DOCKER docker-compose rm postgres
  $SUDO_DOCKER docker-compose run --rm postgres /bin/bash -c "rm -rf /var/lib/postgresql/data/*"
}


function usage_init() {

  cat <<EOF
Usage: ${0} init [-f] [PROJECTNAME]

Initializes the RDE. If there is an existing .rde.conf
file, settings are taken from there.

If no .rde.conf exist it creates a new one based on
PROJECTNAME or the current directory if none given.

If there is already a docker-compose.yml in the directory
you have to provide the parameter -f to force the
recreation of Dockerfile and docker-compose.yml
EOF

}

function usage_create() {

  cat <<EOF
Usage: ${0} create

Creates a new rails application in the current directory
EOF

}

function usage_run() {

  cat <<EOF
Usage: ${0} run COMMAND

Runs COMMAND inside an instance of your rails container
EOF

}

function usage_start() {

  cat <<EOF

Usage: ${0} start

Starts the rails application and the linked Postgres
instance.

EOF

}

function usage_bundle() {
  cat <<EOF

Usage: ${0} bundle

Rebuilds the Docker image based on the current Gemfile.

EOF

}

function usage_general(){

  cat <<EOF

Usage: ${0} {init|create|run|start|help} PARAMETERS

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
            Use $0 help COMMAND to get more detailed
            information.

EOF

}

function usage() {

  case "$2" in
    init)
      usage_init
    ;;
    create)
      usage_create
    ;;
    run)
      usage_run
    ;;
    start)
      usage_start
    ;;
    bundle)
      usage_bundle
    ;;
    *)
      usage_general
    ;;
  esac

}


case "$1" in
        init)
                shift
                init $@
        ;;
        create)
                create
        ;;
        run)
                shift
                run $@
        ;;
        start)
                start
        ;;
        bundle)
                bundle
        ;;
        destroy-db)
                destroy_db
        ;;
        help)
                usage $2
        ;;
        *)
                usage
        ;;
esac
