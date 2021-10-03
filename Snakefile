
rule all:
    input:
        "outputs/index.html",
        "outputs/report_A.html",
        "outputs/report_B.html",
        "outputs/report_C.html",
        "outputs/report_D.html",
        "outputs/report_E.html",
        "outputs/report_F.html"



rule db:
    shell:
        """
        python3 ./analysis/db_update.py
        """

rule clean:
    shell:
        """
        rm -f data/*
        rm -f outputs/*
        """


rule killr:
    shell:
        """
        kill -9 $(ps -u root | awk '$4=="R" {{ printf "%s ", $1 }}')
        """

###### VADs

rule:
    output: "data/ad_matchmeta.Rds"
    input: "analysis/ad_ana.R"
    shell: "Rscript {input[0]}"


###### Report

rule:
    input: "analysis/report.Rmd", "data/ad_matchmeta.Rds"
    output: "outputs/report_A.html"
    shell:
        """
        Rscript -e "
            rmarkdown::render(
                input = '{input[0]}',
                knit_root_dir = '/app',
                output_dir = './outputs',
                output_file = 'report_A.html',
                params = list(
                    lower_elo = 1200,
                    lower_elo_slice = 800,
                    mapclass = 'Open',
                    leaderboard = '1v1 Random Map',
                    lower_dt = lubridate::ymd_hms('2021-08-25 01:00:00')
                )
            )"
        """


rule:
    input: "analysis/report.Rmd", "data/ad_matchmeta.Rds"
    output: "outputs/report_B.html"
    shell:
        """
        Rscript -e "
            rmarkdown::render(
                input = '{input[0]}',
                knit_root_dir = '/app',
                output_dir = './outputs',
                output_file = 'report_B.html',
                params = list(
                    lower_elo = 1200,
                    lower_elo_slice = 800,
                    mapclass = 'Closed',
                    leaderboard = '1v1 Random Map',
                    lower_dt = lubridate::ymd_hms('2021-08-25 01:00:00')
                )
            )"
        """


rule:
    input: "analysis/report.Rmd", "data/ad_matchmeta.Rds"
    output: "outputs/report_C.html"
    shell:
        """
        Rscript -e "
            rmarkdown::render(
                input = '{input[0]}',
                knit_root_dir = '/app',
                output_dir = './outputs',
                output_file = 'report_C.html',
                params = list(
                    lower_elo = 2000,
                    lower_elo_slice = 1500,
                    mapclass = 'Open',
                    leaderboard = 'Team Random Map',
                    lower_dt = lubridate::ymd_hms('2021-08-25 01:00:00')
                )
            )"
        """


rule:
    input: "analysis/report.Rmd", "data/ad_matchmeta.Rds"
    output: "outputs/report_D.html"
    shell:
        """
        Rscript -e "
            rmarkdown::render(
                input = '{input[0]}',
                knit_root_dir = '/app',
                output_dir = './outputs',
                output_file = 'report_D.html',
                params = list(
                    lower_elo = 2000,
                    lower_elo_slice = 1500,
                    mapclass = 'Closed',
                    leaderboard = 'Team Random Map',
                    lower_dt = lubridate::ymd_hms('2021-08-25 01:00:00')
                )
            )"
        """


rule:
    input: "analysis/report.Rmd", "data/ad_matchmeta.Rds"
    output: "outputs/report_E.html"
    shell:
        """
        Rscript -e "
            rmarkdown::render(
                input = '{input[0]}',
                knit_root_dir = '/app',
                output_dir = './outputs',
                output_file = 'report_E.html',
                params = list(
                    lower_elo = 1100,
                    lower_elo_slice = 800,
                    mapclass = 'Any',
                    leaderboard = '1v1 Empire Wars',
                    lower_dt = lubridate::ymd_hms('2021-08-25 01:00:00')
                )
            )"
        """


rule:
    input: "analysis/report.Rmd", "data/ad_matchmeta.Rds"
    output: "outputs/report_F.html"
    shell:
        """
        Rscript -e "
            rmarkdown::render(
                input = '{input[0]}',
                knit_root_dir = '/app',
                output_dir = './outputs',
                output_file = 'report_F.html',
                params = list(
                    lower_elo = 1100,
                    lower_elo_slice = 800,
                    mapclass = 'Any',
                    leaderboard = 'Team Empire Wars',
                    lower_dt = lubridate::ymd_hms('2021-08-25 01:00:00')
                )
            )"
        """

rule:
    input: "analysis/index.Rmd"
    output: "outputs/index.html"
    shell:
        """
        Rscript -e "
            rmarkdown::render(
                input = '{input[0]}',
                knit_root_dir = '/app',
                output_dir = './outputs',
                output_file = 'index.html'
            )"
        """