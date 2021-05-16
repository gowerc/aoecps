# aoecps

Small project to analyse AOE2 civilisation performance statistics in order to identify any evidence of game imbalance

## Build Instructions

The only dependencies for this project are `docker`, `docker-compose` and an internet connection. In theory the project is OS agnostic however the file system mounting has caused issues on windows in the past (I have not tested this recently). That being said, if you are using windows the recommendation is to run the project from WSL2 Ubuntu 20.04.

Instructions to re-run the analysis

- Clone down the project and navigate to it via the terminal
- Build the images by running `docker-compose build`
- Enable the containers by running `docker-compose up -d`
- Enter the analytic container via `docker-compose exec analysis bash`
- Build the database by running `snakemake -j1 db`
- Remove prior analysis files via snakemake -j1 clean`
- Re-run the analysis via `snakemake -j1 all` 
- Finally once done close the containers via `docker-compose down`


