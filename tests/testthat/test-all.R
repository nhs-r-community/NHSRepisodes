test_that("error messaging for add_parent_interval works", {

    dat <- data.frame(
        id = c(1, 1, 2, 2, 2, 1),
        start = as.Date(c(
            "2020-01-01", "2020-01-03", "2020-04-01",
            "2020-04-15", "2020-04-17", "2020-05-01"
        )),
        end = as.Date(c(
            "2020-01-10", "2020-01-10", "2020-04-30",
            "2020-04-16", "2020-04-19", "2020-10-01"
        ))
    )

    # default method
    expect_snapshot(
        error = TRUE,
        with(dat, add_parent_interval(id, start, end, name_parent_start = "id"))
    )

    expect_snapshot(
        error = TRUE,
        with(dat, add_parent_interval(id, as.POSIXlt(start), as.POSIXlt(end)))
    )

    expect_snapshot(
        error = TRUE,
        with(dat, add_parent_interval(id, start, as.POSIXct(end)))
    )

    expect_snapshot(
        error = TRUE,
        with(dat, add_parent_interval(id[-1L], start, end))
    )

    expect_snapshot(
        error = TRUE,
        with(dat, add_parent_interval(id, start, end[-1L]))
    )

    # data.frame method
    expect_snapshot(
        error = TRUE,
        add_parent_interval(dat, "id", "start", "end", name_parent_start = "parent_end")
    )

    expect_snapshot(
        error = TRUE,
        add_parent_interval(dat, "id", "start", "end", name_parent_start = "id")
    )

    expect_snapshot(
        error = TRUE,
        add_parent_interval(dat, "id", "start", "bob")
    )
})


test_that("error messaging for merge_episodes works", {

    dat <- data.frame(
        id = c(1, 1, 2, 2, 2, 1),
        start = as.Date(c(
            "2020-01-01", "2020-01-03", "2020-04-01",
            "2020-04-15", "2020-04-17", "2020-05-01"
        )),
        end = as.Date(c(
            "2020-01-10", "2020-01-10", "2020-04-30",
            "2020-04-16", "2020-04-19", "2020-10-01"
        ))
    )

    # default method
    expect_snapshot(
        error = TRUE,
        with(dat, merge_episodes(id, start, end, name_episode_start = "id"))
    )

    # default method rethrows
    expect_snapshot(
        error = TRUE,
        with(dat, merge_episodes(id[-1L], start, end))
    )

    # data.frame method
    expect_snapshot(
        error = TRUE,
        merge_episodes(dat, "id", "start", "end", name_episode_start = "id")
    )

    expect_snapshot(
        error = TRUE,
        merge_episodes(dat, "id", "start", "end", name_episode_start = "episode_end")
    )

    # data.frame method rethrows
    expect_snapshot(
        error = TRUE,
        merge_episodes(dat, "id", "start", "bob")
    )
})

test_that("merge_episodes (data.frame method) works on a small set of values", {

    skip_if_not_installed("dplyr", minimum_version = "1.1.0")
    skip_if_not_installed("ivs")

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
        merge_episodes(id = "id", start = "start", end = "end") |>
        dplyr::mutate(interval = ivs::iv(start = episode_start, end = episode_end + 1)) |>
        dplyr::select(id, interval)

    expect_identical(out1a, out1b)

    # POSIXct
    dat2 <- dplyr::tibble(id = id, start = as.POSIXct(start), end = as.POSIXct(end))

    out2a <- dat2 |>
        dplyr::mutate(interval = ivs::iv(start, end + 1)) |>
        dplyr::reframe(interval = ivs::iv_groups(interval, abutting = FALSE), .by = id)|>
        dplyr::arrange(id, interval)

    out2b <- dat2 |>
        merge_episodes(id = "id", start = "start", end = "end") |>
        dplyr::mutate(interval = ivs::iv(start = episode_start, end = episode_end + 1)) |>
        dplyr::select(id, interval)

    expect_identical(out2a, out2b)

    # snapshot for comparison
    expect_snapshot(
        merge_episodes(dat1, id = "id", start = "start", end = "end")
    )
})

