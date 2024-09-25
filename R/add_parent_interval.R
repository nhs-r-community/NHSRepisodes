# -------------------------------------------------------------------------
#' Calculate parent intervals
#'
# -------------------------------------------------------------------------
#' `add_parent_interval()` calculates the minimum spanning interval that
#' contains overlapping episodes and adds this to the input.
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
#' For the data frame methods. a variable in `x` representing the id associated
#' with an episode.
#'
#' @param start `[character]`.
#'
#' For the default method, vector representing episode start date/time.
#'
#' For the data frame method, a variable in `x` representing the episode start.
#'
#' Variable must be a `<Date>` or `<POSIXct>` object.
#'
#' @param end `[character]`
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
#' @param name_parent_start
#'
#' The column name to use for the start of the parent interval in the output.
#'
#' @param name_parent_end
#'
#' The column name to use for the end of the parent interval in the output.
#'
#' @param name_interval_number
#'
#' The column name to use for the interval number within the matched parent
#' interval in the output.
#'
# -------------------------------------------------------------------------
#' @return
#' The input data with additional columns for the corresponding parent interval
#' (split across the `id` values).
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
#' with(dat, add_parent_interval(id, start, end))
#' add_parent_interval(dat, id = "id", start = "start", end = "end")
#'
# -------------------------------------------------------------------------
#' @export
add_parent_interval <- function(...) {
    UseMethod("add_parent_interval")
}

# -------------------------------------------------------------------------
#' @rdname add_parent_interval
#' @importFrom cli cli_abort
#' @importFrom rlang check_dots_empty0
#' @importFrom ympes assert_scalar_character_not_na
#' @importFrom data.table data.table setnames setDF
#' @importFrom tibble as_tibble
#' @export
add_parent_interval.default <- function(
    id,
    start,
    end,
    ...,
    name_id = "id",
    name_parent_start = "parent_start",
    name_parent_end = "parent_end",
    name_interval_number = "per_id_interval_number"
) {

    check_dots_empty0(...)

    # check the output names
    assert_scalar_character_not_na(name_id)
    assert_scalar_character_not_na(name_parent_start)
    assert_scalar_character_not_na(name_parent_end)
    assert_scalar_character_not_na(name_interval_number)

    names <- c(name_id, name_parent_start, name_parent_end, name_interval_number)

    if (dup <- anyDuplicated(names)) {
        duplicate <- names[dup]
        cli_abort("Output names must be unique. {.str {duplicate}} is used multiple times.")
    }

    # check start and end are of a valid and identical class
    identical <- identical(class(start), class(end))
    valid <- inherits(start, "Date") || inherits(start, "POSIXct")
    if (!(identical && valid)) {
        cli_abort("{.arg start} and {.arg end} columns must both be either {.cls Date} or {.cls POSIXct}.")
    }

    # C API NOTE: .calculate_parent is expecting start/end to be REAL so we
    #             ensure this is the case.
    storage.mode(start) <- "double"
    storage.mode(end) <- "double"

    # check lengths are compatible
    if (length(id) != length(start) || length(id) != length(end)) {
        cli_abort("{.arg id}, {.arg start} and {.arg end} must be the same length.")
    }

    # C API NOTE: .calculate_parent requires us to be ordered by start date
    #             to work! The key argument here ensures this is the case
    #             (allowing for id as we will group by this).
    DT <- data.table(id, start, end, position = seq_along(id), key = c("id", "start"))

    # pull out the position argument so we can return original ordering
    position <- order(DT$position)

    # calculate the parent interval
    DT <- DT[, .calculate_parent(start, end), keyby = id]

    # return original ordering
    DT <- DT[position]

    # Add the desired column names
    setnames(DT, names)

    # Return as tibble
    as_tibble(setDF(DT))
}

# -------------------------------------------------------------------------
#' @rdname add_parent_interval
#' @importFrom cli cli_abort
#' @importFrom rlang check_dots_empty0
#' @importFrom vctrs vec_group_id
#' @importFrom ympes assert_scalar_character_not_na assert_character
#' @export
add_parent_interval.data.frame <- function(
    x,
    id,
    start,
    end,
    ...,
    name_parent_start = "parent_start",
    name_parent_end = "parent_end",
    name_interval_number = "per_id_interval_number"
) {

    check_dots_empty0(...)

    # check the input names
    assert_scalar_character_not_na(id)
    assert_scalar_character_not_na(start)
    assert_scalar_character_not_na(end)

    # check the output names
    assert_scalar_character_not_na(name_parent_start)
    assert_scalar_character_not_na(name_parent_end)
    assert_scalar_character_not_na(name_interval_number)

    output_names <- c(name_parent_start, name_parent_end, name_interval_number)

    if (dup <- anyDuplicated(output_names)) {
        duplicate <- output_names[dup]
        cli_abort("Output names must be unique. {.str {duplicate}} is used multiple times.")
    }

    # check input data.frame does not use output names
    x_names <- names(x)
    matches <- output_names[output_names %in% x_names]
    if (length(matches)) {
        match <- matches[1L]
        cli_abort(
            "The name {.str {match}} clashes with one of the column names in {.arg x}.
             Please choose a different name."
        )
    }

    # check that input names are present
    input_names <- c(id, start, end)
    matches <- input_names[!input_names %in% x_names]
    if (length(matches)) {
        match <- matches[1L]
        cli_abort(
            "Not all inputs are present in {.arg x}.
            No column named {.str {match}} can be found."
        )
    }

    # pull out the relevant variables
    id <- x[[id]]
    start <- x[[start]]
    end <- x[[end]]

    # calculate the parent intervals
    # TODO - this could be more efficient as we duplicate some checks
    dat <- add_parent_interval.default(
        id = id,
        start = start,
        end = end,
        name_id = "id",
        name_parent_start = name_parent_start,
        name_parent_end = name_parent_end,
        name_interval_number = name_interval_number
    )

    # drop the id column and combine with the input
    dat$id <- NULL
    cbind(x, dat)
}

# -------------------------------------------------------------------------
#' @rdname add_parent_interval
#' @importFrom data.table setDT
#' @export
add_parent_interval.data.table <- function(
    x,
    id,
    start,
    end,
    ...,
    name_parent_start = "parent_start",
    name_parent_end = "parent_end",
    name_interval_number = "per_id_interval_number"
) {
    x <- as.data.frame(x)
    out <- NextMethod()
    setDT(out)[]
}

# -------------------------------------------------------------------------
#' @rdname add_parent_interval
#' @importFrom tibble as_tibble
#' @export
add_parent_interval.tbl_df <- function(
    x,
    id,
    start,
    end,
    ...,
    name_parent_start = "parent_start",
    name_parent_end = "parent_end",
    name_interval_number = "per_id_interval_number"
) {
    out <- NextMethod()
    as_tibble(out)
}

# ------------------------------------------------------------------------- #
# ------------------------------------------------------------------------- #
# -------------------------------- INTERNALS ------------------------------ #
# ------------------------------------------------------------------------- #
# ------------------------------------------------------------------------- #
.calculate_parent <- function(start, end) {
    .Call("calculate_parent", start, end)
}
