library(shiny)
library(bslib)
library(bsicons)
library(shinyWidgets)
library(jsonlite)

# Load crop data
crop_data <- fromJSON("data/SDVCrops.json")
crop_list <- split(crop_data$Crop, crop_data$Season)

prob_data <- fromJSON ("data/SDVProb.json")

# Create a named list of crops by season
crop_list <- lapply(crop_data, names)


# Define UI ----
ui <- fluidPage (
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "style.css")
  ),
  page_sidebar(
  title = "Stardew Valley Crop Calculator",
  sidebar = sidebar(
    width = "50%",
    sliderInput("farmer_level", label = "What is your Farmer skill level?", min = 1, max = 10, value = 1, step = 1, round = FALSE, ticks = TRUE, animate = FALSE, width = '100%', pre = NULL, post = NULL, timeFormat = NULL,
                timezone = NULL, dragRange = TRUE),
    radioButtons("season", 
                 label = "What Season are you planting in?", 
                 choiceNames = list (
                   HTML('<div class="radio-button-text">Spring</div>'),
                   HTML('<div class="radio-button-text">Summer</div>'),
                   HTML('<div class="radio-button-text">Fall</div>'),
                   HTML('<div class="radio-button-text">Winter</div>')
                 ),
                 choiceValues = list(
                   "Spring",
                   "Summer",
                   "Fall",
                   "Winter"),
                 selected = "Spring", 
                 inline = FALSE, 
                 width = "100%"),
    checkboxGroupInput ("profession", 
                        label = "Do you have either of these two professions?",
                        choiceNames = list (
                          HTML('<div class="radio-button-text">Tiller (+10%  to crop value)</div>'),
                          HTML('<div class="radio-button-text"> Artisan (+40% to artisan goods)</div>')
                        ),
                        choiceValues = list(
                          "Tiller",
                          "Artisan"),
                        inline = FALSE,
                        width = "100%"
                        ),
    
# This part is still under construction ----
     selectInput (
     "crops",
     label = "What crops will you be planting?",
     choices = NULL,
     width = "100%",
    ), 
    
    numericInput (
      "seed_count",
      label = "How many seeds?",
      value = 0,
      min = 0,
      max = 999,
      width = "100%"
    )
    
  ),
  card(
    card_header("Profits"),
    "This section will display all of the calculations.",
    tableOutput("results_table"),
    plotOutput("results_plot"),
    card_footer("Stardew Valley Crop Calculator"),
  ),
)
)

# Define server logic ----
server <- function(input, output, session) {
  observeEvent(input$season, {
    updateSelectInput(session, 
                      "crops", 
                      choices = crop_list[[input$season]])
  })
}


# Run the app ----
shinyApp(ui = ui, server = server)