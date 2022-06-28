test_that("merge_episodes works on a small set of values", {
    id1 = c(1,1,2,2,2,1)
    start1 = as.Date(c("2020-01-01", "2020-01-03","2020-04-01", "2020-04-15", "2020-04-17", "2020-05-01"))
    end1 = as.Date(c("2020-01-10", "2020-01-10", "2020-04-30", "2020-04-16", "2020-04-19", "2020-10-01"))

    # Date
    dat1 <- dplyr::tibble(id=id1,start=start1,end=end1)

    dat1 |>
        dplyr::mutate(interval = ivs::iv(start, end + 1)) |>
        dplyr::group_by(id) |>
        dplyr::summarise(interval=ivs::iv_groups(interval, abutting = FALSE), .groups = "drop") ->
        out1a

    dat1 |>
        merge_episodes() |>
        dplyr::mutate(interval = ivs::iv(start = .episode_start, end = .episode_end + 1)) |>
        dplyr::select(id, interval) ->
        out1b

    expect_identical(out1a, out1b)

    # POSIXct
    dat3 <- dplyr::tibble(id=id1,start=as.POSIXct(start1),end=as.POSIXct(end1))

    dat3 |>
        dplyr::mutate(interval = ivs::iv(start, end + 1)) |>
        dplyr::group_by(id) |>
        dplyr::summarise(interval=ivs::iv_groups(interval, abutting = FALSE), .groups = "drop") ->
        out3a

    dat3 |>
        merge_episodes() |>
        dplyr::mutate(interval = ivs::iv(start = .episode_start, end = .episode_end + 1)) |>
        dplyr::select(id, interval) ->
        out3b

    expect_identical(out3a, out3b)

    # snapshot for comparison
    expect_snapshot_output(merge_episodes(dat1))

})


test_that("merge_episodes works on a large set of values", {
    set.seed(99)
    n=10000
    id2 <- sample(seq_len(n), size = n * 5, replace = TRUE)
    start2 <- as.Date("2020-01-01") + sample.int(365, size = n*5, replace = TRUE)
    end2 <- start2 + sample(1:100, size = n*5, replace = TRUE)

    # Dates
    dat2 <- dplyr::tibble(id=id2, start=start2,end=end2)

    dat2 |>
        dplyr::mutate(interval = ivs::iv(start, end + 1)) |>
        dplyr::group_by(id) |>
        dplyr::summarise(interval=ivs::iv_groups(interval, abutting = FALSE), .groups = "drop") ->
        out2a

    dat2 |>
        merge_episodes() |>
        dplyr::mutate(interval = ivs::iv(start = .episode_start, end = .episode_end + 1)) |>
        dplyr::select(id, interval) ->
        out2b

    expect_identical(out2a, out2b)

    # POSIXct
    dat4 <- dplyr::tibble(id=id2,start=as.POSIXct(start2),end=as.POSIXct(end2))

    dat4 |>
        dplyr::mutate(interval = ivs::iv(start, end + 1)) |>
        dplyr::group_by(id) |>
        dplyr::summarise(interval=ivs::iv_groups(interval, abutting = FALSE), .groups = "drop") ->
        out4a

    dat4 |>
        merge_episodes() |>
        dplyr::mutate(interval = ivs::iv(start = .episode_start, end = .episode_end + 1)) |>
        dplyr::select(id, interval) ->
        out4b

    expect_identical(out4a, out4b)

})


