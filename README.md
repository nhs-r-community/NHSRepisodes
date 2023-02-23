
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
    reframe(interval = iv_groups(interval, abutting = FALSE), .by = id)
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
#>  1 115303 2020-11-23 2021-02-20
#>  2  15465 2020-07-15 2020-09-05
#>  3  67221 2020-04-24 2020-07-23
#>  4   2603 2020-10-26 2020-12-09
#>  5  39753 2020-11-20 2021-01-05
#>  6  12948 2020-02-10 2020-03-23
#>  7  36370 2020-06-20 2020-08-18
#>  8  31357 2020-06-28 2020-09-02
#>  9  85851 2020-09-16 2020-10-30
#> 10 106298 2020-12-17 2021-03-23
#> # … with 624,990 more rows

system.time(
    big_dat |>
        mutate(interval = iv(start, end + 1)) |>
        reframe(interval = iv_groups(interval, abutting = FALSE), .by = id) ->
        out
        
)
#>    user  system elapsed 
#>  31.989   0.093  32.179
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
#> # A tibble: 335,893 × 4
#>       id .interval_number .episode_start .episode_end
#>    <int>            <int> <date>         <date>      
#>  1     1                1 2020-03-08     2020-04-09  
#>  2     1                2 2020-04-11     2020-07-20  
#>  3     1                3 2020-08-11     2020-09-12  
#>  4     1                4 2020-09-15     2021-01-11  
#>  5     2                1 2020-01-21     2020-02-01  
#>  6     2                2 2020-04-09     2020-07-22  
#>  7     2                3 2020-09-21     2020-11-13  
#>  8     3                1 2020-01-28     2020-04-30  
#>  9     3                2 2020-06-04     2020-08-12  
#> 10     3                3 2020-08-25     2020-10-06  
#> # … with 335,883 more rows

# And for comparison with earlier timings
system.time(
    big_dat |> 
        merge_episodes() |> 
        mutate(interval = iv(start = .episode_start, end = .episode_end + 1)) ->
        out2
)
#>    user  system elapsed 
#>   0.714   0.001   0.579

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
#>  1     1 2020-03-08 2020-04-09 2020-03-08    2020-04-09                 1
#>  2     1 2020-04-11 2020-06-29 2020-04-11    2020-07-20                 2
#>  3     1 2020-05-28 2020-07-20 2020-04-11    2020-07-20                 2
#>  4     1 2020-08-11 2020-08-29 2020-08-11    2020-09-12                 3
#>  5     1 2020-08-25 2020-09-12 2020-08-11    2020-09-12                 3
#>  6     1 2020-09-15 2020-11-17 2020-09-15    2021-01-11                 4
#>  7     1 2020-10-28 2021-01-11 2020-09-15    2021-01-11                 4
#>  8     1 2020-11-23 2020-11-27 2020-09-15    2021-01-11                 4
#>  9     2 2020-01-21 2020-02-01 2020-01-21    2020-02-01                 1
#> 10     2 2020-04-09 2020-06-14 2020-04-09    2020-07-22                 2
#> # … with 624,990 more rows
```
