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

    expect_snapshot(
        error = TRUE,
        add_parent_interval(dat)
    )

    expect_snapshot(
        error = TRUE,
        add_parent_interval(dat, id = "bob", start = "start", end = "end")
    )

    expect_snapshot(
        error = TRUE,
        add_parent_interval(dat, id = "id", start = "bob", end = "end")
    )

    expect_snapshot(
        error = TRUE,
        add_parent_interval(dat, id = "id", start = "start", end = "bob")
    )

    expect_snapshot(
        error = TRUE,
        add_parent_interval(dat, id = "id", start = "start", end = "end", name_parent_start = "parent_end")
    )

    expect_snapshot(
        error = TRUE,
        add_parent_interval(dat, id = "id", start = "start", end = "end", bob = "bob")
    )

})
