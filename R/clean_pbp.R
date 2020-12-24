library(tidyverse)
library(jsonlite)

library(furrr)
library(future)
plan(multisession)

scraped_games <- list.files("data/pbp") %>%
  tibble::as_tibble() %>%
  dplyr::rename(
    id = value
  )

get_game <- function(scraped_games, i) {
  
  game <- readRDS(glue::glue("data/pbp/{scraped_games %>% dplyr::slice(i) %>% pull(id)}"))
  
  home <- game$summary$home$alias
  away <- game$summary$away$alias
  season <- game$summary$season$year
  week <- game$summary$week$sequence
  
  pbp <- game %>%
    pluck("periods", "pbp") %>%
    bind_rows() %>%
    as_tibble() %>%
    pull(events) %>%
    bind_rows() %>%
    as_tibble() %>%
    select(
      reference, description, sequence, screen_pass, play_action, run_pass_option, statistics, details, 
           pocket_location, qb_at_snap, pass_route, running_lane, men_in_box, play_blitz = blitz, players_rushed
      ) %>%
    unnest_wider(statistics) %>%
    unnest(cols = stat_type : att_yards) %>%
    dplyr::rename(
      existing_description = description,
      existing_yards = yards,
      play_sequence = sequence
    ) %>%
    select(
      reference, play_sequence, existing_description, screen_pass, play_action, run_pass_option, details, 
      pocket_location, qb_at_snap, pass_route, running_lane, men_in_box, play_blitz = blitz, players_rushed,
      on_target_throw, dropped, catchable, incompletion_type, broken_tackles, pass_route, qb_at_snap,
      men_in_box, batted_pass, hurry
    ) %>%
    unnest_wider(details) %>%
    unnest(cols = c(
      on_target_throw, dropped, catchable, incompletion_type, broken_tackles, pass_route, qb_at_snap,
      men_in_box, batted_pass, hurry, play_blitz
    )) %>%
    select(
      play_blitz, reference, play_sequence, existing_description, play_action, screen_pass, run_pass_option, 
      hurry, batted_pass, incompletion_type,
      on_target_throw, dropped, catchable, pocket_location, players_rushed,
      men_in_box, running_lane, pass_route
    ) %>%
    group_by(reference) %>%
    summarize(
      sr_desc = dplyr::first(existing_description),
      sequence = dplyr::first(play_sequence),
      play_action = if_else(dplyr::first(na.omit(play_action)), 1, 0),
      screen_pass = if_else(dplyr::first(na.omit(screen_pass)), 1, 0), 
      run_pass_option = if_else(dplyr::first(na.omit(run_pass_option)), 1, 0), 
      blitz = dplyr::first(play_blitz), 
      hurry = max(na.omit(hurry)), 
      batted_pass = max(na.omit(batted_pass)), 
      incompletion_type = dplyr::first(na.omit(incompletion_type)),
      on_target_throw = dplyr::first(na.omit(on_target_throw)), 
      dropped = dplyr::first(na.omit(dropped)), 
      catchable = dplyr::first(na.omit(catchable)), 
      pocket_location = dplyr::first(na.omit(pocket_location)), 
      players_rushed = dplyr::first(na.omit(players_rushed)),
      men_in_box = dplyr::first(na.omit(men_in_box)),
      pass_route = dplyr::first(na.omit(pass_route))
    ) %>%
    ungroup() %>%
    dplyr::rename(play_id = reference) %>%
    mutate(
      game_id = 
        glue::glue('{season}_{formatC(week, width=2, flag=\"0\")}_{away}_{home}'),
      hurry = if_else(hurry == -Inf, NA_real_, hurry),
      batted_pass = if_else(batted_pass == -Inf, NA_real_, batted_pass)
    ) %>%
    arrange(sequence)
  
  return(pbp)
  
}

all_games <- future_map_dfr(1 : nrow(scraped_games), function(x) {
  
  message(glue::glue("{x}"))
  get_game(scraped_games, x)
  
})



all_games %>%
  saveRDS("data/pbp_2020.rds")


all_games %>%
  filter(game_id == "2020_11_ARI_SEA")


