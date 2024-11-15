# Generate hexagonal logo for the package

# Setup ------------------------------------------------------------------------
p_family <- "Aller_Rg"

main_colour <- NHSRtheme::get_nhs_colours()["DarkBlue"]

# Creating subplot -------------------------------------------------------------
colours <- data.frame(
    hex = c(
        NHSRtheme::get_nhs_colours(section = "blues"),
        NHSRtheme::get_nhs_colours(section = "support greens"),
        NHSRtheme::get_nhs_colours(section = "neutrals")
    )
) |>
    tibble::rownames_to_column() |>
    dplyr::mutate(group = dplyr::case_when(
        grepl("Blue", rowname) ~ "blues",
        grepl("Green", rowname) ~ "greens",
        .default = "neutrals"
    )) |>
    dplyr::mutate(group2 = glue::glue("{group}{dplyr::row_number()}"),
                  .by = group) |>
    dplyr::select(group2, hex)

data <- data.frame(
    start = c(1.4, 3, 6, 8, 2, 5, 6.35, 2.7, 5, 7.5),
    end = c(3, 6, 8, 10, 5, 6.35, 9, 5, 7.5, 10.4),
    group = c(rep("blues", 4), rep("greens", 3), rep("neutrals", 3))
) |>
    dplyr::mutate(group2 = glue::glue("{group}{dplyr::row_number()}"),
                  .by = group) |>
    dplyr::left_join(colours, "group2")

subplot <- data |>
    dplyr::mutate(group = factor(group,
                                 levels = c("greens", "blues", "neutrals"))) |>
    ggplot2::ggplot() +
    ggplot2::geom_segment(
        ggplot2::aes(
            x = start,
            xend = end,
            y = group,
            yend = group,
            colour = group2
        ),
        linewidth = 10,
        lineend = "butt"
    ) +
    ggplot2::scale_colour_manual(values = data$hex) +
    ggplot2::theme_void() +
    ggplot2::theme(legend.position = "none") +
    hexSticker::theme_transparent() # make background of the plot transparent

# Creating hex logo ------------------------------------------------------------
hexSticker::sticker(
    subplot = subplot,
    package = "NHSRepisodes",
    h_color = main_colour,
    h_fill = "#ffffff",
    s_x = 1,
    s_y = 1,
    s_height = 1.3,
    s_width = 1.5,
    url = "",
    u_angle = 30,
    u_x = 1.08,
    u_y = 0.1,
    u_size = 4.85,
    dpi = 500,
    p_x = 1.0,
    p_y = 1,
    p_size = 22,
    p_color = "#ffffff",
    p_family = p_family,
    u_color = main_colour,
    u_family = p_family,
    filename = "inst/images/nhsrepisodeslogo.png"
)
