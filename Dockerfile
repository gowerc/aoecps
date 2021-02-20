FROM rocker/r-ver:4.0.3

RUN apt-get update && apt-get install -y \
    apt-utils \
    libssl-dev \
    libsasl2-dev \
    curl \
    wget \
    libz-dev \
    git

ENV RENV_PATHS_CACHE=/renv/cache
ENV RENV_PATHS_SOURCE=/renv/source
ENV RENV_PATHS_BINARY=/renv/bin
ENV RENV_VERSION=0.12.5

RUN mkdir /app
WORKDIR /app
COPY . .

RUN R -e "install.packages('remotes', repos = c(CRAN = 'https://cloud.r-project.org'))"
RUN R -e "remotes::install_github('rstudio/renv@${RENV_VERSION}')"