test_that("merge_episodes (default method) works on a small set of values", {

    skip_if_not_installed("dplyr", minimum_version = "1.1.0")
    skip_if_not_installed("ivs")

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
        with(merge_episodes(id, start, end)) |>
        dplyr::mutate(interval = ivs::iv(start = episode_start, end = episode_end + 1)) |>
        dplyr::select(id, interval)

    expect_identical(out1a, out1b)

    # POSIXct
    dat2 <- dplyr::tibble(id = id, start = as.POSIXct(start), end = as.POSIXct(end))

    out2a <- dat2 |>
        dplyr::mutate(interval = ivs::iv(start, end + 1)) |>
        dplyr::reframe(interval = ivs::iv_groups(interval, abutting = FALSE), .by = id)|>
        dplyr::arrange(id, interval)

    out2b <- dat2 |>
        with(merge_episodes(id, start, end)) |>
        dplyr::mutate(interval = ivs::iv(start = episode_start, end = episode_end + 1)) |>
        dplyr::select(id, interval)

    expect_identical(out2a, out2b)

    # snapshot for comparison
    expect_snapshot(merge_episodes(id, start, end))
})



test_that("merge_episodes (data.frame method) works on a large set of values", {

    skip_if_not_installed("dplyr", "1.1.0")
    skip_if_not_installed("ivs")

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
        merge_episodes(id = "id", start = "start", end = "end") |>
        dplyr::mutate(interval = ivs::iv(start = episode_start, end = episode_end + 1)) |>
        dplyr::select(id, interval)

    expect_identical(out1a, out1b)

    # POSIXct
    dat2 <- dplyr::tibble(id = id, start = as.POSIXct(start), end = as.POSIXct(end))

    out2a <- dat2 |>
        dplyr::mutate(interval = ivs::iv(start, end + 1)) |>
        dplyr::reframe(interval = ivs::iv_groups(interval, abutting = FALSE), .by = id) |>
        dplyr::arrange(id, interval)

    out2b <- dat2 |>
        merge_episodes(id = "id", start = "start", end = "end") |>
        dplyr::mutate(interval = ivs::iv(start = episode_start, end = episode_end + 1)) |>
        dplyr::select(id, interval)

    expect_identical(out2a, out2b)
})

test_that("merge_episodes (default method) works on a large set of values", {

    skip_if_not_installed("dplyr", "1.1.0")
    skip_if_not_installed("ivs")

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
        with(merge_episodes(id, start, end)) |>
        dplyr::mutate(interval = ivs::iv(start = episode_start, end = episode_end + 1)) |>
        dplyr::select(id, interval)

    expect_identical(out1a, out1b)

    # POSIXct
    dat2 <- dplyr::tibble(id = id, start = as.POSIXct(start), end = as.POSIXct(end))

    out2a <- dat2 |>
        dplyr::mutate(interval = ivs::iv(start, end + 1)) |>
        dplyr::reframe(interval = ivs::iv_groups(interval, abutting = FALSE), .by = id) |>
        dplyr::arrange(id, interval)

    out2b <- dat2 |>
        with(merge_episodes(id, start, end)) |>
        dplyr::mutate(interval = ivs::iv(start = episode_start, end = episode_end + 1)) |>
        dplyr::select(id, interval)

    expect_identical(out2a, out2b)
})


test_that("merge_episodes as expected for different data frame like objects", {

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
    dat <- data.frame(id = id, start = start, end = end)
    tbl <- tibble::as_tibble(dat)
    dt  <- data.table::as.data.table(dat)

    out_dat <- merge_episodes(dat, "id", "start", "end")
    out_tbl <- merge_episodes(tbl, "id", "start", "end")
    out_dt  <- merge_episodes( dt, "id", "start", "end")

    # class is maintained
    expect_identical(class(out_dat), "data.frame")
    expect_true(tibble::is_tibble(out_tbl))
    expect_true(data.table::is.data.table(out_dt))

    # All our equal
    expect_identical(out_dat, as.data.frame(out_tbl))
    expect_identical(out_dat, as.data.frame(out_dt))

})


test_that("add_parent_intervals as expected for different data frame like objects", {

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
    dat <- data.frame(id = id, start = start, end = end)
    tbl <- tibble::as_tibble(dat)
    dt  <- data.table::as.data.table(dat)

    out_dat <- add_parent_interval(dat, "id", "start", "end")
    out_tbl <- add_parent_interval(tbl, "id", "start", "end")
    out_dt  <- add_parent_interval( dt, "id", "start", "end")

    # class is maintained
    expect_identical(class(out_dat), "data.frame")
    expect_true(tibble::is_tibble(out_tbl))
    expect_true(data.table::is.data.table(out_dt))

    # All our equal
    expect_identical(out_dat, as.data.frame(out_tbl))
    expect_identical(out_dat, as.data.frame(out_dt))

})
