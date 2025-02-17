% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/tidy.R
\name{tidy.marginaleffects}
\alias{tidy.marginaleffects}
\title{Tidy a \code{marginaleffects} object}
\usage{
\method{tidy}{marginaleffects}(x, conf_level = 0.95, by = NULL, ...)
}
\arguments{
\item{x}{An object produced by the \code{marginaleffects} function.}

\item{conf_level}{numeric value between 0 and 1. Confidence level to use to build a confidence interval.}

\item{by}{Character vector of variable names over which to compute group-averaged marginal effects.}

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
A "tidy" \code{data.frame} of summary statistics which conforms to the
\code{broom} package specification.
}
\description{
Tidy a \code{marginaleffects} object
}
\details{
The \code{tidy} function calculates average marginal effects by taking the mean
of all the unit-level marginal effects computed by the \code{marginaleffects}
function.

The standard error of the average marginal effects is obtained by
taking the mean of each column of the Jacobian. . Then, we use this
"Jacobian at the mean" in the Delta method to obtained standard errors.

In Bayesian models (e.g., \code{brms}), we compute Average Marginal
Effects by applying the mean function twice. First, we apply it to all
marginal effects for each posterior draw, thereby estimating one Average (or
Median) Marginal Effect per iteration of the MCMC chain. Second, we take
the \code{mean} and \code{quantile} function to the results of Step 1 to obtain the
Average (or Median) Marginal Effect and its associated interval.
}
\examples{
mod <- lm(mpg ~ hp * wt + factor(gear), data = mtcars)
mfx <- marginaleffects(mod)

# average marginal effects
tidy(mfx)

# average marginal effects by group
tidy(mfx, by = "gear")
}
