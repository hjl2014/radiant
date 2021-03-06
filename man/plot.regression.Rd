% Generated by roxygen2 (4.1.1): do not edit by hand
% Please edit documentation in R/regression.R
\name{plot.regression}
\alias{plot.regression}
\title{Plot method for the regression function}
\usage{
\method{plot}{regression}(x, plots = "", lines = "", conf_lev = 0.95,
  intercept = FALSE, shiny = FALSE, ...)
}
\arguments{
\item{x}{Return value from \code{\link{regression}}}

\item{plots}{Regression plots to produce for the specified regression model. Enter "" to avoid showing any plots (default). "hist" to show histograms of all variables in the model. "correlations" for a visual representation of the correlation matrix selected variables. "scatter" to show scatter plots (or box plots for factors) for the dependent variables with each independent variable. "dashboard" for a series of six plots that can be used to evaluate model fit visually. "resid_pred" to plot the independent variables against the model residuals. "coef" for a coefficient plot with adjustable confidence intervals. "leverage" to show leverage plots for each independent variable}

\item{lines}{Optional lines to include in the select plot. "line" to include a line through a scatter plot. "loess" to include a polynomial regression fit line. To include both use c("line","loess")}

\item{conf_lev}{Confidence level used to estimate confidence intervals (.95 is the default)}

\item{intercept}{Include the intercept in the coefficient plot (TRUE, FALSE). FALSE is the default}

\item{shiny}{Did the function call originate inside a shiny app}

\item{...}{further arguments passed to or from other methods}
}
\description{
Plot method for the regression function
}
\details{
See \url{http://vnijs.github.io/radiant/quant/regression.html} for an example in Radiant
}
\examples{
result <- regression("diamonds", "price", c("carat","clarity"))
plot(result, plots = "dashboard")
plot(result, plots = "dashboard", lines = c("line","loess"))
plot(result, plots = "coef", intercept = TRUE)
plot(result, plots = "coef", conf_lev = .99, intercept = TRUE)
plot(result, plots = "hist")
plot(result, plots = "scatter", lines = c("line","loess"))
plot(result, plots = "correlations")
plot(result, plots = "leverage")
plot(result, plots = "resid_pred", lines = "line")
}
\seealso{
\code{\link{regression}} to generate the results

\code{\link{summary.regression}} to summarize results

\code{\link{predict.regression}} to generate predictions
}

