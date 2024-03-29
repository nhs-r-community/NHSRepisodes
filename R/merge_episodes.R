# -------------------------------------------------------------------------
#' Merge overlapping episodes
#'
# -------------------------------------------------------------------------
#' `merge_episodes()` combines overlapping episodes in to a minimal spanning
#' interval split by in individual identifier. Methods are provided for
#' data.frame like objects.
#'
# -------------------------------------------------------------------------
#' @param x
#'
#' \R object.
#'
#' @param id `[character]`
#'
#' Variable in `x` representing the id associated with the episode.
#'
#' @param start `[character]`
#'
#' Variable in `x` representing the start of the episode.
#'
#' Must refer to a variable that is either class `<Date>` or `<POSIXct>`.
#'
#' @param end `[character]`
#'
#' Variable in `x` representing the start of the episode.
#'
#' Must refer to a variable that is the same class as `start`.
#'
#' @param ...
#'
#' Not currently used.
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
#' merge_episodes(dat)
#'
# -------------------------------------------------------------------------
#' @export
merge_episodes <- function(x, ...) {
    UseMethod("merge_episodes")
}

# -------------------------------------------------------------------------
#' @rdname merge_episodes
#' @export
merge_episodes.default <- function(x, ...) {
    stopf("Not implemented for <%s> objects.", toString(class(x)))
}

# -------------------------------------------------------------------------
#' @rdname merge_episodes
#' @export
merge_episodes.data.table <- function(x, id = "id", start = "start", end = "end", ...) {
    .merge_episodes(x, id = id, start = start, end = end)
}

# -------------------------------------------------------------------------
#' @rdname merge_episodes
#' @export
merge_episodes.tbl_df <- function(x, id = "id", start = "start", end = "end", ...) {
    if (!requireNamespace("tibble")) {
        stop("{tibble} is required to use this function. Please install to continue.")
    }
    DT <- .merge_episodes(x, id = id, start = start, end = end)
    tibble::as_tibble(data.table::setDF(DT))
}

# -------------------------------------------------------------------------
#' @rdname merge_episodes
#' @export
merge_episodes.data.frame <- function(x, id = "id", start = "start", end = "end", ...) {
    DT <- .merge_episodes(x, id = id, start = start, end = end)
    as.data.frame(DT)
}

# ------------------------------------------------------------------------- #
# ------------------------------------------------------------------------- #
# -------------------------------- INTERNALS ------------------------------ #
# ------------------------------------------------------------------------- #
# ------------------------------------------------------------------------- #
.merge_episodes <- function(x, id, start, end) {
    . <- .parent_start <- .parent_end <- NULL # for CRAN package checks
    DT <- .add_parent_interval(
        x,
        id = id,
        start = start,
        end = end,
        call = sys.call(-1L)
    )
    DT <- DT[,
       .(.episode_start = min(.parent_start), .episode_end = max(.parent_end)),
       by = c(id, ".interval_number")]
    setorderv(DT, c(id, ".episode_start"))
}
