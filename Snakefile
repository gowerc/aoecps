
rule all:
    input:
        "outputs/index.html",
        "outputs/report_rm_solo_any.html",
        "outputs/report_rm_solo_open.html",
        "outputs/report_rm_solo_closed.html",
        "outputs/report_rm_team_any.html",
        "outputs/report_rm_team_open.html",
        "outputs/report_rm_team_closed.html",
        "outputs/report_ew_solo_all.html",
        "outputs/report_ew_team_all.html"


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

###### VAD
rule:
    output: "data/ad_matchmeta.Rds"
    input: "analysis/ad_ana.R"
    shell: "Rscript {input[0]}"


###### Reports
rule:
    input: "analysis/report.Rmd", "data/ad_matchmeta.Rds"
    output: "outputs/report_{suffix}.html"
    shell:
        """
        Rscript -e "
            rmarkdown::render(
                input = '{input[0]}',
                knit_root_dir = '/app',
                output_dir = './outputs',
                output_file = 'report_{wildcards.suffix}.html',
                params = list(type = '{wildcards.suffix}')
            )"
        """

rule:
    input:"analysis/index.Rmd"
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