library(dplyr)
library(purrr)

C1C2_offset <- 0.0075
C1C3_offset <- 0.015
C4C5_offset <- 0.02
C4C6_offset <- 0.04
C7C8_offset <- 0.02
C7C9_offset <- 0.04

C1_C2 <- 0.53
C1_C3 <- C1_C2 + 0.025
C1_C4 <- 0.62
C1_C5 <- C1_C4 + 0.025
C1_C6 <- C1_C4 + 0.05
C1_C7 <- 0.51
C1_C8 <- C1_C7 + 0.015
C1_C9 <- C1_C7 + 0.03
C1_C10 <- 0.42

C2_C3 <- C1_C3 - C1C2_offset
C2_C4 <- C1_C4 - C1C2_offset
C2_C5 <- C1_C5 - C1C2_offset
C2_C6 <- C1_C6 - C1C2_offset
C2_C7 <- C1_C7 - C1C2_offset
C2_C8 <- C1_C8 - C1C2_offset
C2_C9 <- C1_C9 - C1C2_offset
C2_C10 <- C1_C10 - C1C2_offset

C3_C4 <- C1_C4 - C1C3_offset
C3_C5 <- C1_C5 - C1C3_offset
C3_C6 <- C1_C6 - C1C3_offset
C3_C7 <- C1_C7 - C1C3_offset
C3_C8 <- C1_C8 - C1C3_offset
C3_C9 <- C1_C9 - C1C3_offset
C3_C10 <- C1_C10 - C1C3_offset

C4_C5 <- 0.51
C4_C6 <- C4_C5 + 0.01
C4_C7 <- 0.55
C4_C8 <- C4_C7 + 0.02
C4_C9 <- C4_C7 + 0.04
C4_C10 <- 0.57

C5_C6 <- C4_C6 - C4C5_offset
C5_C7 <- C4_C7 - C4C5_offset
C5_C8 <- C4_C8 - C4C5_offset
C5_C9 <- C4_C9 - C4C5_offset
C5_C10 <- C4_C10 - C4C5_offset

C6_C7 <- C4_C7 - C4C6_offset
C6_C8 <- C4_C8 - C4C6_offset
C6_C9 <- C4_C9 - C4C6_offset
C6_C10 <- C4_C10 - C4C6_offset

C7_C8 <- 0.51
C7_C9 <- C7_C8 + 0.01
C7_C10 <- 0.58

C8_C9 <- C7_C9 + C7C8_offset
C8_C10 <- C7_C10 + C7C8_offset

C9_C10 <- C7_C9 + C7C9_offset
library(glue)

mat <- matrix(nrow = 10, ncol = 10)
for(i in 1:10) for(j in 1:10){
    if (i == j) mat[i, j] <- 0.5
    if (i < j) mat[i, j] <- get(glue("C{i}_C{j}"))
    if (i > j) mat[i, j] <- (1 - get(glue("C{j}_C{i}")))
}

rowMeans(mat)









###### OLD



get_new_elo <- function( old_elo, op_elo, won){
    RA <- old_elo
    RB <- op_elo
    EA <- 1 / ( 1 + 10 ^((RB-RA)/400))
    new_elo <- RA + 32 * ( won - EA)
    return(new_elo)
}

invlogit <- function(x) {
    1 / (1 + exp(-x))
}


get_match_results <- function(n_games, players){
    n_players <- length(players)
    index_range <- 1:n_players

    min_elo_init <- -log(n_players) * 100
    max_elo_init <-  log(n_players) * 100

    true_scores <- map_dbl(players, "true_score")
    elos <- qunif(pnorm(true_scores), min_elo_init, max_elo_init)

    matches <- vector(mode = "list", length = n_games)

    for(i in 1:n_games){
        next_player_index <- sample(index_range, size = 1)
        
        player_margin <- 50
        
        op_index <- index_range[
            index_range <= next_player_index + player_margin &
                index_range >= next_player_index - player_margin &
                index_range != next_player_index
        ] %>%
            sample(1)
    
        elos <- elos[order(elos)]
    
        p1 <- elos[next_player_index]
        p2 <- elos[op_index]
    
        p1_ts <- true_scores[[names(p1)]]
        p2_ts <- true_scores[[names(p2)]]
    
        p1_civ <- players[[names(p1)]]$pick_fun()
        p2_civ <- players[[names(p2)]]$pick_fun()
        
        res <- rbinom(1, 1, p = invlogit(
            p1_ts - p2_ts +
            CIVS[p1_civ] - CIVS[p2_civ]
        ))
    
        matches[[i]] <- list(
            p1 = names(p1),
            p2 = names(p2),
            p1_elo = p1[[1]],
            p2_elo = p2[[1]],
            p1_civ = p1_civ,
            p2_civ = p2_civ,
            result = res
        )
        
        elos[next_player_index] <- get_new_elo(p1, p2, res)
        elos[op_index] <- get_new_elo(p2, p1, 1- res)
        
    }
    dat <- map_df(matches, as_tibble)
    return(dat)
}


