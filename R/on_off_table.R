library(tidyverse)
library(jsonlite)
library(gt)

participation <- readRDS("data/participation_2020.rds") %>%
  mutate(
    home_team = ifelse(home_team == "JAC", "JAX", home_team),
    away_team = ifelse(away_team == "JAC", "JAX", away_team)
    ) %>%
  select(play_id, week, home_team, away_team, home_names, away_names)

season_pbp <- readRDS(url("https://raw.githubusercontent.com/guga31bb/nflfastR-data/master/data/play_by_play_2020.rds")) %>%
  filter(!is.na(posteam), !is.na(epa), !is.na(down), rush == 1 | pass == 1)
  # filter(between(vegas_wp, .025, .975))

player = "Chris Carson"
offense = 1

joined <- season_pbp %>% 
  left_join(participation, by=c("home_team", "away_team", "play_id", "week")) %>%
  mutate(
    split = if_else(
      stringr::str_detect(home_names, player) | stringr::str_detect(away_names, player),
      1,
      0),
    split = if_else(is.na(split), 0, split)
  ) %>%
  # since no participation data yet
  mutate(
    split = case_when(
      home_team == "LA" & away_team == "SEA" ~ 0,
      TRUE ~ split
    )
  ) %>%
  filter(down != 4)

if (offense == 1) {
  tm = pull(joined %>% filter(split==1) %>% slice(1), posteam)
  pbp <- joined %>% filter(posteam==tm)
} else {
  tm = pull(joined %>% filter(split==1) %>% slice(1), defteam)
  pbp <- joined %>% filter(defteam==tm)
}

tm

#do stuff for the team summary table
all <- pbp %>% group_by(split) %>% summarize(
  epa = mean(epa), success=mean(success), p=mean(pass), play=n(), fd=mean(first_down)) %>%
  mutate(rowname="All plays", type=1)

early <- pbp %>% filter(down == 1 | down ==2) %>% group_by(split) %>% summarize(
  epa = mean(epa), success=mean(success), p=mean(pass),play=n(), fd=mean(first_down))%>%
  mutate(rowname="Early downs (1st & 2nd)", type=4)

earlyr <- pbp %>% filter((down == 1 | down ==2) & rush==1) %>% group_by(split) %>% summarize(
  epa = mean(epa), success=mean(success), p=mean(pass),play=n(), fd=mean(first_down))%>%
  mutate(rowname="Early rush", type=5)

earlyp <- pbp %>% filter((down == 1 | down ==2) & pass==1) %>% group_by(split) %>% summarize(
  epa = mean(epa), success=mean(success), p=mean(pass),play=n(), fd=mean(first_down))%>%
  mutate(rowname="Early pass", type=6)

late <- pbp %>% filter(down==3  | down == 4) %>% group_by(split) %>% summarize(
  epa = mean(epa), success=mean(success), p=mean(pass), play=n(), fd=mean(first_down))%>%
  mutate(rowname="Third down", type=7)

type <- pbp %>% group_by(split, pass) %>% summarize(
  epa = mean(epa), success=mean(success), p=mean(pass), play=n(), fd=mean(first_down)) %>%
  mutate(rowname=if_else(pass==1,"Pass","Rush"), type=2)

bound <- bind_rows(all,early,earlyr, earlyp,late,type) %>%
  mutate(p=round(100*p), epa=round(epa, digits=2), success=round(success,digits=2), fd=round(fd,digits=2)) %>%
  arrange(-split,type) %>% select(-pass, -type)

#team summary table
table <- bound%>%  select(split, rowname, epa, success, fd, play) %>% 
  mutate(split = ifelse(split == 0, paste(player, "Off Field"), paste(player, "On Field"))) %>%
  group_by(split) %>% 
  gt() %>%
  cols_label(
    epa = md("**EPA/<br>play**"), fd=md("**1st down<br>rate**"), success = md("**Success<br>rate**"), play = md("**Plays**")) %>%
  cols_align(align = "center") %>%
  tab_source_note(
    md(glue::glue("Win prob between 2.5% and 97.5% | Table: @benbbaldwin <br> Data: @nflfastR and Sportradar | {max(pbp$season)} through week {max(pbp$week)}"))) %>%
  tab_header(title = paste(tm, "splits with", player, "on and off field")) %>%
  tab_style(
    style = list(
      cell_text(weight = "bold")), locations = cells_group(groups=TRUE)) %>%
  tab_style(
    style = list(
      cell_text(style = "italic", align="center")), 
    locations = cells_stub(rows=c(2,3,9,10,5,6,12,13))) 

table

table %>%
  gtsave("results/on_off.png")



