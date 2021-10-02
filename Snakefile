
rule all:
    input: 
        "outputs/report.html"

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
    output: "data/ta.Rds"
    input: "analysis/ad_ta.R"
    shell: "Rscript {input[0]}"

rule:
    output: "data/ia.Rds"
    input: "analysis/ad_ia.R"
    shell: "Rscript {input[0]}"


###### Bradley Terry outputs

rule ia_bt_civ:
    output: "outputs/g_ia_bt_civ.png", "outputs/g_ia_bt_civ_PR.png" 
    input: "analysis/g_ia_bt_civ.R", "data/ia.Rds"
    shell: "Rscript {input[0]}"

rule ia_bt_cu:
    output: "outputs/g_ia_bt_cu.png"
    input: "analysis/g_ia_bt_cu.R", "data/ia.Rds", "data-raw/civ_unit_map.csv"
    shell: "Rscript {input[0]}"

rule ta_bt_civ:
    output: "outputs/g_ta_bt_civ.png", "outputs/g_ta_bt_civ_PR.png"
    input: "analysis/g_ta_bt_civ.R", "data/ta.Rds", "data/ta_pr.Rds"
    shell: "Rscript {input[0]}"

rule bt_civ:
    output: "outputs/g_bt_civ.png"
    input: "analysis/g_bt_civ.R", "outputs/g_ia_bt_civ.png", "outputs/g_ta_bt_civ.png"
    shell: "Rscript {input[0]}"


#### Civ v Civ collection
rule ia_cvc:
    output:
        "outputs/g_ia_cvc_civs_meta.Rds",
        "outputs/t_ia_cvc_opt.Rds",
        "outputs/g_ia_cvc_clust.png"
    input:
        "analysis/g_ia_cvc.R",
        "data/ia.Rds"
    shell: "Rscript {input[0]}"


#### g_ia Descriptives
rule i_desc:
    output:
        "outputs/g_ia_desc_ELODIST.png",
        "outputs/g_ia_desc_PR.png",
        "outputs/g_ia_desc_VERDIST.png",
        "outputs/g_ia_desc_WR.png",
        "data/ia_pr.Rds"
    input:
        "data/ia.Rds",
        prog = "analysis/g_ia_desc.R"
    shell:
        "Rscript {input.prog}"


#### g_ta Descriptives

rule t_desc:
    output:
        "outputs/g_ta_desc_ELODIST.png",
        "outputs/g_ta_desc_PR.png",
        "outputs/g_ta_desc_VERDIST.png",
        "outputs/g_ta_desc_WR.png",
        "data/ta_pr.Rds"
    input:
        "data/ta.Rds",
        prog = "analysis/g_ta_desc.R"
    shell:
        "Rscript {input.prog}"


######### Misc Outputs

rule misc1:
    output: "outputs/g_ia_slice.png"
    input: "analysis/g_ia_slice.R", "data/ia.Rds"
    shell: "Rscript {input[0]}"

rule misc2:
    output: "outputs/g_ta_slice.png"
    input: "analysis/g_ta_slice.R", "data/ta.Rds"
    shell: "Rscript {input[0]}"

rule misc3:
    output: "outputs/g_pr.png"
    input: "analysis/g_pr.R", "data/ia_pr.Rds", "data/ta_pr.Rds"
    shell: "Rscript {input[0]}"


######### Main Report

OUTPUTS = [ i.output for i in [
    rules.misc1,
    rules.misc2,
    rules.misc3,
    rules.i_desc,
    rules.t_desc,
    rules.ia_cvc,
    rules.ia_bt_civ,
    rules.ia_bt_cu,
    rules.ta_bt_civ,
    rules.bt_civ
]]

rule report:
    input: "analysis/report.Rmd", OUTPUTS
    output: "outputs/report.html"
    shell:
        """
        Rscript -e "
            rmarkdown::render(
                input = '{input[0]}',
                knit_root_dir = '/app',
                output_dir = './outputs',
                output_file = 'report.html'
            )"
        """


