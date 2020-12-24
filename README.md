# sport_radar

This is a set of functions to scrape and manipulate Sport Radar data obtained with their API. **THESE CAN ONLY BE USED IF YOU HAVE AN API KEY WHICH IS NOT PROVIDED IN THE REPO**.

## Getting this to work: you need an API key

If you don't have a Sport Radar API key, [go here and get a key](https://developer.sportradar.com/docs/read/Home).

Once you have a key, you need to create a file called `"R/key_dont_push.R"` whose contents are

`key = "XXX"`

where "XXX" is your API key.

## Files that scrape the raw data

* ["R/_schedule.R"](https://github.com/guga31bb/sport_radar/blob/master/R/_schedule.R): gets a schedule dataframe which has the Sport Radar game IDs necessary to scrape games. Saves dataframe as "data/schedule_2020.rds"
* ["R/_participation.R"](https://github.com/guga31bb/sport_radar/blob/master/R/_participation.R) saves raw participation data for each game
* ["R/_play_by_play.R"](https://github.com/guga31bb/sport_radar/blob/master/R/_play_by_play.R): saves raw play-by-play charting data for each game

## Files that clean up the scraped data
* ["R/clean_participation"](https://github.com/guga31bb/sport_radar/blob/master/R/clean_participation.R): creates a dataframe with cleaned participation data
* ["R/clean_pbp"](https://github.com/guga31bb/sport_radar/blob/master/R/clean_pbp.R): creates a dataframe with cleaned play-by-play charting data

## Files that make things
* ["R/on_off_table"](https://github.com/guga31bb/sport_radar/blob/master/R/on_off_table.R): creates on-off table for a player