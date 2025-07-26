library(shiny)
library(bslib)
library(bsicons)
library(shinyWidgets)

# Load and clean crop data
crop_data <- read.csv("data/SDVCrops.csv")
colnames(crop_data) <- tolower(colnames(crop_data))

# Define UI ----
ui <- fluidPage(
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "style.css")
  ),
  page_sidebar(
    title = "Stardew Valley Crop Calculator",
    sidebar = sidebar(
      width = "50%",
      radioButtons("season", 
                   label = "What Season are you planting in?", 
                   choiceNames = list (
                     HTML('<div class="radio-button-text">Spring</div>'),
                     HTML('<div class="radio-button-text">Summer</div>'),
                     HTML('<div class="radio-button-text">Fall</div>'),
                     HTML('<div class="radio-button-text">Winter</div>')
                   ),
                   choiceValues = list(
                     "Spring", "Summer", "Fall", "Winter"
                   ),
                   selected = "Spring", 
                   inline = FALSE, 
                   width = "100%"
      ),
      checkboxGroupInput("profession", 
                         label = "Do you have either of these two professions?",
                         choiceNames = list (
                           HTML('<div class="radio-button-text">Tiller (+10%  to crop value)</div>'),
                           HTML('<div class="radio-button-text">Artisan (+40% to artisan goods)</div>')
                         ),
                         choiceValues = list("Tiller", "Artisan"),
                         inline = FALSE,
                         width = "100%"
      ),
      
      # Crop selector + seed count
      selectInput(
        "crops",
        label = "What crops will you be planting?",
        choices = NULL,
        width = "100%"
      ), 
      numericInput(
        "seed_count",
        label = "How many seeds?",
        value = 0,
        min = 0,
        max = 999,
        width = "100%"
      ),
      
      # NEW UI: total available & dynamic sale‐method inputs
      tags$p(
        "Total Crops Available:",
        textOutput("total_available", inline = TRUE)
      ),
      uiOutput("method_inputs")
    ),
    
    # Results card
    card(
      card_header("Profits"),
      "This section will display all of the calculations.",
      tableOutput("results_table"),
      plotOutput("results_plot"),
      card_footer("Thank you.")
    )
  )
)

# Define server logic ----
server <- function(input, output, session) {
  
  # 1. Season → crop dropdown
  seasonal_crops <- reactive({
    req(input$season)
    crop_data[crop_data$season == input$season, "crop"]
  })
  observe({
    updateSelectInput(session, "crops",
                      choices  = seasonal_crops(),
                      selected = NULL)
  })
  
  # 2. Selected crop & total yield
  selected_crop <- reactive({
    req(input$crops)
    crop_data[crop_data$crop == input$crops, ]
  })
  produce_count <- reactive({
    req(input$seed_count, selected_crop())
    input$seed_count * selected_crop()$perszn
  })
  
  # ── Insert new server outputs here ──
  
  # 2a. Show total available produce
  output$total_available <- renderText({
    req(produce_count())
    produce_count()
  })
  
  # 2b. Dynamically emit numericInputs for each non-NA sale method
  output$method_inputs <- renderUI({
    crop  <- selected_crop()
    total <- produce_count()
    req(crop, total)
    
    methods <- c("base", "silver", "gold", "keg", "aged", "jar", "dehyd")
    labels  <- c("Base quality", "Silver quality", "Gold quality",
                 "Keg product",  "Aged product",   "Jar product", "Dehydrated")
    
    inputs <- lapply(seq_along(methods), function(i) {
      col <- methods[i]
      val <- crop[[col]]
      id  <- paste0("n_", col)
      
      if (!is.na(val)) {
        numericInput(
          inputId = id,
          label   = paste0("Units sold (", labels[i], ")"),
          value   = 0,
          min     = 0,
          max     = total,
          width   = "100%"
        )
      }
    })
    
    do.call(tagList, inputs)
  })
  
  # 3. Build profit table
  profit_table <- reactive({
    crop <- selected_crop()
    n    <- produce_count()
    cost <- input$seed_count * crop$seed
    
    base_price   <- if ("Tiller"  %in% input$profession) crop$tiller.base   else crop$base
    silver_price <- if ("Tiller"  %in% input$profession) crop$tiller.silver else crop$silver
    gold_price   <- if ("Tiller"  %in% input$profession) crop$tiller.gold   else crop$gold
    
    keg_price   <- if ("Artisan" %in% input$profession) crop$artisan.keg   else crop$keg
    aged_price  <- if ("Artisan" %in% input$profession) crop$artisan.aged else crop$aged
    jar_price   <- if ("Artisan" %in% input$profession) crop$artisan.jar  else crop$jar
    dehyd_price <- if ("Artisan" %in% input$profession) crop$artisan.dehyd else crop$dehyd
    
    methods <- c("Base", "Silver", "Gold", "Keg", "Aged", "Jar", "Dehydrated")
    prices  <- c(base_price, silver_price, gold_price,
                 keg_price, aged_price, jar_price, dehyd_price)
    
    df <- data.frame(
      Method    = methods,
      UnitPrice = prices,
      Profit    = n * prices - cost,
      stringsAsFactors = FALSE
    )
    subset(df, !is.na(UnitPrice))
  })
  
  # 4. Outputs
  output$results_table <- renderTable({
    profit_table()
  }, digits = 0)
  
  output$results_plot <- renderPlot({
    df <- profit_table()
    barplot(
      df$Profit,
      names.arg = df$Method,
      col       = "steelblue",
      main      = paste("Total Profit for", input$crops),
      ylab      = "Profit"
    )
  })
}

# Run the app ----
shinyApp(ui = ui, server = server)
