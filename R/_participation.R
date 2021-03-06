library(tidyverse)
library(jsonlite)
source("R/key_dont_push.R")

# #####################################################################
## scraping participation files and saving locally

# get this in _schedule.R
sched <- readRDS("data/schedule_2020.rds") %>%
  filter(status == "closed") %>%
  select(id, home = home.alias, away = away.alias, home.game_number, away.game_number, scheduled, week) %>%
  mutate(game_date = as.Date(substr(scheduled, 1, 10))) %>% 
  # filter(game_date <= lubridate::today()) %>%
  filter(week <= 10)

scraped_games <- list.files("data/participation") %>%
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

  url <- paste0("http://api.sportradar.us/nfl/official/trial/v5/en/plays/",need_scrape %>% dplyr::slice(j) %>% pull(id),"/participation.json?api_key=",key)
  request <- httr::GET(url)
  
  game <- request %>%
    httr::content(as = "text", encoding = "UTF-8") %>%
    jsonlite::fromJSON(flatten = TRUE)
  
  # only save if there's actually data
  if (length(game$plays) > 0) {
    # message(glue::glue("data/participation/{need_scrape %>% dplyr::slice(j) %>% pull(id)}.rds"))
    saveRDS(game, file = glue::glue("data/participation/{need_scrape %>% dplyr::slice(j) %>% pull(id)}.rds"))
  }
  

  Sys.sleep(1)
}



