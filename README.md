
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
#>        id start      end       
#>     <int> <date>     <date>    
#>  1  48768 2020-10-31 2020-11-01
#>  2 102240 2020-01-15 2020-02-03
#>  3  39531 2020-03-12 2020-05-01
#>  4   1051 2020-10-19 2020-12-11
#>  5    541 2020-11-23 2021-01-13
#>  6 103069 2020-01-18 2020-04-06
#>  7  30936 2020-04-20 2020-04-28
#>  8  66793 2020-12-09 2021-03-09
#>  9  42456 2020-07-21 2020-08-07
#> 10  94291 2020-07-09 2020-08-13
#> # … with 624,990 more rows

system.time(
    big_dat |>
        mutate(interval = iv(start, end + 1)) |>
        group_by(id) |>
        summarise(interval=iv_groups(interval, abutting = FALSE), .groups = "drop") ->
        out
        
)
#>    user  system elapsed 
#>  32.067   0.102  32.260
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
merge_episodes(big_dat)
#> # A tibble: 335,831 × 4
#>       id .interval_number .episode_start .episode_end
#>    <int>            <int> <date>         <date>      
#>  1     1                1 2020-01-24     2020-03-16  
#>  2     1                2 2020-05-22     2020-06-25  
#>  3     1                3 2020-08-20     2020-11-15  
#>  4     2                1 2020-01-07     2020-01-22  
#>  5     2                2 2020-03-26     2020-08-27  
#>  6     2                3 2020-09-10     2020-11-27  
#>  7     3                1 2020-01-07     2020-01-14  
#>  8     3                2 2020-08-05     2020-10-01  
#>  9     4                1 2020-02-04     2020-02-20  
#> 10     4                2 2020-02-27     2020-05-02  
#> # … with 335,821 more rows

# And for comparison with earlier timings
system.time(
    big_dat |> 
        merge_episodes() |> 
        mutate(interval = iv(start = .episode_start, end = .episode_end + 1)) ->
        out2
)
#>    user  system elapsed 
#>   0.698   0.000   0.564

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
#>  1     1 2020-01-24 2020-03-16 2020-01-24    2020-03-16                 1
#>  2     1 2020-05-22 2020-06-25 2020-05-22    2020-06-25                 2
#>  3     1 2020-08-20 2020-10-10 2020-08-20    2020-11-15                 3
#>  4     1 2020-10-04 2020-11-15 2020-08-20    2020-11-15                 3
#>  5     2 2020-01-07 2020-01-22 2020-01-07    2020-01-22                 1
#>  6     2 2020-03-26 2020-05-04 2020-03-26    2020-07-08                 2
#>  7     2 2020-05-04 2020-07-08 2020-03-26    2020-08-01                 2
#>  8     2 2020-05-31 2020-08-01 2020-03-26    2020-08-27                 2
#>  9     2 2020-07-21 2020-08-27 2020-03-26    2020-08-27                 2
#> 10     2 2020-09-10 2020-11-27 2020-09-10    2020-11-27                 3
#> # … with 624,990 more rows
```
