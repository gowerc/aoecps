


data_wr_avg <- function(matchmeta, players){
    result <- matchmeta %>% 
        select(match_id, winning_team, rating_diff_mean) %>% 
        mutate(rating_diff_mean = if_else(winning_team == 1, rating_diff_mean, -rating_diff_mean))

    players2 <- players %>% 
        inner_join(result, by= "match_id")

    civlist <- players %>% 
        arrange(civ_name) %>% 
        distinct(civ_name) %>% 
        pull(civ_name)

    ridge <- cross_df(list(civ_win = civlist, civ_lose = civlist)) %>% 
        mutate(match_id = paste0("ridge", 1:n()))

    team_win <- players2 %>% 
        filter(team == winning_team) %>% 
        select(match_id, civ_win = civ_name)

    team_lose <- players2 %>% 
        filter(team != winning_team) %>% 
        select(match_id, civ_lose = civ_name)

    assert_that(
        nrow(team_win) == nrow(team_lose)
    )

    res <- team_win %>% 
        left_join(team_lose, by = "match_id") %>% 
        bind_rows(ridge) %>% 
        filter(civ_win != civ_lose) %>% 
        mutate(civ_win = factor(civ_win, levels = civlist)) %>% 
        mutate(civ_lose = factor(civ_lose, levels = civlist)) %>% 
        mutate(swap = as.numeric(civ_win) > as.numeric(civ_lose)) %>%
        mutate(civ1 = if_else(swap, civ_lose, civ_win)) %>%
        mutate(civ2 = if_else(swap, civ_win, civ_lose)) %>%
        mutate(term = sprintf("%s_%s", civ1, civ2)) %>%
        mutate(val = if_else(swap, -1, 1)) %>% 
        group_by(match_id) %>% 
        mutate(val = val / n()) %>% 
        ungroup() %>% 
        group_by(match_id, term) %>% 
        summarise(val = sum(val), .groups = "drop") 

    res2 <- res %>% 
        select(match_id, term, val) %>% 
        spread(term, val, fill = 0) %>% 
        left_join(select(result, match_id, rating_diff_mean), by = "match_id") %>% 
        select(-match_id) %>% 
        mutate(result = 1)


    mod <- glm(
        data = res2,
        formula = result ~ 0 + .
    )


    coefs <- coef(mod)
    coefs_names <- names(coefs)

    trans <- matrix(nrow = length(civlist), ncol = length(coefs))
    rownames(trans) <- civlist

    for(i in seq_along(civlist)) {
        civ <- civlist[i]
        v1 <- str_detect(coefs_names, paste0("^",civ, "_")) * 1
        v2 <- str_detect(coefs_names, paste0("_",civ, "$")) * 1
        trans[i,] <- v1 - v2
    }

    trans <- trans / length(civlist)

    tibble(
        civ_name = civlist,
        lp = as.vector(trans %*% matrix(ncol = 1, coefs)),
        se = sqrt(diag(trans %*% vcov(mod) %*% t(trans))),
    ) %>% 
        mutate(
            lci = invlogit(lp - 1.96 * se) * 100,
            est = invlogit(lp) * 100,
            uci = invlogit(lp + 1.96 * se) * 100,
            wr = est
        )
}




plot_wr_avg <- function(dat){
    
    pdat <- dat %>% 
        arrange(desc(est)) %>% 
        mutate(coef = fct_inorder(civ_name))


    footnotes <- c(
        "The error bars represent the 95% confidence interval<br/>"
    ) %>%
        as_footnote()

    ggplot(data = pdat, aes(x = coef, group = coef, ymin = lci, ymax = uci, y = est)) +
        geom_hline(yintercept = 50, col = "red", alpha = 0.65) + 
        geom_errorbar(width = 0.3) +
        geom_point() +
        theme_bw() +
        theme(
            axis.text.x = element_text(angle = 50, hjust = 1),
            plot.caption = element_text(hjust = 0)
        ) +
        labs(caption = footnotes) +
        ylab("Win Rate (%)") +
        xlab("") +
        scale_y_continuous(breaks = pretty_breaks(10))
}
