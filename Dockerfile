FROM rocker/r-ver:4.0.3

RUN apt-get update && apt-get install -y \
    apt-utils \
    libssl-dev \
    libsasl2-dev \
    curl \
    wget \
    libz-dev \
    libxml2-dev \
    libcurl4-openssl-dev \
    unixodbc-dev \
    libpq-dev \
    gnupg2 \
    git

## Install postgressql-cleint 13 (to communicate with db from the command line)
RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" | tee  /etc/apt/sources.list.d/pgdg.list
RUN apt-get update && apt-get -y install postgresql-client-13


ENV RENV_PATHS_CACHE=/renv/cache \
    RENV_PATHS_SOURCE=/renv/source \
    RENV_PATHS_BINARY=/renv/bin \
    RENV_VERSION=0.12.5

RUN mkdir /app
WORKDIR /app







