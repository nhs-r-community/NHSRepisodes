test_that("error messaging works", {
    dat <- data.frame(
        id   = c(1,1,2,2,2,1),
        start = as.Date(c("2020-01-01", "2020-01-03","2020-04-01",
                          "2020-04-15", "2020-04-17", "2020-05-01")),
        end   = as.Date(c("2020-01-10", "2020-01-10", "2020-04-30",
                          "2020-04-16", "2020-04-19", "2020-10-01"))
    )

    expect_snapshot_error(add_parent_interval("bob"))
    expect_snapshot_error(merge_episodes("bob"))

    dat2 <- dat
    names(dat2)[3] <- "e"
    expect_snapshot_error(add_parent_interval(dat2))

    dat3 <- dat
    dat3$end <- as.numeric(dat3$end)
    expect_snapshot_error(add_parent_interval(dat3))


})
