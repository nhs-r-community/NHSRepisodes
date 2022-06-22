
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
#>        id start      end       
#>     <int> <date>     <date>    
#>  1  29443 2020-01-22 2020-03-02
#>  2  67394 2020-12-29 2021-01-16
#>  3  13998 2020-08-12 2020-08-13
#>  4  67419 2020-02-07 2020-04-13
#>  5  14394 2020-05-25 2020-08-06
#>  6  32913 2020-06-09 2020-09-10
#>  7 110736 2020-05-05 2020-07-09
#>  8 105723 2020-10-29 2021-01-02
#>  9  58685 2020-01-31 2020-04-02
#> 10  49374 2020-08-25 2020-09-10
#> # … with 624,990 more rows

system.time(
    big_dat |>
        mutate(interval = iv(start, end + 1)) |>
        group_by(id) |>
        summarise(interval=iv_groups(interval, abutting = FALSE), .groups = "drop") ->
        out
        
)
#>    user  system elapsed 
#>  32.458   0.100  32.682
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
#> # A tibble: 335,911 × 4
#>       id .interval_number .episode_start .episode_end
#>    <int>            <int> <date>         <date>      
#>  1     1                1 2020-02-25     2020-05-31  
#>  2     1                2 2020-10-27     2021-02-14  
#>  3     2                1 2020-03-09     2020-03-31  
#>  4     2                2 2020-07-14     2021-01-06  
#>  5     3                1 2020-04-17     2020-12-09  
#>  6     4                1 2020-01-21     2020-03-29  
#>  7     4                2 2020-09-04     2020-11-23  
#>  8     5                1 2020-03-07     2020-06-12  
#>  9     5                2 2020-06-22     2020-09-08  
#> 10     5                3 2020-12-16     2020-12-19  
#> # … with 335,901 more rows

# And for comparison with earlier timings
system.time(
    big_dat |> 
        merge_episodes() |> 
        mutate(interval = iv(start = .episode_start, end = .episode_end + 1)) ->
        out2
)
#>    user  system elapsed 
#>   0.743   0.000   0.601

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
#>  1     1 2020-02-25 2020-05-31 2020-02-25    2020-05-31                 1
#>  2     1 2020-03-25 2020-05-14 2020-02-25    2020-05-31                 1
#>  3     1 2020-04-24 2020-05-12 2020-02-25    2020-05-31                 1
#>  4     1 2020-10-27 2020-12-15 2020-10-27    2020-12-27                 2
#>  5     1 2020-10-30 2020-12-27 2020-10-27    2021-02-14                 2
#>  6     1 2020-12-26 2021-02-14 2020-10-27    2021-02-14                 2
#>  7     2 2020-03-09 2020-03-31 2020-03-09    2020-03-31                 1
#>  8     2 2020-07-14 2020-10-16 2020-07-14    2020-12-17                 2
#>  9     2 2020-10-02 2020-12-17 2020-07-14    2021-01-06                 2
#> 10     2 2020-10-25 2021-01-06 2020-07-14    2021-01-06                 2
#> # … with 624,990 more rows
```
