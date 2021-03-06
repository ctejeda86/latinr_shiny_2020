########## Carga de librerias necesarias.

library("dplyr")           # Para transformar la data, y piping `%>%`
library("forcats")         # Para reordenar las barras del plot.
library("ggplot2")         # Para generar los plots.
library("readr")           # Para cargar el dataset.
library("shiny")
library("shinycssloaders") # Para agregar waiters.
library("shinythemes")     # Para cambiarle el tema de colores.
library("tidyr")           # Para pivotear la tabla.
library("colourpicker")    # Para el selector de colores.

# Cargo el dataset.
emo_datos <- read_csv("Datos/emo_datos.csv")

########## Interfaz de usuarie.

ui <- navbarPage(                      # Vamos a tener un panel de tabs.
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
    withSpinner(                     # Le agrego un waiter hasta que se cargue el plot.
      plotOutput("por_emoji")        # Lugar donde ira el plot para mostrar el grafico por emoji.
    ),
    hr(),                              # Separador de contenido
    h4("Personaliza el grafico"),      # Encabezado de cuarto nivel
    colourInput(inputId = "colorBarra", label = "Color de las barras",
                value = "#595959")     # Selector de color para las barras
  ),
  tabPanel(                          # Un tab para analisis por paises.
    "Por pais",                      # Titulo del tab.
    selectInput(                     # Input de selector de opciones.
      "selector_pais",               # ID del selector de paises.
      label = "Paises",              # Label del selector.
      choices = unique(unlist(emo_datos$pais)), # Opciones posibles para seleccionar.
      multiple = TRUE                # Permite seleccionar mas de uno.
    ),
    withSpinner(                     # Le agrego un waiter hasta que se cargue el plot.
      plotOutput("por_pais"),        # Lugar donde ira el plot para mostrar el grafico por paises.
      type = 8,                      # Otro tipo de spinner.
      color = "#562457",             # Color del spinner.
      size = 2                       # Tamanio del spinner
    )
  )
)


########## Codigo de servidor.

# Funcion para generar el plot con imagenes.
# `data_conteos` debe ser un data.frame con columnas `x` y `n`.
# `emoji_img_map` debe ser un data.frame con columnas `emoji` y `label`.
emoji_img_map <- read_rds("Datos/emoji_img_map.rds")
plot_barras <- function(data_conteos, colorBarra) {
  library("ggtext")
  # Reordenamos de mayor a menor los datos del eje x.
  merge(data_conteos, emoji_img_map, by.x = "x", by.y = "emoji") %>%
    ggplot(aes(x = fct_reorder(label, n, .desc = TRUE), y = n)) +
    geom_col(fill = colorBarra) +                              # Grafico de barras.
    theme(axis.text.x = element_markdown()) + # Para poner la imagen del emoji en vez del emoji.
    labs(x = NULL)                            # Borramos el label del eje x.
}

server <- function(input, output, session) {
  output$por_emoji <- renderPlot({
    # Uso la funcion `req` para que este codigo se ejecute solo si el `input` utilizado tiene algun
    # valor.
    seleccion_emojis <- req(input$selector_emoji) # Obtengo el valor actual del selector.
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
      plot_barras(input$colorBarra)                 # Graficamos!
  })
  output$por_pais <- renderPlot({
    # Uso la funcion `req` para que este codigo se ejecute solo si el `input` utilizado tiene algun
    # valor.
    seleccion_pais <- req(input$selector_pais) # Obtengo el valor actual del selector.
    filter(emo_datos, pais %in% seleccion_pais) %>%
      select(-pais) %>% # Seleccionamos todo menos la columna de pais (vamos a ver solo los emoji).
      pivot_longer(cols = starts_with("top_")) %>% # No tenemos en cuenta el orden de eleccion.
      count(value, sort = TRUE) %>% # Contamos cuantas veces se repite cada emoji.
      mutate(x = value) %>% # Renombramos la variable `value` como `x` (va a ser nuestro eje x del plot).
      plot_barras(input$colorBarra)
  })
}

########## Ejecutamos la app!

shinyApp(ui, server)


