# source("helpers.R")
#
#
#
# # # WIP: weighted data, get average predictions using a `comparisons()` hack
#
# library(survey)
# data(nhanes)
# nhanes$RIAGENDR <- factor(nhanes$RIAGENDR, labels = c("male", "female"))
# #
# svydsgn <- svydesign(
#     id = ~SDMVPSU, strata = ~SDMVSTRA, weights = ~WTMEC2YR,
#     nest = TRUE, data = nhanes)
# mod <- suppressWarnings(svyglm(
#     HI_CHOL ~ RIAGENDR + agecat, design = svydsgn, family = binomial))
# #
# nd <- insight::get_data(svymod)
# nd$wts <- svymod$prior.weights
# cmp <- comparisons(
#     mod,
#     type = "link",
#     weights = "wts",
#     transform_pre = function(hi, lo) hi,
#     newdata = nd,
#     variables = "RIAGENDR")
#
# On the link-scale, the predictions jacobian == model.matrix
# Interesting because it allows us to get fast standard errors

# J <- attr(cmp, "J")
# M <- insight::get_modelmatrix(mod)
# V <- attr(cmp, "vcov")
# sqrt(colSums(t(J %*% V) * t(J))) |> head()
# sqrt(colSums(t(M %*% V) * t(M))) |> head()


source("helpers.R")
requiet("survey")

# mtcars logit
dat <- mtcars
dat$weights <- dat$w <- 1:32
mod <- suppressWarnings(svyglm(
    am ~ mpg,
    design = svydesign(ids = ~1, weights = ~weights, data = dat),
    family = binomial))
p1 <- predictions(mod, newdata = dat)
p2 <- predictions(mod, weights = "weights", newdata = dat)
p3 <- predictions(mod, weights = "w", newdata = dat)
p4 <- predictions(mod, weights = dat$weights)
expect_false(tidy(p1)$estimate == tidy(p2)$estimate)
expect_false(tidy(p1)$std.error == tidy(p2)$std.error)
expect_equal(tidy(p2), tidy(p3))
expect_equal(tidy(p2), tidy(p4))

# sanity check
expect_error(comparisons(mod, weights = "junk"), pattern = "explicitly")
expect_error(marginaleffects(mod, weights = "junk"), pattern = "explicitly")

# vs. Stata (not clear what SE they use, so we give tolerance)
stata <- c("estimate" = .0441066, "std.error" = .0061046)
mfx <- marginaleffects(mod, weights = mod$prior.weights)
mfx <- tidy(mfx)
mfx <- unlist(mfx[, 3:4])
expect_equivalent(mfx, stata, tolerance = 0.0002)

# . logit am mpg [pw=weights]
#
# Iteration 0:   log pseudolikelihood = -365.96656  
# Iteration 1:   log pseudolikelihood = -255.02961  
# Iteration 2:   log pseudolikelihood = -253.55843  
# Iteration 3:   log pseudolikelihood = -253.55251  
# Iteration 4:   log pseudolikelihood = -253.55251  
#
# Logistic regression                                     Number of obs =     32
#                                                         Wald chi2(1)  =   8.75
#                                                         Prob > chi2   = 0.0031
# Log pseudolikelihood = -253.55251                       Pseudo R2     = 0.3072
#
# ------------------------------------------------------------------------------
#              |               Robust
#           am | Coefficient  std. err.      z    P>|z|     [95% conf. interval]
# -------------+----------------------------------------------------------------
#          mpg |   .2789194   .0943021     2.96   0.003     .0940908    .4637481
#        _cons |  -5.484059   2.066303    -2.65   0.008    -9.533938   -1.434179
# ------------------------------------------------------------------------------
#
# . margins, dydx(mpg)
#
# Average marginal effects                                    Number of obs = 32
# Model VCE: Robust
#
# Expression: Pr(am), predict()
# dy/dx wrt:  mpg
#
# ------------------------------------------------------------------------------
#              |            Delta-method
#              |      dy/dx   std. err.      z    P>|z|     [95% conf. interval]
# -------------+----------------------------------------------------------------
#          mpg |   .0441066   .0061046     7.23   0.000     .0321419    .0560714
# ------------------------------------------------------------------------------
