#' Calculate parent intervals
#'
#' @description
#' `add_parent_interval()` calculates the minimum spanning interval that
#' contains overlapping episodes and adds this to the input. Methods are
#' provided for data.frame like objects.
#'
#' @param x
#' An \R object.
#'
#' @param id `[character]`
#' Variable in `x` representing the id associated with an episode.
#'
#' @param start `[character]`
#' Variable in `x` representing the start of the episode.
#'
#' @param end `[character]`
#' Variable in `x` representing the start of the episode.
#'
#' @param ...
#' Not currently used.
#'
#' @return
#' The input data with additional columns for the corresponding parent interval.
#' The returned object will be of the same class as the input `x` (i.e. a
#' data.frame, data.table or tibble).
#'
#' @examples
#' dat <- data.frame(
#'     id   = c(1,1,2,2,2,1),
#'     start = as.Date(c("2020-01-01", "2020-01-03","2020-04-01",
#'                       "2020-04-15", "2020-04-17", "2020-05-01")),
#'     end   = as.Date(c("2020-01-10", "2020-01-10", "2020-04-30",
#'                       "2020-04-16", "2020-04-19", "2020-10-01"))
#' )
#'
#' add_parent_interval(dat)
#'
#' @export
add_parent_interval <- function(x, id = "id", start = "start", end = "end", ...) {
    UseMethod("add_parent_interval")
}

#' @rdname add_parent_interval
#' @export
add_parent_interval.default <- function(x, ...) {
    stop(sprintf("Not implemented for class [%s].", paste(class(x), collapse = ", ")))
}

#' @rdname add_parent_interval
#' @export
add_parent_interval.data.table <- function(x, id = "id", start = "start", end = "end", ...) {
    .validate_inputs(x = x, id = id, start = start, end = end)
    vec_id <- .subset2(x, id)
    start <- .subset2(x, start)
    end <- .subset2(x, end)
    out <- .add_parent_interval(vec_id,start,end)
    setnames(out, old = "id", new = id)
}

#' @rdname add_parent_interval
#' @export
add_parent_interval.tbl_df <- function(x, id = "id", start = "start", end = "end", ...) {
    x <- as.data.table(x)
    x <- add_parent_interval.data.table(x, id=id, start=start, end=end)
    tibble::as_tibble(setDF(x))
}

#' @rdname add_parent_interval
#' @export
add_parent_interval.data.frame <- function(x, id = "id", start = "start", end = "end", ...) {
    x <- as.data.table(x)
    x <- add_parent_interval.data.table(x, id=id, start=start, end=end)
    as.data.frame(x)
}


# -------------------------------------------------------------------------
# internals ---------------------------------------------------------------
# -------------------------------------------------------------------------
.validate_inputs <- function(x, id, start, end) {
    nms <- names(x)
    vars <- c(id, start, end)
    present <- vars %in% nms
    if (any(!present))
        stop(sprintf("'%s' is not a column in `x`", vars[!present][1]), call. = FALSE)
    s <- .subset2(x, start)
    e <- .subset2(x, end)
    if (!identical(class(s), class(e)))
        stop("`start` and `end` must be the same class")
    invisible(x)
}

.add_parent_interval <- function(id, start, end) {
    DT <- as.data.table(list(id=id, start=start, end=end))
    setorder(DT, id, start)
    DT <- DT[,c(".parent_start", ".parent_end", ".interval_number") := .calculate_parent(start, end), keyby = id]
    DT[]
}

.calculate_parent <- function(start, end) {
    .Call("calculate_parent", start, end)
}
