SHELL:=/bin/bash 

.PHONY: all dbupdate

all: dbupdate outputs/report.html

dbupdate:
	./bin/rsql ./analysis/db_init.sql
	Rscript ./analysis/db_game_meta.R
	Rscript ./analysis/db_matches.R

outputs=\
	outputs/g_ia_slice.png\
	outputs/g_iae12_bt_CI.png\
	outputs/g_iae12_ELODIST.png\
	outputs/g_iae12_PR.png\
	outputs/g_iae12_VERDIST.png\
	outputs/g_iae12_WR.png


outputs/report.html: analysis/report.Rmd $(outputs)
	Rscript -e "\
        rmarkdown::render(\
            input = './analysis/report.Rmd',\
            knit_root_dir = '/app',\
            output_dir = './outputs',\
            output_file = 'report.html'\
        )"


data/iae12.Rds: analysis/ad_iae12.R
	Rscript $<

data/m_iae12_bt.Rds: analysis/m_iae12_bt.R data/iae12.Rds
	Rscript $<

outputs/g_ia_slice.png: analysis/g_ia_slice.R data/iae12.Rds
	Rscript $<

outputs/g_iae12_bt_CI.png: analysis/g_iae12_bt.R data/m_iae12_bt.Rds
	Rscript $<

outputs/g_iae12_ELODIST.png: analysis/g_iae12.R data/iae12.Rds
	Rscript $<

outputs/g_iae12_PR.png: analysis/g_iae12.R data/iae12.Rds
	Rscript $<

outputs/g_iae12_VERDIST.png: analysis/g_iae12.R data/iae12.Rds
	Rscript $<
	
outputs/g_iae12_WR.png: analysis/g_iae12.R data/iae12.Rds
	Rscript $<
