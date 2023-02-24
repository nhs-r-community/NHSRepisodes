
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
if (getNamespaceVersion("dplyr") < "1.1.0")
    stop("Please update dplyr to version 1.1.0 or higher to run these examples.")
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

ivs provides an elegant way to find the minimum spanning interval across
these episodes:

``` r
dat |>
    mutate(interval = iv(start, end + 1)) |>
    reframe(interval = iv_groups(interval, abutting = FALSE), .by = id)
#> # A tibble: 4 × 2
#>      id                 interval
#>   <int>               <iv<date>>
#> 1     1 [2020-01-01, 2020-01-11)
#> 2     1 [2020-01-11, 2020-01-13)
#> 3     1 [2020-05-01, 2020-10-02)
#> 4     2 [2020-04-01, 2020-05-01)
```

This is great when we only have a small number of ids to group by but is
noticeably slow for a larger number:

``` r
n <- 125000
id2 <- sample(seq_len(n), size = n * 5, replace = TRUE)
start2 <- as.Date("2020-01-01") + sample.int(365, size = n*5, replace = TRUE)
end2 <- start2 + sample(1:100, size = n*5, replace = TRUE)
(big_dat <- tibble(id=id2, start=start2,end=end2))
#> # A tibble: 625,000 × 3
#>        id start      end       
#>     <int> <date>     <date>    
#>  1 118011 2020-04-29 2020-05-11
#>  2  67643 2020-09-09 2020-10-28
#>  3  15579 2020-07-10 2020-08-28
#>  4  42415 2020-04-10 2020-06-11
#>  5  19183 2020-07-24 2020-09-30
#>  6  12678 2020-03-09 2020-05-29
#>  7  62065 2020-09-24 2020-10-07
#>  8  66902 2020-08-09 2020-10-28
#>  9  51506 2020-12-24 2021-01-23
#> 10  93303 2020-08-17 2020-10-04
#> # … with 624,990 more rows

system.time(
    big_dat |>
        mutate(interval = iv(start, end + 1)) |>
        reframe(interval = iv_groups(interval, abutting = FALSE), .by = id) ->
        out
        
)
#>    user  system elapsed 
#>  32.429   0.081  32.611
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

***NHSRepisodes*** solves this with the `merge_episodes()` function:

``` r
merge_episodes(big_dat)
#> # A tibble: 336,583 × 4
#>       id .interval_number .episode_start .episode_end
#>    <int>            <int> <date>         <date>      
#>  1     1                1 2020-06-07     2020-08-27  
#>  2     1                2 2020-10-01     2021-02-26  
#>  3     2                1 2020-01-24     2020-04-14  
#>  4     2                2 2020-07-21     2020-10-02  
#>  5     2                3 2020-10-14     2021-01-19  
#>  6     3                1 2020-01-16     2020-03-22  
#>  7     3                2 2020-04-04     2020-06-08  
#>  8     3                3 2020-08-31     2021-01-23  
#>  9     4                1 2020-02-25     2020-03-21  
#> 10     4                2 2020-03-26     2020-05-08  
#> # … with 336,573 more rows

# And for comparison with earlier timings
system.time(
    big_dat |> 
        merge_episodes() |> 
        mutate(interval = iv(start = .episode_start, end = .episode_end + 1)) ->
        out2
)
#>    user  system elapsed 
#>   0.713   0.007   0.583

# equal output (subject to ordering)
all.equal(arrange(out, id, interval), select(out2, id, interval))
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
#>  1     1 2020-06-07 2020-08-27 2020-06-07    2020-08-27                 1
#>  2     1 2020-08-13 2020-08-15 2020-06-07    2020-08-27                 1
#>  3     1 2020-10-01 2020-12-22 2020-10-01    2021-02-26                 2
#>  4     1 2020-12-09 2021-02-26 2020-10-01    2021-02-26                 2
#>  5     2 2020-01-24 2020-04-14 2020-01-24    2020-04-14                 1
#>  6     2 2020-01-27 2020-02-03 2020-01-24    2020-04-14                 1
#>  7     2 2020-07-21 2020-10-02 2020-07-21    2020-10-02                 2
#>  8     2 2020-10-14 2020-11-01 2020-10-14    2020-11-11                 3
#>  9     2 2020-10-29 2020-11-11 2020-10-14    2021-01-19                 3
#> 10     2 2020-11-03 2021-01-19 2020-10-14    2021-01-19                 3
#> # … with 624,990 more rows
```
