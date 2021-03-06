########## Carga de librerias necesarias.

library("dplyr")       # Para transformar la data, y piping `%>%`
library("forcats")     # Para reordenar las barras del plot.
library("ggplot2")     # Para generar los plots.
library("readr")       # Para cargar el dataset.
library("shiny")
library("shinythemes") # Para cambiarle el tema de colores.
library("tidyr")       # Para pivotear la tabla.

# Cargo el dataset.
emo_datos <- read_csv("Datos/emo_datos.csv")

########## Interfaz de usuarie.

ui <- navbarPage(                    # Vamos a tener un panel de tabs.
  title = "Emoji Data Explorer",     # Titulo de la tabla de tabs.
  theme = shinytheme("cerulean"),    # Le ponemos un lindo tema de colores!
  tabPanel(                          # Un tab para analisis por emoji.
    "Por emoji",                     # Titulo del tab.
    selectInput(                     # Input de selector de opciones.
      "selector_emoji",              # ID del selector de emojis.
      label = "Emoji",               # Label del selector.
      choices = unique(unlist(emo_datos[, -1])), # Opciones posibles para seleccionar.
      multiple = TRUE                # Permite seleccionar mas de uno.
    ),
    plotOutput("por_emoji")          # Aquí irá el gráfico
  ),
  tabPanel(                          # Un tab para analisis por paises.
    "Por pais",                      # Titulo del tab.
    selectInput(                     # Input de selector de opciones.
      "selector_pais",               # ID del selector de paises.
      label = "Paises",              # Label del selector.
      choices = NULL,                # Opciones posibles para seleccionar (NULL por ahora).
      multiple = TRUE                # Permite seleccionar mas de uno.
    ),
    plotOutput("por_pais")           # Aquí irá el gráfico
  )
)

########## Codigo de servidor.

# Funcion para generar el plot.
# `data_conteos` debe ser un data.frame con columnas `x` y `n`.
plot_barras <- function(data_conteos) {
  # Reordenamos de mayor a menor los datos del eje x.
  ggplot(data_conteos, aes(x = fct_reorder(x, n, .desc = TRUE), y = n)) +
    geom_col() +                       # Grafico de barras.
    labs(x = NULL)                     # Borramos el label del eje x.
}

server <- function(input, output, session) {
  output$por_emoji <- renderPlot({
    seleccion_emojis <- input$selector_emoji # Obtengo el valor actual del selector.
    filter( # Filtro las filas del dataset que contengan alguno de los emoji seleccionados.
      emo_datos,
      top_1 %in% seleccion_emojis |
        top_2 %in% seleccion_emojis |
        top_3 %in% seleccion_emojis |
        top_4 %in% seleccion_emojis |
        top_5 %in% seleccion_emojis
    ) %>%
      select(pais) %>%              # Seleccionamos solo la columna de pais.
      count(pais, sort = TRUE) %>%  # Contamos cuantas veces se repite cada bandera.
      mutate(x = pais) %>%          # Renombramos la variable `pais` como `x`.
      plot_barras()                 # Graficamos!
  })
}

########## Ejecutamos la app!

shinyApp(ui, server)
