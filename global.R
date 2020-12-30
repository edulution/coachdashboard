# source("helpers.R")

library(dplyr)
library(shiny)
library(shinythemes)
library(shinyWidgets)
library(shinycssloaders)
library(shinydashboard)
library(ggplot2)
library(config)
library(dbplyr)
library(forcats)
library(DT)
library(pool)
library(RPostgres)
library(networkD3)
library(stringr)
library(lubridate)

# fetch config vars for kolibri and baseline testing
bl_config <- config::get("baseline")

# create database connection pool objects
bl_pool <- dbPool(
  drv = RPostgres::Postgres(),
  dbname = bl_config$database,
  host = bl_config$server,
  user = bl_config$uid,
  password = bl_config$pwd,
  port = bl_config$port
)

# Colors for progress bars and content items in stacked bars
# content types - document , exercise, video
content_colors <- c("#0077CC","#26B7B7","#4C4CAE")
prog_bar_color <- "#1AA14D"

# Intervals and Colors for test scores
test_score_interval <- c(0.25,0.50,0.69,0.84)
test_score_colors <- c('#FF412A','#EC9090','#F5C216','#99CC33','#00B050')

# Names of the playlists
playlists <- c(
  "Pre-Alpha A",
  "Pre-Alpha B",
  "Pre-Alpha C",
  "Pre-Alpha D",
  "Alpha A",
  "Alpha B",
  "Alpha C",
  "Alpha D",
  "Bravo A",
  "Bravo B",
  "Bravo C",
  "Bravo D",
  "Grade 7 (Zambia)",
  "Coach Professional Development"
)

# colors for each course family
prealpha_colors <- colorRampPalette(c("#6CACE4","#0072CE"))
alpha_colors <- colorRampPalette(c("#84BD00","#509E2F"))
bravo_colors <- colorRampPalette(c("#7474C1","#300188"))
zm_gr7 <- "#795548"
coach_prof_dev <- "#FFA300"

# combine the colors above into one vector
playlist_colors <- c(
  prealpha_colors(4),
  alpha_colors(4),
  bravo_colors(4),
  zm_gr7,
  coach_prof_dev
  )

# Turn playlist_colors into a named vector using the playlist names
names(playlist_colors) <- playlists

# options for spinner
options(spinner.color.background = "white")
options(spinner.type = 2)
options(spinner.color = "green")