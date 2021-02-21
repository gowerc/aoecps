

.PHONY: all dbupdate

all:
	./bin/rsql ./analysis/db_init.sql
	Rscript ./analysis/db_meta.R
	Rscript ./analysis/db_matches.R
	Rscript ./analysis/ad_results.R
	Rscript ./analysis/g_boot.R



dbupdate:
	./bin/rsql ./analysis/db_init.sql
	Rscript ./analysis/db_meta.R
	Rscript ./analysis/db_matches.R










