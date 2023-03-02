
<!-- README.md is generated from README.Rmd. Please edit that file -->

# NHSRepisodes

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R-CMD-check](https://github.com/nhs-r-community/NHSRepisodes/workflows/R-CMD-check/badge.svg)](https://github.com/nhs-r-community/NHSRepisodes/actions)
<!-- badges: end -->

***NHSRepisodes*** is a (hopefully) temporary solution to a small
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
library(NHSRepisodes)
library(dplyr)
library(ivs)
library(data.table)

# note - we need functionality introduced in dplyr 1.1.0.
if (getNamespaceVersion("dplyr") < "1.1.0") {
    warning("Please update dplyr to version 1.1.0 or higher to run these examples.")
    knitr::knit_exit()
}
    

# Create a dummy data set give the first and last dates of an episode
dat <- tribble(
    ~id, ~start, ~end,
    1L, "2020-01-01", "2020-01-10",
    1L, "2020-01-03", "2020-01-10",
    2L, "2020-04-01", "2020-04-30",
    2L, "2020-04-15", "2020-04-16",
    2L, "2020-04-17", "2020-04-19",
    1L, "2020-05-01", "2020-10-01",
    1L, "2020-01-01", "2020-01-10",
    1L, "2020-01-11", "2020-01-12",
)

# This will create an object called dat and also open in the console
(dat <- mutate(dat, across(start:end, as.Date)))
#> # A tibble: 8 × 3
#>      id start      end       
#>   <int> <date>     <date>    
#> 1     1 2020-01-01 2020-01-10
#> 2     1 2020-01-03 2020-01-10
#> 3     2 2020-04-01 2020-04-30
#> 4     2 2020-04-15 2020-04-16
#> 5     2 2020-04-17 2020-04-19
#> 6     1 2020-05-01 2020-10-01
#> 7     1 2020-01-01 2020-01-10
#> 8     1 2020-01-11 2020-01-12
```

The {ivs} package provides an elegant way to find the minimum spanning
interval across these episodes:

``` r
dat |>
    mutate(interval = iv(start = start, end = end + 1)) |>
    reframe(interval = iv_groups(interval, abutting = FALSE), .by = id)
#> # A tibble: 4 × 2
#>      id                 interval
#>   <int>               <iv<date>>
#> 1     1 [2020-01-01, 2020-01-11)
#> 2     1 [2020-01-11, 2020-01-13)
#> 3     1 [2020-05-01, 2020-10-02)
#> 4     2 [2020-04-01, 2020-05-01)
```

Note that {ivs} creates intervals that are *right-open* meaning they are
inclusive on the left (have an opening square bracket `[`) and exclusive
on the right (with a closing a rounded bracket `)`). Consequently, in
our first call to `mutate()` we added 1 to the `end` value. This ensures
that the full range of dates are considered (e.g. for the first row we
want to consider all days from `2020-01-01` to `2020-01-10` not only up
until `2020-01-09`).

This works great when we only have a small number of ids to group by.
However, it becomes noticeably slow for a larger number:

``` r
# Creating a larger data set
n <- 125000
id2 <- sample(seq_len(n), size = n * 5, replace = TRUE)
start2 <- as.Date("2020-01-01") + sample.int(365, size = n * 5, replace = TRUE)
end2 <- start2 + sample(1:100, size = n * 5, replace = TRUE)

# creates the object big_dat and shows the first 10 rows as a tibble in the console
(big_dat <- tibble(id = id2, start = start2, end = end2))
#> # A tibble: 625,000 × 3
#>        id start      end       
#>     <int> <date>     <date>    
#>  1  33679 2020-07-10 2020-08-03
#>  2 110401 2020-06-19 2020-06-23
#>  3  21667 2020-07-27 2020-09-14
#>  4  45126 2020-12-03 2021-02-13
#>  5  87209 2020-04-08 2020-04-10
#>  6 114414 2020-12-03 2021-01-24
#>  7  61087 2020-02-04 2020-04-28
#>  8  71417 2020-02-06 2020-04-11
#>  9 105663 2020-12-01 2020-12-17
#> 10 101811 2020-10-09 2020-12-10
#> # … with 624,990 more rows

# checking the time to run
system.time(
    out <- big_dat |>
        mutate(interval = iv(start, end + 1)) |>
        reframe(interval = iv_groups(interval, abutting = FALSE), .by = id)
)
#>    user  system elapsed 
#>  32.398   0.153  32.687
```

If you were not already using it, this is likely the time you would
reach for the {data.table} package. Unfortunately the interval class
created by {ivs} is built upon on the [record type from
vctrs](https://vctrs.r-lib.org/reference/new_rcrd.html), and this class
is not supported in {data.table}:

``` r
DT <- as.data.table(big_dat)
DT[, interval := iv(start, end + 1)]
#> Error in `[.data.table`(DT, , `:=`(interval, iv(start, end + 1))): Supplied 2 items to be assigned to 625000 items of column 'interval'. If you wish to 'recycle' the RHS please use rep() to make this intent clear to readers of your code.
```

***NHSRepisodes*** solves this with the `merge_episodes()` function:

``` r
merge_episodes(big_dat)
#> # A tibble: 335,915 × 4
#>       id .interval_number .episode_start .episode_end
#>    <int>            <int> <date>         <date>      
#>  1     1                1 2020-04-23     2020-06-21  
#>  2     1                2 2020-12-10     2021-02-04  
#>  3     2                1 2020-04-27     2020-05-23  
#>  4     2                2 2020-05-24     2020-07-03  
#>  5     2                3 2020-09-24     2020-12-02  
#>  6     3                1 2020-03-16     2020-07-27  
#>  7     3                2 2020-10-10     2020-10-31  
#>  8     4                1 2020-01-15     2020-06-03  
#>  9     4                2 2020-09-06     2021-03-19  
#> 10     5                1 2020-06-19     2020-09-23  
#> # … with 335,905 more rows

# And for comparison with earlier timings
system.time(
    out2 <- big_dat |>
        merge_episodes() |>
        mutate(interval = iv(start = .episode_start, end = .episode_end + 1))
)
#>    user  system elapsed 
#>   0.718   0.005   0.588

# equal output (subject to ordering)
all.equal(arrange(out, id, interval), select(out2, id, interval))
#> [1] TRUE
```

We also provide another function `add_parent_interval()` that associates
the the minimum spanning interval with each observation without reducing
to the unique values:

``` r
add_parent_interval(dat)
#> # A tibble: 8 × 6
#>      id start      end        .parent_start .parent_end .interval_number
#>   <int> <date>     <date>     <date>        <date>                 <int>
#> 1     1 2020-01-01 2020-01-10 2020-01-01    2020-01-10                 1
#> 2     1 2020-01-01 2020-01-10 2020-01-01    2020-01-10                 1
#> 3     1 2020-01-03 2020-01-10 2020-01-01    2020-01-10                 1
#> 4     1 2020-01-11 2020-01-12 2020-01-11    2020-01-12                 2
#> 5     1 2020-05-01 2020-10-01 2020-05-01    2020-10-01                 3
#> 6     2 2020-04-01 2020-04-30 2020-04-01    2020-04-30                 1
#> 7     2 2020-04-15 2020-04-16 2020-04-01    2020-04-30                 1
#> 8     2 2020-04-17 2020-04-19 2020-04-01    2020-04-30                 1
```
