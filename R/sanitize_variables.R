sanitize_variables <- function(model,
                               newdata,
                               variables,
                               contrast_numeric = 1,
                               contrast_factor = "reference") {
    checkmate::assert(
        checkmate::check_character(variables, min.len = 1, null.ok = TRUE),
        checkmate::check_list(variables, names = "unique"),
        combine = "or")
    checkmate::assert_data_frame(newdata, min.row = 1, null.ok = TRUE)

    if (!is.null(model) & is.null(newdata)) {
        origindata <- insight::get_data(model)
    } else {
        origindata <- newdata
    }

    if (is.null(newdata)) {
        newdata <- origindata
    }

    # variables is NULL: get all variables from model
    if (is.null(variables)) {
        variables_list <- insight::find_variables(model)
        variables_list[["response"]] <- NULL
        contrast_types <- NULL

    # variables is named list
    } else if (isTRUE(checkmate::check_list(variables, names = "unique"))) {
        for (n in names(variables)) {
            if (n %in% colnames(newdata)) {
                if (isTRUE(find_variable_class(n, newdata, model) == "numeric")) {
                    sanity_contrast_numeric(variables[[n]])
                }
                if (isTRUE(find_variable_class(n, newdata, model) %in% c("factor", "character"))) {
                    sanity_contrast_factor(variables[[n]])
                }
            }
        }
        contrast_types <- variables
        variables_list <- list("conditional" = names(variables))

    # variables is vector
    } else {
        variables_list <- list("conditional" = variables)
        contrast_types <- NULL
    }

    variables <- unique(unlist(variables_list))

    # mhurdle names the variables weirdly
    if (inherits(model, "mhurdle")) {
        variables_list <- list("conditional" = insight::find_predictors(model, flatten = TRUE))
    }

    # weights
    w <- tryCatch(insight::find_weights(model), error = function(e) NULL)
    w <- intersect(w, colnames(newdata))
    variables <- unique(c(variables, w))
    variables_list[["weights"]] <- w

    # check missing character levels
    # Character variables are treated as factors by model-fitting functions,
    # but unlike factors, they do not not keep a record of all factor levels.
    # This poses problem when feeding `newdata` to `predict`, which often
    # breaks (via `model.matrix`) when the data does not include all possible
    # factor levels.
    levels_character <- list()
    for (v in variables) {
        if (v %in% colnames(origindata) && is.character(origindata[[v]])) {
            levels_character[[v]] <- unique(origindata[[v]])
        }
    }
    attr(variables_list, "levels_character") <- levels_character
    attr(variables_list, "contrast_types") <- contrast_types

    # check missing variables
    miss <- setdiff(variables, colnames(newdata))
    if (length(miss) > 0) {
        stop(sprintf("Variables missing from `newdata` and/or the data extracted from the model objects: %s",
                     paste(miss, collapse = ", ")),
             call. = FALSE)
    }

    return(variables_list)
}



