SHELL:=/bin/bash 


.PHONY: all dbupdate clean

all: dbupdate outputs/report.html

clean:
	rm -f data/*
	rm -f outputs/*

dbupdate:
	./bin/rsql ./analysis/db_init.sql
	Rscript ./analysis/db_game_meta.R
	Rscript ./analysis/db_matches.R 


###### VADs

data/ia.Rds: analysis/ad_ia.R
	Rscript $<

data/ta.Rds: analysis/ad_ta.R
	Rscript $<


###### Bradley Terry outputs

outputs/g_ia_bt_civ.png: analysis/g_ia_bt_civ.R data/ia.Rds 
	Rscript $<

outputs/g_ia_bt_civ_PR.png: analysis/g_ia_bt_civ.R data/ia.Rds data/ia_pr.Rds
	Rscript $<

outputs/g_ia_bt_cu.png: analysis/g_ia_bt_cu.R data/ia.Rds data-raw/civ_unit_map.csv
	Rscript $<

outputs/g_ta_bt_civ.png: analysis/g_ta_bt_civ.R data/ta.Rds
	Rscript $<

outputs/g_ta_bt_civ_PR.png: analysis/g_ta_bt_civ.R data/ta.Rds data/ta_pr.Rds
	Rscript $<

outputs/g_bt_civ.png: analysis/g_bt_civ.R outputs/g_ia_bt_civ.png outputs/g_ta_bt_civ.png
	Rscript $<

outputs_bt=\
	outputs/g_ia_bt_civ.png\
	outputs/g_ia_bt_civ_PR.png\
	outputs/g_ta_bt_civ.png\
	outputs/g_ta_bt_civ_PR.png\
	outputs/g_ia_bt_cu.png\
	outputs/g_bt_civ.png


#### Civ v Civ collection
outputs/g_ia_cvc_civs_meta.Rds: analysis/g_ia_cvc.R data/ia.Rds
	Rscript $<

outputs/t_ia_cvc_opt.Rds: analysis/g_ia_cvc.R data/ia.Rds
	Rscript $<

outputs/g_ia_cvc_clust.png: analysis/g_ia_cvc.R data/ia.Rds
	Rscript $<

outputs_cvc=\
	outputs/g_ia_cvc_civs_meta.Rds\
	outputs/t_ia_cvc_opt.Rds\
	outputs/g_ia_cvc_clust.png


#### g_ia Descriptives
outputs/g_ia_desc_ELODIST.png: analysis/g_ia_desc.R data/ia.Rds
	Rscript $<

outputs/g_ia_desc_PR.png: analysis/g_ia_desc.R data/ia.Rds
	Rscript $<

outputs/g_ia_desc_VERDIST.png: analysis/g_ia_desc.R data/ia.Rds
	Rscript $<
	
outputs/g_ia_desc_WR.png: analysis/g_ia_desc.R data/ia.Rds
	Rscript $<

data/ia_pr.Rds: analysis/g_ia_desc.R data/ia.Rds
	Rscript $<

outputs_i_desc=\
	outputs/g_ia_desc_ELODIST.png\
	outputs/g_ia_desc_PR.png\
	outputs/g_ia_desc_VERDIST.png\
	outputs/g_ia_desc_WR.png


#### g_ta Descriptives
outputs/g_ta_desc_ELODIST.png: analysis/g_ta_desc.R data/ta.Rds
	Rscript $<

outputs/g_ta_desc_PR.png: analysis/g_ta_desc.R data/ta.Rds
	Rscript $<

outputs/g_ta_desc_VERDIST.png: analysis/g_ta_desc.R data/ta.Rds
	Rscript $<
	
outputs/g_ta_desc_WR.png: analysis/g_ta_desc.R data/ta.Rds
	Rscript $<

data/ta_pr.Rds: analysis/g_ta_desc.R data/ta.Rds
	Rscript $<

outputs_t_desc=\
	outputs/g_ta_desc_ELODIST.png\
	outputs/g_ta_desc_PR.png\
	outputs/g_ta_desc_VERDIST.png\
	outputs/g_ta_desc_WR.png


#### Misc
outputs/g_ia_slice.png: analysis/g_ia_slice.R data/ia.Rds
	Rscript $<

outputs/g_ta_slice.png: analysis/g_ta_slice.R data/ta.Rds
	Rscript $<

outputs/g_pr.png: analysis/g_pr.R data/ia_pr.Rds data/ta_pr.Rds
	Rscript $<

outputs_meta=\
	outputs/g_ia_slice.png\
	outputs/g_ta_slice.png\
	outputs/g_pr.png

outputs=\
	$(outputs_meta)\
	$(outputs_i_desc)\
	$(outputs_t_desc)\
	$(outputs_cvc)\
	$(outputs_bt)
	





outputs/report.html: analysis/report.Rmd $(outputs)
	Rscript -e "\
        rmarkdown::render(\
            input = './analysis/report.Rmd',\
            knit_root_dir = '/app',\
            output_dir = './outputs',\
            output_file = 'report.html'\
        )"