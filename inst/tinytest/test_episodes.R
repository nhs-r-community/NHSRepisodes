library(dplyr)
library(ivs)

# example data 1
id1 = c(1,1,2,2,2,1)
start1 = as.Date(c("2020-01-01", "2020-01-03","2020-04-01", "2020-04-15", "2020-04-17", "2020-05-01"))
end1 = as.Date(c("2020-01-10", "2020-01-10", "2020-04-30", "2020-04-16", "2020-04-19", "2020-10-01"))
(dat1 <- tibble(id=id1,start=start1,end=end1))

dat1 |>
    mutate(interval = iv(start, end + 1)) |>
    group_by(id) |>
    summarise(interval=iv_groups(interval, abutting = FALSE), .groups = "drop") ->
    out1

dat1 |>
    merge_episodes() |>
    mutate(interval = iv(start = .episode_start, end = .episode_end + 1)) |>
    select(id, interval) ->
    out2

expect_identical(out1, out2)


# example data 2
n=10000
id2 <- sample(seq_len(n), size = n * 5, replace = TRUE)
start2 <- as.Date("2020-01-01") + sample.int(365, size = n*5, replace = TRUE)
end2 <- start2 + sample(1:100, size = n*5, replace = TRUE)
(dat2 <- tibble(id=id2, start=start2,end=end2))

dat2 |>
    mutate(interval = iv(start, end + 1)) |>
    group_by(id) |>
    summarise(interval=iv_groups(interval, abutting = FALSE), .groups = "drop") ->
    out3

dat2 |>
    merge_episodes() |>
    mutate(interval = iv(start = .episode_start, end = .episode_end + 1)) |>
    select(id, interval) ->
    out4

expect_identical(out3, out4)




