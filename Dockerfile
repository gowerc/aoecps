FROM rocker/r-ver:4.0.3

## Required system dependencies
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
    jq \
    git \
    libv8-dev \
    vim \
    pandoc \
    libxt-dev

## Install postgressql-cleint 13 (to communicate with db from the command line)
RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" | tee  /etc/apt/sources.list.d/pgdg.list
RUN apt-get update && apt-get -y install postgresql-client-13


# Fix Rstudio package manager to use a specific date cutoff  (20th January 2021)
RUN sed -i "s/focal\/latest/focal\/908360/g" /usr/local/lib/R/etc/Rprofile.site

# Install required libraries
RUN Rscript -e "options(warn=2);\
    install.packages(c(\
        'tidyverse',\
        'dplyr',\
        'tidyr',\
        'tibble',\
        'stringr',\
        'assertthat',\
        'lubridate',\
        'httr',\
        'glue',\
        'languageserver',\
        'devtools',\
        'RPostgres',\
        'DBI',\
        'rmarkdown',\
        'knitr',\
        'DT',\
        'dbplyr',\
        'forcats',\
        'jsonlite'\
    ))"

RUN mkdir /app
WORKDIR /app


