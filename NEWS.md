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
