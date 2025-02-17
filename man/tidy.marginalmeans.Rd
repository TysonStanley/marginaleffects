% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/tidy.R
\name{tidy.marginalmeans}
\alias{tidy.marginalmeans}
\title{Tidy a \code{marginalmeans} object}
\usage{
\method{tidy}{marginalmeans}(x, conf_level = 0.95, ...)
}
\arguments{
\item{x}{An object produced by the \code{marginalmeans} function.}

\item{conf_level}{numeric value between 0 and 1. Confidence level to use to build a confidence interval.}

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
Tidy a \code{marginalmeans} object
}
