test_that("merge_episodes works on a small set of values", {
    id <- c(1, 1, 2, 2, 2, 1)
    start <- as.Date(c(
        "2020-01-01",
        "2020-01-03",
        "2020-04-01",
        "2020-04-15",
        "2020-04-17",
        "2020-05-01"
    ))
    end <- as.Date(c(
        "2020-01-10",
        "2020-01-10",
        "2020-04-30",
        "2020-04-16",
        "2020-04-19",
        "2020-10-01"
    ))

    # Date
    dat1 <- dplyr::tibble(id = id, start = start, end = end)

    out1a <- dat1 |>
        dplyr::mutate(interval = ivs::iv(start, end + 1)) |>
        dplyr::reframe(interval = ivs::iv_groups(interval, abutting = FALSE), .by = id) |>
        dplyr::arrange(id, interval)

    out1b <- dat1 |>
        merge_episodes() |>
        dplyr::mutate(interval = ivs::iv(start = .episode_start, end = .episode_end + 1)) |>
        dplyr::select(id, interval)

    expect_identical(out1a, out1b)

    # POSIXct
    dat2 <- dplyr::tibble(id = id, start = as.POSIXct(start), end = as.POSIXct(end))

    out2a <- dat2 |>
        dplyr::mutate(interval = ivs::iv(start, end + 1)) |>
        dplyr::reframe(interval = ivs::iv_groups(interval, abutting = FALSE), .by = id)|>
        dplyr::arrange(id, interval)

    out2b <- dat2 |>
        merge_episodes() |>
        dplyr::mutate(interval = ivs::iv(start = .episode_start, end = .episode_end + 1)) |>
        dplyr::select(id, interval)

    expect_identical(out2a, out2b)

    # snapshot for comparison
    expect_snapshot_output(merge_episodes(dat1))
})


test_that("merge_episodes works on a large set of values", {
    set.seed(99)
    n <- 10000
    id <- sample(seq_len(n), size = n * 5, replace = TRUE)
    start <- as.Date("2020-01-01") + sample.int(365, size = n * 5, replace = TRUE)
    end <- start + sample(1:100, size = n * 5, replace = TRUE)

    # Dates
    dat1 <- dplyr::tibble(id = id, start = start, end = end)

    out1a <- dat1 |>
        dplyr::mutate(interval = ivs::iv(start, end + 1)) |>
        dplyr::reframe(interval = ivs::iv_groups(interval, abutting = FALSE), .by = id) |>
        dplyr::arrange(id, interval)

    out1b <- dat1 |>
        merge_episodes() |>
        dplyr::mutate(interval = ivs::iv(start = .episode_start, end = .episode_end + 1)) |>
        dplyr::select(id, interval)

    expect_identical(out1a, out1b)

    # POSIXct
    dat2 <- dplyr::tibble(id = id, start = as.POSIXct(start), end = as.POSIXct(end))

    out2a <- dat2 |>
        dplyr::mutate(interval = ivs::iv(start, end + 1)) |>
        dplyr::reframe(interval = ivs::iv_groups(interval, abutting = FALSE), .by = id) |>
        dplyr::arrange(id, interval)

    out2b <- dat2 |>
        merge_episodes() |>
        dplyr::mutate(interval = ivs::iv(start = .episode_start, end = .episode_end + 1)) |>
        dplyr::select(id, interval)

    expect_identical(out2a, out2b)
})
