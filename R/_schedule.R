library(tidyverse)
library(jsonlite)
source("R/key_dont_push.R")

# #####################################################################
## schedule for game IDs

url <- glue::glue("http://api.sportradar.us/nfl/official/trial/v6/en/games/2020/REG/schedule.json?api_key={key}")
request <- httr::GET(url)

games <- request %>%
  httr::content(as = "text", encoding = "UTF-8") %>%
  jsonlite::fromJSON(flatten = TRUE)

weeks <- games$weeks$games

all <- map_df(1 : 17, function(x) {
  
  weeks[[x]] %>%
    as_tibble() %>%
    mutate(week = x)
  
})

all %>%
  saveRDS("data/schedule_2020.rds")