get_match_summary <- function(dat){
    players <- c(dat$p1, dat$p2) %>% unique()
    players <- players[order(players)]

    dat2 <- dat %>%
        filter(p1_civ != p2_civ) %>%
        mutate(p1 = factor(p1, levels = players)) %>%
        mutate(p2 = factor(p2, levels = players))

    bind_rows(
        dat %>% select(civ = p1_civ, result),
        dat %>% mutate(result = 1- result) %>% select(civ = p2_civ, result)
    ) %>%
        group_by(civ) %>%
        summarise(
            wc = sum(result),
            n = n(),
            wr = wc / n ,
            wr_l = wr - 1.96 * sqrt( wr*(1-wr)/n),
            wr_u = wr + 1.96 * sqrt( wr*(1-wr)/n)
        )  %>%
        ungroup() %>%
        mutate(pr = n / sum(n))
}

get_match_summary_bt <- function(dat){
    players <- c(dat$p1, dat$p2) %>% unique()
    players <- players[order(players)]

    dat2 <- dat %>%
        filter(p1_civ != p2_civ) %>%
        mutate(p1 = factor(p1, levels = players)) %>%
        mutate(p2 = factor(p2, levels = players)) %>%
        mutate(p1_elo = p1_elo / 25) %>% 
        mutate(p2_elo = p2_elo / 25) 

    amat <- model.matrix(~ p1_civ - 1 + p1_elo, data = dat2)
    bmat <- model.matrix(~ p2_civ - 1 + p2_elo, data = dat2)

    stopifnot(
        ncol(amat) == ncol(bmat),
        nrow(amat) == nrow(bmat)
    )

    dmat <- amat - bmat
    colnames(dmat) <- c(names(CIVS), "delo")

    mdat <- as_tibble(dmat) %>% select(-J)
    mdat$result <- dat2$result

    mod <- glm(
        formula = result ~ . -1,
        family = binomial(),
        data = mdat
    )

    tibble(
        civs = names(CIVS),
        score_real = CIVS,
        score = c(mod$coefficients[1:(length(CIVS)-1)],0),
        se = c(sqrt(diag(vcov(mod))[1:(length(CIVS)-1)]),0),
        lci = score - 1.96 * se,
        uci = score + 1.96 * se
    )
}

CIVS = c(
    "A" = 0.45,
    "B" = 0.4,
    "C" = 0.35,
    "D" = 0.3,
    "E" = 0.25,
    "F" = 0.2,
    "G" = 0.15,
    "H" = 0.1,
    "I" = 0.05,
    "J" = 0
)

get_players <- function(n_players, allo_fun){
    players <- vector(mode = "list", length = n_players)
    for (i in 1:n_players) {
        true_score = rnorm(1, 0.5)
        players[[i]] <- list(
            true_score = true_score,
            pick_fun = allo_fun(ts = true_score)
        )
    }
    names(players) <- paste0("p", 1:n_players)
    return(players)
}

type_0 <- function(ts){
    function(){
        sample(names(CIVS), 1)
    }
}


type_1 <- function(ts){
    x <- list(
        function(){
            "A"
        },
        function(){
            sample(names(CIVS), 1)
        }
    )
    index <- sample(1:length(x), 1, p=c(0.3, 0.8))
    x[[index]]
}

type_2 <- function(ts){
    x <- list(
        function(){
            sample(c("A", "B"), p = c(0.6, 0.4))
        },
        function(){
            sample(names(CIVS), 1)
        }
    )
    index <- sample(1:length(x), 1, p=c(0.3, 0.8))
    x[[index]]
}

type_3 <- function(ts){
    x <- list(
        function(){
            sample(c("A", "B", "C"), p = c(0.5, 0.32, 0.18))
        },
        function(){
            sample(names(CIVS), 1)
        }
    )
    index <- sample(1:length(x), 1, p=c(0.3, 0.8))
    x[[index]]
}

type_4 <- function(ts){
    p <- as.numeric(scale(CIVS) / 5 + 0.5)
    p <- p / sum(p)
    function() sample(names(CIVS), 1, prob = p)
}

n_match <- 100000
n_player <- 3000

players_0 <- get_players(n_player, type_0)
results_0 <- get_match_results(n_match, players_0)
sum_0 <- get_match_summary_bt(results_0)

players_1 <- get_players(n_player, type_1)
results_1 <- get_match_results(n_match, players_1)
sum_1 <- get_match_summary_bt(results_1)

players_2 <- get_players(n_player, type_2)
results_2 <- get_match_results(n_match, players_2)
sum_2 <- get_match_summary_bt(results_2)

players_3 <- get_players(n_player, type_3)
results_3 <- get_match_results(n_match, players_3)
sum_3 <- get_match_summary_bt(results_3)

players_4 <- get_players(n_player, type_4)
results_4 <- get_match_results(n_match, players_4)
sum_4 <- get_match_summary_bt(results_4)

tibble(
    civ = sum_0$civs,
    real_score = sum_0$score_real,
    type_0 = sum_0$score,
    type_1 = sum_1$score,
    type_2 = sum_2$score,
    type_3 = sum_3$score,
    type_4 = sum_4$score
)




