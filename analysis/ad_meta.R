library(jsonlite)
library(httr)


x <- GET(
    url = "https://aoe2.net/api/strings?game=aoe2de&language=en"
)

stop_for_status(x)

# content(x)


y <- jsonlite::fromJSON(txt = content(x))


saveRDS(
    file = "data/meta.Rds",
    object = y
)
