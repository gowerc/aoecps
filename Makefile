

.PHONY: all

all:
	Rscript ./analysis/ad_meta.R
	Rscript ./analysis/ad_raw_results.R
	Rscript ./analysis/ad_results.R
	Rscript ./analysis/g_boot.R











