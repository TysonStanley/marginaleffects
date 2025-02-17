% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/predictions.R
\name{predictions}
\alias{predictions}
\title{Adjusted Predictions}
\usage{
predictions(
  model,
  newdata = NULL,
  variables = NULL,
  vcov = TRUE,
  conf_level = 0.95,
  type = "response",
  weights = NULL,
  transform_post = NULL,
  ...
)
}
\arguments{
\item{model}{Model object}

\item{newdata}{A data frame over which to compute quantities of interest.
\itemize{
\item \code{NULL}: adjusted predictions for each observed value in the original dataset.
\item The \code{\link[=datagrid]{datagrid()}} function can be used to specify a custom grid of regressors. For example:
\itemize{
\item \code{newdata = datagrid()}: contrast at the mean
\item \code{newdata = datagrid(cyl = c(4, 6))}: \code{cyl} variable equal to 4 and 6 and other regressors fixed at their means or modes.
\item See the Examples section and the \code{\link[=datagrid]{datagrid()}} documentation for more.
}
}}

\item{variables}{Character vector. Compute Adjusted Predictions for
combinations of each of these variables. Factor levels are considered at
each of their levels. Numeric variables variables are considered at Tukey's
Five-Number Summaries. \code{NULL} uses the original data used to fit the model.}

\item{vcov}{Type of uncertainty estimates to report (e.g., for robust standard errors). Acceptable values:
\itemize{
\item FALSE: Do not compute standard errors. This can speed up computation considerably.
\item TRUE: Unit-level standard errors using the default \code{vcov(model)} variance-covariance matrix.
\item String which indicates the kind of uncertainty estimates to return.
\itemize{
\item Heteroskedasticity-consistent: \code{"HC"}, \code{"HC0"}, \code{"HC1"}, \code{"HC2"}, \code{"HC3"}, \code{"HC4"}, \code{"HC4m"}, \code{"HC5"}. See \code{?sandwich::vcovHC}
\item Heteroskedasticity and autocorrelation consistent: \code{"HAC"}
\item Other: \code{"NeweyWest"}, \code{"KernHAC"}, \code{"OPG"}. See the \code{sandwich} package documentation.
}
\item One-sided formula which indicates the name of cluster variables (e.g., \code{~unit_id}). This formula is passed to the \code{cluster} argument of the \code{sandwich::vcovCL} function.
\item Square covariance matrix
\item Function which returns a covariance matrix (e.g., \code{stats::vcov(model)})
}}

\item{conf_level}{numeric value between 0 and 1. Confidence level to use to build a confidence interval.}

\item{type}{string indicates the type (scale) of the predictions used to
compute marginal effects or contrasts. This can differ based on the model
type, but will typically be a string such as: "response", "link", "probs",
or "zero". When an unsupported string is entered, the model-specific list of
acceptable values is returned in an error message.}

\item{weights}{column name of the weights variable in \code{newdata}, or numeric vector of length equal to the number of rows in the original data or in \code{newdata} (if supplied).}

\item{transform_post}{(experimental) A function applied to unit-level adjusted predictions and confidence intervals just before the function returns results. For bayesian models, this function is applied to individual draws from the posterior distribution, before computing summaries.}

\item{...}{Additional arguments are passed to the \code{predict()} method
supplied by the modeling package.These arguments are particularly useful
for mixed-effects or bayesian models (see the online vignettes on the
\code{marginaleffects} website). Available arguments can vary from model to
model, depending on the range of supported arguments by each modeling
package. See the "Model-Specific Arguments" section of the
\code{?marginaleffects} documentation for a non-exhaustive list of available
arguments.}
}
\value{
A \code{data.frame} with one row per observation and several columns:
\itemize{
\item \code{rowid}: row number of the \code{newdata} data frame
\item \code{type}: prediction type, as defined by the \code{type} argument
\item \code{group}: (optional) value of the grouped outcome (e.g., categorical outcome models)
\item \code{predicted}: predicted outcome
\item \code{std.error}: standard errors computed by the \code{insight::get_predicted} function or, if unavailable, via \code{marginaleffects} delta method functionality.
\item \code{conf.low}: lower bound of the confidence interval (or equal-tailed interval for bayesian models)
\item \code{conf.high}: upper bound of the confidence interval (or equal-tailed interval for bayesian models)
}
}
\description{
Calculate adjusted predictions for each row of the dataset. The \code{datagrid()}
function and the \code{newdata} argument can be used to calculate Average
Adjusted Predictions (AAP), Average Predictions at the Mean (APM), or
Predictions at User-Specified Values of the regressors (aka Adjusted
Predictions at Representative values, APR). For more information, see the
Details and Examples sections below, and in the vignettes on the
\code{marginaleffects} website: \url{https://vincentarelbundock.github.io/marginaleffects/}
\itemize{
\item \href{https://vincentarelbundock.github.io/marginaleffects/#getting-started}{Getting Started}
\item \href{https://vincentarelbundock.github.io/marginaleffects/articles/mfx01_predictions.html}{Predictions Vignette}
\item \href{https://vincentarelbundock.github.io/marginaleffects/articles/mfx06_supported_models.html}{Supported Models}
}
}
\details{
An "adjusted prediction" is the outcome predicted by a model for some
combination of the regressors' values, such as their observed values, their
means, or factor levels (a.k.a. “reference grid”).
When possible, this function uses the delta method to compute the standard
error associated with the adjusted predictions.

A detailed vignette on adjusted predictions is published on the package
website:

https://vincentarelbundock.github.io/marginaleffects/
Compute model-adjusted predictions (fitted values) for a "grid" of regressor values.
}
\section{Model-Specific Arguments}{


Some model types allow model-specific arguments to modify the nature of
marginal effects, predictions, marginal means, and contrasts.\tabular{llll}{
   Package \tab Class \tab Argument \tab Documentation \cr
   \code{brms} \tab \code{brmsfit} \tab \code{ndraws} \tab \link[brms:posterior_predict.brmsfit]{brms::posterior_predict} \cr
    \tab  \tab \code{re_formula} \tab  \cr
   \code{lme4} \tab \code{merMod} \tab \code{include_random} \tab \link[insight:get_predicted]{insight::get_predicted} \cr
    \tab  \tab \code{re.form} \tab \link[lme4:predict.merMod]{lme4::predict.merMod} \cr
    \tab  \tab \code{allow.new.levels} \tab \link[lme4:predict.merMod]{lme4::predict.merMod} \cr
   \code{glmmTMB} \tab \code{glmmTMB} \tab \code{re.form} \tab \link[glmmTMB:predict.glmmTMB]{glmmTMB::predict.glmmTMB} \cr
    \tab  \tab \code{allow.new.levels} \tab \link[glmmTMB:predict.glmmTMB]{glmmTMB::predict.glmmTMB} \cr
    \tab  \tab \code{zitype} \tab \link[glmmTMB:predict.glmmTMB]{glmmTMB::predict.glmmTMB} \cr
   \code{mgcv} \tab \code{bam} \tab \code{exclude} \tab \link[mgcv:predict.bam]{mgcv::predict.bam} \cr
   \code{robustlmm} \tab \code{rlmerMod} \tab \code{re.form} \tab \link[robustlmm:rlmerMod-class]{robustlmm::predict.rlmerMod} \cr
    \tab  \tab \code{allow.new.levels} \tab \link[robustlmm:rlmerMod-class]{robustlmm::predict.rlmerMod} \cr
}
}

\examples{
# Adjusted Prediction for every row of the original dataset
mod <- lm(mpg ~ hp + factor(cyl), data = mtcars)
pred <- predictions(mod)
head(pred)

# Adjusted Predictions at User-Specified Values of the Regressors
predictions(mod, newdata = datagrid(hp = c(100, 120), cyl = 4))

# Average Adjusted Predictions (AAP)
library(dplyr)
mod <- lm(mpg ~ hp * am * vs, mtcars)

pred <- predictions(mod, newdata = datagrid(am = 0, grid_type = "counterfactual")) \%>\%
    summarize(across(c(predicted, std.error), mean))

predictions(mod, newdata = datagrid(am = 0:1, grid_type = "counterfactual")) \%>\% 
    group_by(am) \%>\%
    summarize(across(c(predicted, std.error), mean))

# Conditional Adjusted Predictions
plot_cap(mod, condition = "hp")
}
