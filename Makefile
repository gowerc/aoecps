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

outputs=\
	outputs/g_ia_slice.Rds\
	outputs/g_tae12_bt_civ.png\
	outputs/g_iae12_bt_civ.png\
	outputs/g_iae12_bt_cc.png\
	outputs/g_iae12_bt_cu.png \
	outputs/g_ae12_bt_civ.png\
	outputs/g_iae12_desc_ELODIST.png\
	outputs/g_iae12_desc_PR.png\
	outputs/g_iae12_desc_VERDIST.png\
	outputs/g_iae12_desc_WR.png\
	outputs/g_iae12_desc_WRPR.png\
	outputs/g_iae12_cvc_clust.png\
	outputs/t_iae12_cvc_opt.Rds\
	outputs/g_iae12_cvc_civs.Rds
	
	


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

data/tae12.Rds: analysis/ad_tae12.R
	Rscript $<


###### Outputs


outputs/g_iae12_bt_civ.png: analysis/g_iae12_bt_civ.R data/iae12.Rds
	Rscript $<

outputs/g_tae12_bt_civ.png: analysis/g_tae12_bt_civ.R data/tae12.Rds
	Rscript $<

outputs/g_iae12_bt_cc.png: analysis/g_iae12_bt_cc.R data/iae12.Rds
	Rscript $<

outputs/g_iae12_bt_cu.png: analysis/g_iae12_bt_cu.R data/iae12.Rds
	Rscript $<

outputs/g_ae12_bt_civ.png: analysis/g_ae12_bt_civ.R outputs/g_iae12_bt_civ.png outputs/g_tae12_bt_civ.png
	Rscript $<

outputs/g_ia_slice.Rds: analysis/g_ia_slice.R data/iae12.Rds
	Rscript $<


#### Civ v Civ collection
outputs/g_iae12_cvc_civs.Rd: analysis/g_iae12_cvc.R data/iae12.Rds
	Rscript $<

outputs/t_iae12_cvc_opt.Rds: analysis/g_iae12_cvc.R data/iae12.Rds
	Rscript $<

outputs/g_iae12_cvc_clust.png: analysis/g_iae12_cvc.R data/iae12.Rds
	Rscript $<



#### g_iae12 collection
outputs/g_iae12_desc_ELODIST.png: analysis/g_iae12_desc.R data/iae12.Rds
	Rscript $<

outputs/g_iae12_desc_PR.png: analysis/g_iae12_desc.R data/iae12.Rds
	Rscript $<

outputs/g_iae12_desc_VERDIST.png: analysis/g_iae12_desc.R data/iae12.Rds
	Rscript $<
	
outputs/g_iae12_desc_WR.png: analysis/g_iae12_desc.R data/iae12.Rds
	Rscript $<

outputs/g_iae12_desc_WRPR.png: analysis/g_iae12_desc.R data/iae12.Rds
	Rscript $<
