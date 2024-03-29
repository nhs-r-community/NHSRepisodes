# -------------------------------------------------------------------------
#' Calculate parent intervals
#'
# -------------------------------------------------------------------------
#' `add_parent_interval()` calculates the minimum spanning interval that
#' contains overlapping episodes and adds this to the input. Methods are
#' provided for data.frame like objects.
#'
# -------------------------------------------------------------------------
#' @param x
#'
#' \R object.
#'
#' @param id `[character]`
#'
#' Variable in `x` representing the id associated with an episode.
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
#' The input data with additional columns for the corresponding parent interval
#' (split across `id` values).
#'
#' Additional columns will be labelled '.parent_start', '.parent_end' and
#' '.interval_number' where the interval number is in order of occurrence of
#' the corresponding parent interval.
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
#' add_parent_interval(dat)
#'
# -------------------------------------------------------------------------
#' @export
add_parent_interval <- function(x, ...) {
    UseMethod("add_parent_interval")
}

# -------------------------------------------------------------------------
#' @rdname add_parent_interval
#' @export
add_parent_interval.default <- function(x, ...) {
    stopf("Not implemented for <%s> objects.", toString(class(x)))
}

# -------------------------------------------------------------------------
#' @rdname add_parent_interval
#' @export
add_parent_interval.data.table <- function(x, id = "id", start = "start", end = "end", ...) {
    .add_parent_interval(x, id = id, start = start, end = end)
}

# -------------------------------------------------------------------------
#' @rdname add_parent_interval
#' @export
add_parent_interval.tbl_df <- function(x, id = "id", start = "start", end = "end", ...) {
    if (!requireNamespace("tibble")) {
        stop("{tibble} is required to use this function. Please install to continue.")
    }
    out <- .add_parent_interval(x, id = id, start = start, end = end)
    tibble::as_tibble(data.table::setDF(out))
}

# -------------------------------------------------------------------------
#' @rdname add_parent_interval
#' @export
add_parent_interval.data.frame <- function(x, id = "id", start = "start", end = "end", ...) {
    out <- .add_parent_interval(x, id = id, start = start, end = end)
    as.data.frame(out)
}


# ------------------------------------------------------------------------- #
# ------------------------------------------------------------------------- #
# -------------------------------- INTERNALS ------------------------------ #
# ------------------------------------------------------------------------- #
# ------------------------------------------------------------------------- #
.add_parent_interval <- function(x, id, start, end, call = sys.call(-1L)) {

    .position <- NULL # for CRAN package checks

    # check input data.frame does not used reserved names
    # TODO - this could be better but will suffice for time being
    reserved <- c(".position", ".parent_start", ".parent_end", ".interval_number")
    nms <- names(x)
    matches <- nms[nms %in% reserved]
    if (length(matches)) {
        stopf(
            "`x` cannot have a column named %s for this function to work",
            sQuote(matches[1L])
        )
    }

    # check specified columns are present
    vars <- c(id, start, end)
    present <- vars %in% nms
    if (any(!present)) {
        v <- vars[!present][1]
        stopf("%s is not a column in `x`", sQuote(v), .call = call)
    }

    # check start and end are of a valid and identical class
    vec_start <- .subset2(x, start)
    vec_end <- .subset2(x, end)
    start_cond <- !inherits(vec_start, "Date") && !inherits(vec_start, "POSIXct")
    end_cond <- !inherits(vec_end, "Date") && !inherits(vec_end, "POSIXct")
    i_cond <- !identical(class(vec_start), class(vec_end))
    if (start_cond || end_cond || i_cond) {
        stopf("`start` and `end` columns must both be either <Date> or <POSIXct>.")
    }

    # Ensure input is data.table
    DT <- as.data.table(x)

    # add position column so we can return original ordering
    DT[, .position := .I]

    # .calculate_parent requires us to be ordered by start date to work
    setorderv(DT, cols = c(id, start))
    DT[,c(".parent_start", ".parent_end", ".interval_number") :=
           .calculate_parent(start, end), keyby = c(id)]

    # return original ordering
    setorder(DT, .position)
    DT[,.position :=NULL]
}

.calculate_parent <- function(start, end) {
    .Call("calculate_parent", start, end)
}
