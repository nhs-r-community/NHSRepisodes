# -------------------------------------------------------------------------
#' Merge overlapping episodes
#'
# -------------------------------------------------------------------------
#' `merge_episodes()` combines overlapping episodes in to a minimal spanning
#' interval split by in individual identifier.
#'
# -------------------------------------------------------------------------
#' @param ... Further arguments passed to or from other methods.
#'
#' @param x
#'
#' Data frame like object.
#'
#' @param id
#'
#' For the default method, vector representing the id associated with the
#' episode.
#'
#' For the data frame method, a variable in `x` representing the id associated
#' with the episode.
#'
#' @param start
#'
#' For the default method, vector representing episode start date/time.
#'
#' For the data frame method, a variable in `x` representing the episode start.
#'
#' Variable must be a `<Date>` or `<POSIXct>` object.
#'
#' @param end
#'
#' For the default method, vector representing episode end date/time.
#'
#' For the data frame method, a variable in `x` representing the episode end.
#'
#' Variable must be a `<Date>` or `<POSIXct>` object.
#'
#' Must refer to a variable that is the same class as `start`.
#'
#' @param name_id
#'
#' The column name to use for the patient id in the output.
#'
#' @param name_episode_start
#'
#' The column name to use for the start of the episode in the output.
#'
#' @param name_episode_end
#'
#' The column name to use for the end of the episode in the output.
#'
#' @param name_episode_number
#'
#' The column name to use for the episode number of an individual patient in the
#' output.
#'
# -------------------------------------------------------------------------
#' @return
#'
#' The resulting combined episode intervals split by id and ordered by interval
#' number.
#'
#' The returned object will be of the same class as the input `x` (i.e. a
#' data.frame, data.table or tibble).
#'
# -------------------------------------------------------------------------
#' @examples
#' dat <- data.frame(
#'     id = c(1, 1, 2, 2, 2, 1),
#'     start = as.Date(c(
#'         "2020-01-01", "2020-01-03", "2020-04-01",
#'         "2020-04-15", "2020-04-17", "2020-05-01"
#'     )),
#'     end = as.Date(c(
#'         "2020-01-10", "2020-01-10", "2020-04-30",
#'         "2020-04-16", "2020-04-19", "2020-10-01"
#'     ))
#' )
#'
#' with(dat, merge_episodes(id, start, end))
#' merge_episodes(dat, id = "id", start = "start", end = "end")
#'
# -------------------------------------------------------------------------
#' @export
merge_episodes <- function(...) {
    UseMethod("merge_episodes")
}

# -------------------------------------------------------------------------
#' @rdname merge_episodes
#' @importFrom cli cli_abort
#' @importFrom rlang check_dots_empty0
#' @importFrom data.table setDT setnames setorderv setDF
#' @export
merge_episodes.default <- function(
    id,
    start,
    end,
    ...,
    name_id = "id",
    name_episode_start = "episode_start",
    name_episode_end = "episode_end",
    name_episode_number = "episode_number"
) {

    # for CRAN checks due to NSE
    . <- parent_start <- parent_end <- NULL

    check_dots_empty0(...)

    # calculate the parent interval
    dat <- tryCatch(
        add_parent_interval(
            id = id,
            start = start,
            end = end,
            name_id = name_id,
            name_parent_start = "parent_start",
            name_parent_end = "parent_end",
            name_interval_number = name_episode_number
        ),
        error = function(cnd) {
            cli_abort("Unable to calculate the parent interval.", parent = cnd)
        }
    )

    # Check for duplicate output names before creating the output
    names <- c(name_id, name_episode_start, name_episode_end, name_episode_number)
    if (dup <- anyDuplicated(names)) {
        duplicate <- names[dup]
        cli_abort("Output names must be unique. {.str {duplicate}} is used multiple times.")
    }

    # use data.table calculate the start and end by id and episode
    setDT(dat)
    dat <- dat[,
        .(episode_start = min(parent_start), episode_end = max(parent_end)),
        by = c(name_id, name_episode_number)]

    # update names
    setnames(
        dat,
        old = c("episode_start", "episode_end"),
        new = c(name_episode_start, name_episode_end)
    )

    # order first by id and then start
    setorderv(dat, c(name_id, name_episode_start))

    # return as tibble
    tibble::as_tibble(setDF(dat))
}

# -------------------------------------------------------------------------
#' @rdname merge_episodes
#' @importFrom cli cli_abort
#' @importFrom rlang check_dots_empty0
#' @importFrom data.table setDT setnames setorderv setDF
#' @export
merge_episodes.data.frame <- function(
    x,
    id,
    start,
    end,
    ...,
    name_episode_start = "episode_start",
    name_episode_end = "episode_end",
    name_episode_number = "episode_number"
) {

    # for CRAN checks due to NSE
    . <- parent_start <- parent_end <- NULL

    check_dots_empty0(...)

    # add the parent interval
    dat <- tryCatch(
        add_parent_interval(
            x = x,
            id = id,
            start = start,
            end = end,
            name_parent_start = "parent_start",
            name_parent_end = "parent_end",
            name_interval_number = name_episode_number
        ),
        error = function(cnd) {
            cli_abort("Unable to calculate the parent interval.", parent = cnd)
        }
    )

    # Check for valid output names before creating the output
    names <- c(name_episode_start, name_episode_end, name_episode_number)
    invalid <- names %in% id
    if (any(invalid)) { # this shouldn't be NA if add_parent_interval has been called first
        invalid <- names[invalid][1L]
        cli_abort(
            "Output names must be unique and not match the {.arg id} argument.
            {.str {invalid}} is used multiple times."
        )
    }

    if (dup <- anyDuplicated(names)) {
        duplicate <- names[dup]
        cli_abort("Output names must be unique. {.str {duplicate}} is used multiple times.")
    }

    # use data.table calculate the start and end by id and episode
    setDT(dat)
    dat <- dat[,
               .(episode_start = min(parent_start), episode_end = max(parent_end)),
               by = c(id, name_episode_number)]



    # update names
    setnames(
        dat,
        old = c("episode_start", "episode_end"),
        new = c(name_episode_start, name_episode_end)
    )

    # order first by id and then start
    setorderv(dat, c(id, name_episode_start))

    # return as data frame
    setDF(dat)[]
}

# -------------------------------------------------------------------------
#' @rdname merge_episodes
#' @importFrom data.table setDT
#' @export
merge_episodes.data.table <- function(
    x,
    id,
    start,
    end,
    ...,
    name_episode_start = "episode_start",
    name_episode_end = "episode_end",
    name_episode_number = "episode_number"
) {
    x <- as.data.frame(x)
    out <- NextMethod()
    setDT(out)[]
}

# -------------------------------------------------------------------------
#' @rdname merge_episodes
#' @importFrom tibble as_tibble
#' @export
merge_episodes.tbl_df <- function(x, id = "id", start = "start", end = "end", ...) {
    out <- NextMethod()
    as_tibble(out)
}
