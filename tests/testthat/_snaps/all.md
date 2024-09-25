# error messaging for add_parent_interval works

    Code
      with(dat, add_parent_interval(id, start, end, name_parent_start = "id"))
    Condition
      Error in `add_parent_interval()`:
      ! Output names must be unique. "id" is used multiple times.

---

    Code
      with(dat, add_parent_interval(id, as.POSIXlt(start), as.POSIXlt(end)))
    Condition
      Error in `add_parent_interval()`:
      ! `start` and `end` columns must both be either <Date> or <POSIXct>.

---

    Code
      with(dat, add_parent_interval(id, start, as.POSIXct(end)))
    Condition
      Error in `add_parent_interval()`:
      ! `start` and `end` columns must both be either <Date> or <POSIXct>.

---

    Code
      with(dat, add_parent_interval(id[-1L], start, end))
    Condition
      Error in `add_parent_interval()`:
      ! `id`, `start` and `end` must be the same length.

---

    Code
      with(dat, add_parent_interval(id, start, end[-1L]))
    Condition
      Error in `add_parent_interval()`:
      ! `id`, `start` and `end` must be the same length.

---

    Code
      add_parent_interval(dat, "id", "start", "end", name_parent_start = "parent_end")
    Condition
      Error in `add_parent_interval()`:
      ! Output names must be unique. "parent_end" is used multiple times.

---

    Code
      add_parent_interval(dat, "id", "start", "end", name_parent_start = "id")
    Condition
      Error in `add_parent_interval()`:
      ! The output name "id" clashes with one of the column names in `x`. Please choose a different name.

---

    Code
      add_parent_interval(dat, "id", "start", "bob")
    Condition
      Error in `add_parent_interval()`:
      ! Not all inputs are present in `x`. No column named "bob" can be found.

# error messaging for merge_episodes works

    Code
      with(dat, merge_episodes(id, start, end, name_episode_start = "id"))
    Condition
      Error in `merge_episodes()`:
      ! Output names must be unique. "id" is used multiple times.

---

    Code
      with(dat, merge_episodes(id[-1L], start, end))
    Condition
      Error in `merge_episodes()`:
      ! Unable to calculate the parent interval.
      Caused by error in `add_parent_interval()`:
      ! `id`, `start` and `end` must be the same length.

---

    Code
      merge_episodes(dat, "id", "start", "end", name_episode_start = "id")
    Condition
      Error in `merge_episodes()`:
      ! Output names must be unique and not match the `id` argument. "id" is used multiple times.

---

    Code
      merge_episodes(dat, "id", "start", "end", name_episode_start = "episode_end")
    Condition
      Error in `merge_episodes()`:
      ! Output names must be unique. "episode_end" is used multiple times.

---

    Code
      merge_episodes(dat, "id", "start", "bob")
    Condition
      Error in `merge_episodes()`:
      ! Unable to calculate the parent interval.
      Caused by error in `add_parent_interval()`:
      ! Not all inputs are present in `x`. No column named "bob" can be found.

# merge_episodes (data.frame method) works on a small set of values

    Code
      merge_episodes(dat1, id = "id", start = "start", end = "end")
    Output
      # A tibble: 3 x 4
           id episode_number episode_start episode_end
        <dbl>          <int> <date>        <date>     
      1     1              1 2020-01-01    2020-01-10 
      2     1              2 2020-05-01    2020-10-01 
      3     2              1 2020-04-01    2020-04-30 

# merge_episodes (default method) works on a small set of values

    Code
      merge_episodes(id, start, end)
    Output
      # A tibble: 3 x 4
           id episode_number episode_start episode_end
        <dbl>          <int> <date>        <date>     
      1     1              1 2020-01-01    2020-01-10 
      2     1              2 2020-05-01    2020-10-01 
      3     2              1 2020-04-01    2020-04-30 

