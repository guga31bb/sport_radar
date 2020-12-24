library(tidyverse)
library(jsonlite)
source("R/key_dont_push.R")


# get this in _schedule.R
sched <- readRDS("data/schedule_2020.rds") %>%
  # filter(status == "closed") %>%
  select(id, home = home.alias, away = away.alias, home.game_number, away.game_number, scheduled, week) %>%
  mutate(game_date = as.Date(substr(scheduled, 1, 10))) %>% 
  # filter(game_date <= lubridate::today()) %>%
  filter(week <= 11)

scraped_games <- list.files("data/pbp") %>%
  tibble::as_tibble() %>%
  dplyr::rename(
    id = value
  ) %>%
  dplyr::mutate(
    id = substr(id, 1, (nchar(id) - 4))
  )

#figure out what we need
server_ids <- unique(scraped_games$id)
finished_ids <-unique(sched$id)

need_scrape <- sched[!finished_ids %in% server_ids,]
message(glue::glue("Already have {length(server_ids)} games; missing {nrow(need_scrape)} games"))

for (j in 1 : nrow(need_scrape)) {
  
  message(glue::glue("Getting game {j} of {nrow(need_scrape)}"))
  
  url <- glue::glue("http://api.sportradar.us/nfl/official/trial/v6/en/games/{need_scrape %>% dplyr::slice(j) %>% pull(id)}/pbp.json?api_key={key}")
  request <- httr::GET(url)
  
  game <- request %>%
    httr::content(as = "text", encoding = "UTF-8") %>%
    jsonlite::fromJSON(flatten = TRUE)
  
  if (length(game$periods$pbp[[1]]$events) > 0) {
    
    # message(glue::glue("data/pbp/{need_scrape %>% dplyr::slice(j) %>% pull(id)}.rds"))
    saveRDS(game, file = glue::glue("data/pbp/{need_scrape %>% dplyr::slice(j) %>% pull(id)}.rds"))
    
  }
  
  Sys.sleep(1)
  
}



