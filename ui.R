dashboardPage(
  dashboardHeader(title = "Admin Stats"),
  dashboardSidebar(
    selectizeGroupUI(
      id = "user_filters",
      inline = F,
      params = list(
        country = list(inputId = "country", title = "Country"),
        cluster = list(inputId = "cluster", title = "Cluster"),
        coach_level = list(inputId = "coach_level", title = "Coach Level"),
        username_full_name = list(inputId = "username_full_name", title = "Username: Full Name"),
        playlist = list(inputId = "playlist", title = "Playlist")
      )
    )
  ),
  
  
  dashboardBody(
    tags$head(
      includeScript("google_analytics.js"),
      tags$link(
        rel="shortcut icon",
        href = "https://storage.googleapis.com/inventory_static_files/favicon.png")),
    tabBox(
      width = 12,
      # Time spent tab
      tabPanel(
        tagList(icon("hourglass")," Time Spent"),
        withSpinner(plotOutput("time_plot")),
        checkboxInput(
          'show_time_labels',
          label = "Show labels on bars",
          value = F)
        ),
      # Progress tab
      tabPanel(
        tagList(icon("tachometer-alt"), " Progress"),
        withSpinner(plotOutput("progress_plot")),
        checkboxInput(
          'show_prog_labels',
          label = "Show labels on bars",
          value = F)
        ),
      # Baseline Tests tab
      tabPanel(
        tagList(icon("tasks"), " Baseline Tests"),
        downloadBttn(
          "download_bldata",
          style = "material-flat",
          label = "Download CSV",
          size = "sm"),
        withSpinner(DT::DTOutput("tests_table"))
      ),
      tabPanel(
        "Playlist Contents",
        strong("View the contents of the available courses. Each node in the diagram represents one content item (Exercise, Video etc)"),
        h5(strong("The entire diagram is interactive."), "You may zoom in and out (with a mousewheel), scroll, drag and click on any part of the diagram"),
        br(),
        fluidRow(
          column(
            width = 4,
            selectInput(
              "playlist_select",
              label = "Playlist",
              choices = playlists
            )
          ),
          column(
            width = 4,
            selectInput(
              "diag_group_select",
              label = "Diagram Type",
              choices = c("By Topic","By Content Type")
            )
          )
          
        ),
        fluidRow(
          tabBox(
            width = 12,
            tabPanel(
              "Table",
              withSpinner(DT::DTOutput("topics_table"))
            ),
            tabPanel(
              "Diagram",
              withSpinner(forceNetworkOutput("topics_diagram"))
            )
          )
        )
      )
    )
  )
  
)