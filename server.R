function(input, output, session) {
  # Reactives
  filtered_data <- callModule(
    module = selectizeGroupServer,
    id = "user_filters",
    data = prog_by_playlist(),
    vars = c(
      "country",
      "cluster",
      "coach_level",
      "username_full_name",
      "playlist"
    )
  )
  
  # Progress by playlist reactive
  prog_by_playlist <- reactive({
    # Set global vars
    # Get kolibri users
    kol_users <<- bl_pool %>%
      tbl(in_schema("ext", "kolibriauth_facilityuser"))
    
    # Get test scores
    test_scores <<- bl_pool %>% tbl("vresponsescore")
    
    # Get tests config
    test_config <<- bl_pool %>% tbl("test_marks")
    
    # Get content prerequisites
    content_prereqs <<- bl_pool %>%
      tbl(in_schema("ext", "content_contentnode_has_prerequisite"))
    
    # Get content and topics
    content_and_topics <<- bl_pool %>%
      tbl("content_and_topics")
    
    # return conn to prog_by_playlist view
    bl_pool %>% tbl("prog_by_playlist")
  })
  
  # Baseline tests reactive
  baseline_tests <- reactive({
    # Join users, tests and tests config
    test_scores %>%
      left_join(test_config,
                by = c("test" = "test_id", "course", "module", "testmaxscore","channel_id")) %>%
      left_join(kol_users,
                by = c("user_id" = "id")) %>%
      # Collect the results of the join
      collect() %>%
      # Join to the data filtered in the sectize input
      semi_join(filtered_data(),
                by = c("user_id", "channel_id")) %>%
      # Convert to a dataframe
      as.data.frame() %>%
      # Calculate the percent score for each test, round to 2 decimal places
      mutate(
        pct_score = score / testmaxscore,
        test_date_formatted = ymd(test_date)) %>%
      mutate(
        test_date_formatted = paste(
          day(test_date_formatted),
          month(test_date_formatted, label = T),
          year(test_date_formatted)
        )
      ) %>%
      # Arrange in descending order of test date(latest tests appear first)
      arrange(desc(test_date)) %>%
      # Select only the needed columns
      select(username,
             full_name,
             test_name,
             test_date_formatted,
             pct_score)
      
      
  })
  
  # Reactive for Playlist Contents
  select_playlist_content <- reactive({
    selected_playlist <- input$playlist_select
    content_and_topics %>%
      filter(playlist_name == selected_playlist) %>% 
      select(
        id,
        title,
        kind,
        topic_title,
        playlist_name,
        id_num
      ) %>%
      as.data.frame() %>%
      mutate(
        kind = str_to_sentence(kind)
      )
  })
  
  # Outputs
  output$time_plot <- renderPlot({
    time_plot <- filtered_data() %>%
      ggplot(aes(fct_reorder(full_name, desc(tot_time_spent)), tot_time_spent, fill = playlist)) +
      geom_bar(stat = "identity",
               position = position_dodge(width = 0.8),
               width = 0.8) +
      coord_flip() +
      labs(x = "", y = "Total Time Spent(Hours)") +
      scale_y_continuous() +
      scale_fill_manual(name = "Playlist", values = playlist_colors)
    
    if (input$show_time_labels){
      time_plot <- time_plot + geom_label(
        aes(label = tot_time_spent), 
        hjust = -0.2,
        vjust = 0,
        position = position_dodge(width = 1),
        show.legend = F)
    }
    
    print(time_plot)
  })
  
  output$progress_plot <- renderPlot({
    progress_plot <- filtered_data() %>%
      ggplot(aes(fct_reorder(full_name, desc(prog_pct)), prog_pct, fill = playlist)) +
      geom_bar(stat = "identity",
               position = position_dodge(width = 0.8),
               width = 0.8) +
      coord_flip() +
      labs(x = "", y = "% Completed") +
      scale_y_continuous(labels = scales::percent) +
      scale_fill_manual(name = "Playlist", values = playlist_colors)
    
    if (input$show_prog_labels){
      progress_plot <- progress_plot + geom_label(
        aes(label = paste0(round(prog_pct*100),"%")), 
        hjust = -0.2,
        vjust = 0,
        position = position_dodge(width = 1),
        show.legend = F)
    }
    
    print(progress_plot)
  })
  
  
  output$tests_table <- DT::renderDT({
    DT::datatable(
      baseline_tests(),
      colnames = c('Username', 'Full Name', 'Test', 'Test Date', 'Score'),
      # show only the table, search box, and pagination
      options = list(dom = 'ftp')
    ) %>%
      formatStyle('pct_score',
                  backgroundColor = styleInterval(
                    test_score_interval,
                    test_score_colors)) %>%
      formatPercentage('pct_score')
    
    
  })
  
  # Table of playlist contents
  output$topics_table <- renderDT({
    playlist_content <- select_playlist_content() %>%
      select(-id, -id_num)
    
    DT::datatable(
      playlist_content,
      colnames = c("Title","Kind","Topic","Playlist"),
      options = list(dom = 'ftp')
    )
  })
  
  
  output$topics_diagram <- renderForceNetwork({
    diagram_grouping <- input$diag_group_select
    if(diagram_grouping == "By Topic"){
      group_var <- "topic_title"
    }
    else{
      group_var <- "kind"
    }
    
    playlist_content <- select_playlist_content()
    
    playlist_prereqs <- content_prereqs %>%
      collect() %>% 
      filter(from_contentnode_id %in% playlist_content$id) %>%
      as.data.frame()
      
    
    playlist_prereqs$from_num <- sapply(
      playlist_prereqs$from_contentnode_id,
      function(x) playlist_content[playlist_content$id == x,"id_num"])
    
    playlist_prereqs$to_num <- sapply(
      playlist_prereqs$to_contentnode_id,
      function(x) playlist_content[playlist_content$id == x,"id_num"])
    
    forceNetwork(
      Links = playlist_prereqs,
      Nodes = playlist_content,
      Source = "to_num",
      Target = "from_num",
      NodeID = "title",
      Group = group_var,
      opacity = 0.8,
      legend = T,
      zoom = T,
      fontSize = 15
    )

  })
  
  # Download csv file of baseline data selected
  output$download_bldata <-
    downloadHandler(
      filename = function() {
        paste('adminstats-bldata-', Sys.Date(), '.csv', sep = "")
      },
      content = function(file) {
        write.csv(baseline_tests(), file, row.names = F)
      }
    )
  
  
  
}