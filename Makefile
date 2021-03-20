SHELL:=/bin/bash 


.PHONY: all dbupdate clean

all: dbupdate outputs/report.html

clean:
	rm data/*.Rds

dbupdate:
	./bin/rsql ./analysis/db_init.sql
	Rscript ./analysis/db_game_meta.R
	Rscript ./analysis/db_matches.R 

outputs=\
	outputs/g_ia_slice.png\
	outputs/g_iae12_bt_civ.png\
	outputs/g_iae12_bt_cc.png\
	outputs/g_iae12_bt_cu.png \
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



###### VADs

data/iae12.Rds: analysis/ad_iae12.R
	Rscript $<



###### Outputs


outputs/g_iae12_bt_civ.png: analysis/g_iae12_bt_civ.R data/iae12.Rds
	Rscript $<

outputs/g_iae12_bt_cc.png: analysis/g_iae12_bt_cc.R data/iae12.Rds
	Rscript $<

outputs/g_iae12_bt_cu.png: analysis/g_iae12_bt_cu.R data/iae12.Rds
	Rscript $<

outputs/g_ia_slice.png: analysis/g_ia_slice.R data/iae12.Rds
	Rscript $<

# g_iae12 collection
outputs/g_iae12_ELODIST.png: analysis/g_iae12.R data/iae12.Rds
	Rscript $<

outputs/g_iae12_PR.png: analysis/g_iae12.R data/iae12.Rds
	Rscript $<

outputs/g_iae12_VERDIST.png: analysis/g_iae12.R data/iae12.Rds
	Rscript $<
	
outputs/g_iae12_WR.png: analysis/g_iae12.R data/iae12.Rds
	Rscript $<
