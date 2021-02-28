pkgload::load_all()
library(dplyr)
library(ggplot2)
library(scales)
library(tidyr)
library(forcats)
library(stringr)

fit <- readRDS("./data/m_iae12_bt.Rds")

efit <- rstan::extract(fit)


x <- as.matrix(efit$alpha)
dat <- tibble(index = 1:nrow(x))
for (i in 1:ncol(x)) dat[civmap(i)] <- x[, i]
dat["ELO Delta (25)"] <- efit$beta


dat2 <- dat %>%
    pivot_longer(-index, names_to = "KEY", values_to = "VAL") %>%
    group_by(KEY) %>%
    summarise(
        lci = quantile(VAL, 0.025),
        med = quantile(VAL, 0.5),
        uci = quantile(VAL, 0.975)
    ) %>%
    arrange(desc(med)) %>%
    mutate(KEY = fct_inorder(KEY))

performance_mid <- dat2 %>%
    filter(KEY != "ELO Delta (25)") %>%
    pull(med) %>%
    mean()

p <- ggplot(data = dat2, aes(x = KEY, group = KEY, ymin = lci, ymax = uci, y = med)) +
    geom_errorbar(width = 0.3) +
    geom_point() +
    geom_hline(yintercept = performance_mid, col = "red") +
    theme_bw() +
    theme(
        axis.text.x = element_text(angle = 50, hjust = 1),
        plot.caption = element_text(hjust = 0)
    ) +
    ylab("Performance Score Delta") +
    xlab("") +
    scale_y_continuous(breaks = pretty_breaks(10)) +
    labs(
        caption = paste0(c(
            "The Y-axis represents the difference in the performance",
            "rating from the reference civilisation (Vikings).",
            "The red line represents the mean performance rating across all",
            "civilisations."
        ), collapse = " ") %>% str_wrap(width = 110)
    )


ggsave(
    plot = p,
    filename = "./outputs/g_iae12_bt_CI.png",
    height = 6,
    width = 9
)
