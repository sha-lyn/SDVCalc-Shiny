library(shiny)
library(bslib)
library(bsicons)
library(shinyWidgets)

# Define UI ----
ui <- page_sidebar(
  title = "Stardew Valley Crop Calculator",
  sidebar = sidebar(
    "This is where the user input widgets will go."
  ),
  card(
    card_header("Profits"),
    "This section will display all of the calculations.",
    card_footer("Stardew Valley Crop Calculator"),
  ),
)

# Define server logic ----
server <- function(input, output) {
  
}

# Run the app ----
shinyApp(ui = ui, server = server)