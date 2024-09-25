# error messaging for add_parent_interval works

    Code
      add_parent_interval(dat)
    Condition
      Error in `add_parent_interval.data.frame()`:
      ! argument `id` is missing, with no default.

---

    Code
      add_parent_interval(dat, id = "bob", start = "start", end = "end")
    Condition
      Error in `add_parent_interval()`:
      ! Not all inputs are present in `x`. No column named "bob" can be found.

---

    Code
      add_parent_interval(dat, id = "id", start = "bob", end = "end")
    Condition
      Error in `add_parent_interval()`:
      ! Not all inputs are present in `x`. No column named "bob" can be found.

---

    Code
      add_parent_interval(dat, id = "id", start = "start", end = "bob")
    Condition
      Error in `add_parent_interval()`:
      ! Not all inputs are present in `x`. No column named "bob" can be found.

---

    Code
      add_parent_interval(dat, id = "id", start = "start", end = "end",
        name_parent_start = "parent_end")
    Condition
      Error in `add_parent_interval()`:
      ! Output names must be unique. "parent_end" is used multiple times.

---

    Code
      add_parent_interval(dat, id = "id", start = "start", end = "end", bob = "bob")
    Condition
      Error in `add_parent_interval()`:
      ! `...` must be empty.
      x Problematic argument:
      * bob = "bob"

