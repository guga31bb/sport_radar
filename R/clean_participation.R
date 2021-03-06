library(tidyverse)
library(jsonlite)

scraped_games <- list.files("data/participation") %>%
  tibble::as_tibble() %>%
  dplyr::rename(
    id = value
  )

get_game <- function(i) {
  
  game <- readRDS(glue::glue("data/participation/{scraped_games %>% dplyr::slice(i) %>% pull(id)}"))

  if (length(game$plays) > 0) {
    
    plays <- game$plays
    
    game_players <- map_df(1 : nrow(plays), function(j) {
      
      row = plays %>% dplyr::slice(j)
      
      tibble::tibble(
        play_id = row$sequence,
        time = row$clock,
        desc = row$description,
        home_players = row$home.players,
        away_players = row$away.players,
        # for easy searching
        home_names = list(row$home.players[[1]]$name) %>% paste(),
        away_names = list(row$away.players[[1]]$name) %>% paste()
        
      ) %>%
        return()
      
    })
    
    game_players %>%
      # unnest(cols = c(home_players, away_players), names_repair = "universal") %>%
      # select("play_id", "time", "desc", "home_name" = "name...5", "away_name" = "name...11") %>%
      # nest(home = home_name, away = away_name) %>%
      mutate(
        home_team = game$summary$home$alias,
        away_team = game$summary$away$alias,
        week = game$summary$week$sequence,
        season = game$summary$season$year    
      ) %>%
      return()
    
  } else {
    message(glue::glue("Nothing for {game$summary$away$alias} @ {game$summary$home$alias} week {game$summary$week$sequence}"))
    return(data.frame())
  }
  

}

all_games <- map_df(1 : nrow(scraped_games), function(x) {
  
  message(glue::glue("{x}"))
  get_game(x)
  
})

all_games %>%
  saveRDS("data/participation_2020.rds")


# https://gist.github.com/NateNohling/12ff1819337f347e317cb203b9f4057c

