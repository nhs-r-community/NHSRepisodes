
<!-- README.md is generated from README.Rmd. Please edit that file -->

# Episodes

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R-CMD-check](https://github.com/TimTaylor/episodes/workflows/R-CMD-check/badge.svg)](https://github.com/TimTaylor/episodes/actions)
<!-- badges: end -->

***episodes*** is a (hopefully) temporary solution to a small
inconvenience that relates to
[data.table](https://cran.r-project.org/package=data.table),
[dplyr](https://cran.r-project.org/package=dplyr) and
[ivs](https://cran.r-project.org/package=ivs); namely that dplyr is
currently [slow when working with a large number of
groupings](https://github.com/tidyverse/dplyr/issues/5017) and
data.table [does not support the record
class](https://github.com/Rdatatable/data.table/issues/4910) on which
ivs intervals are based.

To expand on issues consider the following small set of episode data:

``` r
library(episodes)
library(dplyr)
library(ivs)
library(data.table)

id1 = c(1,1,2,2,2,1)
start1 = as.Date(c("2020-01-01", "2020-01-03","2020-04-01", "2020-04-15", "2020-04-17", "2020-05-01"))
end1 = as.Date(c("2020-01-10", "2020-01-10", "2020-04-30", "2020-04-16", "2020-04-19", "2020-10-01"))
(dat <- tibble(id=id1,start=start1,end=end1))
#> # A tibble: 6 × 3
#>      id start      end       
#>   <dbl> <date>     <date>    
#> 1     1 2020-01-01 2020-01-10
#> 2     1 2020-01-03 2020-01-10
#> 3     2 2020-04-01 2020-04-30
#> 4     2 2020-04-15 2020-04-16
#> 5     2 2020-04-17 2020-04-19
#> 6     1 2020-05-01 2020-10-01
```

ivs provides an elegant way to find the minimum spanning interval across
these episodes:

``` r
dat |>
    mutate(interval = iv(start, end + 1)) |>
    group_by(id) |>
    summarise(interval=iv_groups(interval, abutting = FALSE), .groups = "drop")
#> # A tibble: 3 × 2
#>      id                 interval
#>   <dbl>               <iv<date>>
#> 1     1 [2020-01-01, 2020-01-11)
#> 2     1 [2020-05-01, 2020-10-02)
#> 3     2 [2020-04-01, 2020-05-01)
```

This is great when we only have a small number of ids to group by but is
noticeably slow for a larger number:

``` r
n=125000
id2 <- sample(seq_len(n), size = n * 5, replace = TRUE)
start2 <- as.Date("2020-01-01") + sample.int(365, size = n*5, replace = TRUE)
end2 <- start2 + sample(1:100, size = n*5, replace = TRUE)
(big_dat <- tibble(id=id2, start=start2,end=end2))
#> # A tibble: 625,000 × 3
#>       id start      end       
#>    <int> <date>     <date>    
#>  1 17932 2020-06-11 2020-07-17
#>  2 86856 2020-04-16 2020-05-03
#>  3 99862 2020-10-09 2020-12-29
#>  4 65081 2020-06-09 2020-07-14
#>  5 58608 2020-02-20 2020-03-21
#>  6 60298 2020-09-07 2020-09-18
#>  7 75128 2020-12-23 2021-01-19
#>  8 28625 2020-11-26 2021-03-05
#>  9  6430 2020-07-15 2020-10-21
#> 10 81977 2020-07-10 2020-10-01
#> # … with 624,990 more rows

system.time(
    big_dat |>
        mutate(interval = iv(start, end + 1)) |>
        group_by(id) |>
        summarise(interval=iv_groups(interval, abutting = FALSE), .groups = "drop") ->
        out
        
)
#>    user  system elapsed 
#>  33.242   0.105  33.539
```

If you were not already using it, this is likely the time you would
reach for the data.table package. Unfortunately the interval class
created by ivs is built upon on the [record type from
vctrs](https://vctrs.r-lib.org/reference/new_rcrd.html), and this class
is not supported in data.table:

``` r
    DT <- as.data.table(big_dat)
    DT[, interval:=iv(start, end+1)]
#> Error in `[.data.table`(DT, , `:=`(interval, iv(start, end + 1))): Supplied 2 items to be assigned to 625000 items of column 'interval'. If you wish to 'recycle' the RHS please use rep() to make this intent clear to readers of your code.
```

***episodes*** solves this with the `merge_episodes()` function:

``` r
system.time(
    big_dat |> 
        merge_episodes() |> 
        mutate(interval = iv(start = .episode_start, end = .episode_end + 1)) ->
        out2
)
#>    user  system elapsed 
#>   0.824   0.000   0.682

# check for equality
all.equal(out, select(out2, id, interval))
#> [1] TRUE
```

We also provide another function `add_parent_interval()` that associates
the the minimum spanning interval with each observation without reducing
to the unique values:

``` r
add_parent_interval(big_dat)
#> # A tibble: 625,000 × 6
#>       id start      end        .parent_start .parent_end .interval_number
#>    <int> <date>     <date>     <date>        <date>                 <int>
#>  1     1 2020-08-19 2020-10-03 2020-08-19    2020-10-14                 1
#>  2     1 2020-09-23 2020-10-14 2020-08-19    2020-10-14                 1
#>  3     1 2020-12-26 2021-02-16 2020-12-26    2021-02-16                 2
#>  4     2 2020-01-09 2020-02-17 2020-01-09    2020-02-17                 1
#>  5     2 2020-04-27 2020-05-10 2020-04-27    2020-05-10                 2
#>  6     2 2020-09-05 2020-11-23 2020-09-05    2020-11-23                 3
#>  7     3 2020-01-17 2020-01-19 2020-01-17    2020-01-19                 1
#>  8     3 2020-03-10 2020-06-03 2020-03-10    2020-06-03                 2
#>  9     3 2020-06-08 2020-07-20 2020-06-08    2020-07-20                 3
#> 10     3 2020-09-30 2020-11-28 2020-09-30    2020-11-28                 4
#> # … with 624,990 more rows
```
