warn_once <- function(msg, id) {
    msg <- paste(msg, "This warning appears once per session.")
    if (isTRUE(getOption(id, default = TRUE))) {
        warning(msg, call. = FALSE)
        opts <- list(FALSE)
        names(opts) <- id
        options(opts)
    }
}
