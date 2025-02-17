ON_CRAN <- !identical(Sys.getenv("R_NOT_CRAN"), "true")
ON_GH <- identical(Sys.getenv("R_GH"), "true")
ON_CI <- isTRUE(ON_CRAN) || isTRUE(ON_GH)

minver <- function(pkg, ver = NULL) {
    ins <- try(utils::packageVersion(pkg), silent = TRUE)
    if (is.null(ver)) {
        isTRUE(inherits(ins, "try-error"))
    } else {
        isTRUE(ins < ver)
    }
}

# requiet adapted from testthat::skip_if_not_installed (MIT license)
requiet <- function(package, minimum_version = NULL) {
    suppressPackageStartupMessages(
        require(package, warn.conflicts = FALSE, character.only = TRUE)
    )
}


testing_path <- function(x) {
    wd <- tinytest::get_call_wd()
    if (isTRUE(wd != "")) {
        out <- x
    } else {
        out <- paste0(wd, "/", x)
    }
    out <- gsub("^\\/", "", out)
    return(out)
}


download_model <- function(name) {
    tmp <- tempfile()
    url <- paste0("https://raw.github.com/vincentarelbundock/modelarchive/main/data/", name, ".rds")
    try(utils::download.file(url, tmp, quiet = TRUE), silent = TRUE)
    out <- try(readRDS(tmp), silent = TRUE)
    return(out)
}


expect_print <- function(unknown, known) {
    known <- trimws(unlist(strsplit(known, split = "\\n")))
    unknown <- trimws(capture.output(unknown))
    expect_equivalent(known, unknown)
}


check_predictions <- function(object,
                              se = TRUE,
                              n_col = NULL,
                              n_row = NULL) {
    flag <- inherits(object, "predictions") &&
            "type" %in% colnames(predictions) &&
            "predicted" %in% colnames(predictions)
    if (isTRUE(se) && !"std.error" %in% colnames(object)) {
        flag <- FALSE
    }
    if (!is.null(n_col) && ncol(object) >= n_col) {
        flag <- FALSE
    }
    if (!is.null(n_row) && nrow(object) >= n_row) {
        flag <- FALSE
    }
    return(flag)
}

expect_predictions <- function(object,
                               se = TRUE,
                               n_col = NULL,
                               n_row = NULL) {
    expect_inherits(object, "predictions")
    expect_true("type" %in% colnames(object))
    expect_true("predicted" %in% colnames(object))
    if (isTRUE(se)) tinytest::expect_true("std.error" %in% colnames(object))
    if (!is.null(n_col)) tinytest::expect_true(ncol(object) >= n_col)
    if (!is.null(n_row)) tinytest::expect_true(nrow(object) >= n_row)
}


expect_marginaleffects <- function(
    object,
    type = "response",
    n_unique = 10,
    pct_na = 5,
    se = TRUE,
    ...) {

    # Compute
    mfx <- marginaleffects(object, type = type, ...)
    tid <- tidy(mfx)

    # Check
    mfx_class <- class(mfx)[1]
    tid_class <- class(tid)[1]
    mfx_nrow <- nrow(mfx)
    tid_nrow <- nrow(tid)
    dydx_unique <- length(unique(round(mfx$dydx, 4))) /
                   length(unique(mfx$term))
    dydx_na <- sum(is.na(mfx$dydx)) / nrow(mfx) * 100
    if (isTRUE(se)) {
        std.error_unique <- length(unique(round(mfx$std.error, 4))) /
                            length(unique(mfx$term))
        std.error_na <- sum(is.na(mfx$std.error_na)) / nrow(mfx) * 100
    } else {
        std.error_unique <- NULL
        std.error_na <- NULL
    }

    tinytest::expect_inherits(mfx, "marginaleffects")
    tinytest::expect_inherits(tid, "data.frame")
    tinytest::expect_true(nrow(mfx) > 0)
    tinytest::expect_true(nrow(tid) > 0)
    tinytest::expect_true(dydx_unique >= n_unique)
    tinytest::expect_true(dydx_na <= pct_na)
    if (!is.null(std.error_na)) {
        tinytest::expect_true(std.error_unique >= n_unique)
        tinytest::expect_true(std.error_na <= pct_na)
    }
}


expect_marginalmeans <- function(object,
                                 se = TRUE,
                                 n_col = NULL,
                                 n_row = NULL) {
    tinytest::expect_inherits(object, "marginalmeans")
    tinytest::expect_true(nrow(object) >= n_row)
    tinytest::expect_true(ncol(object) >= n_col)
    if (isTRUE(se)) tinytest::expect_true("std.error" %in% colnames(object))
}


expect_margins <- function(results,
                           margins_object,
                           se = TRUE,
                           tolerance = 1e-5,
                           verbose = FALSE) {

    is_equal <- function(x, y) {
        all(abs((x - y) / x) < tolerance)
    }

    results$type <- NULL

    margins_object <- data.frame(margins_object)
    term_names <- unique(results$term)

    flag <- TRUE

    # dydx
    for (tn in term_names) {
        unknown <- results[results$term == tn, "dydx"]
        lab <- paste0("dydx_", tn)
        if (lab %in% colnames(margins_object)) {
            known <- as.numeric(margins_object[, lab])
            tmp <- is_equal(known, unknown)
            if (isFALSE(tmp)) {
                flag <- FALSE
                if (isTRUE(verbose)) print(sprintf("dydx: %s", tn))
            }
        }
    }

    # std.error
    if (isTRUE(se) && "std.error" %in% colnames(results)) {
        for (tn in term_names) {
            lab_se <- paste0("SE_dydx_", tn)
            lab_var <- paste0("Var_dydx_", tn)
            if (lab_se %in% colnames(margins_object)) {
                unknown <- results[results$term == tn, "std.error"]
                known <- as.numeric(margins_object[, lab_se])
                tmp <- is_equal(known, unknown)
                if (isFALSE(tmp)) {
                    flag <- FALSE
                    if (isTRUE(verbose)) print(sprintf("se: %s", tn))
                }
            } else if (lab_var %in% colnames(margins_object)) {
                unknown <- results[results$term == tn, "std.error"]
                known <- sqrt(as.numeric(margins_object[, lab_var]))
                tmp <- is_equal(known, unknown)
                if (isFALSE(tmp)) {
                    flag <- FALSE
                    if (isTRUE(verbose)) print(sprintf("Var: %s", tn))
                }
            } else {
                flag <- FALSE
                if (isTRUE(verbose)) print(sprintf("missing column: %s", lab))
            }
        }
    }

    tinytest::expect_true(flag)
}

