# NHSRepisodes (development version)

- The `merge_episodes()` generic has had it's signature tweaked to widen how it
can be used. This has been done with the addition of a default method that
consequently means the following are equivalent:

```
with(dat, merge_episodes(id, start, end))
reframe(dat, merge_episodes(id, start, end))
merge_episodes(dat, "id", "start", "end")
```

- `add_parent_interval()` has been updated in a similar fashion.

- For both `merge_episodes()` and `add_parent_interval()`, the `id` argument can
  now be of length greater than one. In essence this is akin to constructing
  unique identifiers across multiple variables (I'm unsure if this is useful or
  not at the moment).

- **BREAKING CHANGE**: `merge_episodes` and `add_parent_interval()` now require
column names to be explicitly stated for the data frame methods. I.e. Where, in
the previous release, `merge_episodes(dat)` would have defaults "id", "start"
and "end" for the `id`, `start` and `end` arguments, this would now be written
as `merge_episodes(dat, "id", "start", "end")`.

- Input checking and subsequent error signalling has been improved.

# NHSRepisodes 0.1.0

This is the first (significant) release of the NHSRepisodes package. Since the
earlier, proof of concept version of the package, there have been a few minor
changes that early adopters may observe:

- Fixed bugs in `add_parent_interval()`: one to ensure row ordering is preserved
  and a second to prevent dropping of non-specified columns.
  
- The included README now makes use of recent additions within {dplyr} and will
  require version 1.1.0 (or later) for the examples to run.
  
- Dependencies {rlang} and {cli} have been dropped.

# NHSRepisodes 0.0.0.9000

- Proof of concept / initial development version of the package.
