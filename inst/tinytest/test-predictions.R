source("helpers.R", local = TRUE)
exit_file("TODO: works interactively")
if (ON_CRAN) exit_file("on cran")
requiet("pscl")

tmp <- mtcars
tmp$am <- as.logical(tmp$am)
mod <- lm(mpg ~ hp + wt + factor(cyl) + am, data = tmp)


# bugfix: counterfactual predictions keep rowid
mod <- lm(mpg ~ hp + am, mtcars)
pred <- predictions(mod, newdata = datagrid(am = 0:1, grid.type = "counterfactual"))
expect_predictions(pred, n_row = 64)
expect_true("rowid_counterfactual" %in% colnames(pred))


################
#  conf.level  #
################

# conf.level argument changes width of interval
for (L in c(.4, .7, .9, .95, .99, .999)) {
    nd <- datagrid(model = mod)
    unknown <- predictions(mod, newdata = nd, conf.level = L)
    known <- predict(mod, newdata = nd, se.fit = TRUE, interval = "confidence", level = L)$fit
    expect_equivalent(unknown$conf.low, known[, "lwr"])
    expect_equivalent(unknown$conf.high, known[, "upr"])
}


#################################
#  average adjusted predictions #
#################################
dat <- mtcars
dat$w <- 1:32
mod <- lm(mpg ~ hp + am, dat)
pre <- predictions(mod)
tid1 <- tidy(pre)
tid2 <- tidy(pre, by = "am")
expect_equal(nrow(tid1), 1)
expect_equal(nrow(tid2), 2)


#########################################
#  weigted average adjusted predictions #
#########################################
pre <- predictions(mod, weights = "w", newdata = dat)
tid3 <- tidy(pre)
tid4 <- tidy(pre, by = "am")
expect_equal(nrow(tid3), 1)
expect_equal(nrow(tid4), 2)
expect_true(all(tid1$estimate != tid3$estimate))
expect_true(all(tid2$estimate != tid4$estimate))


######################################
#  values against predict benchmark  #
######################################
mod <- lm(mpg ~ hp + wt + factor(cyl) + am, data = tmp)
nd <- datagrid(model = mod, cyl = c(4, 6, 8))
mm <- predictions(mod, newdata = nd)
expect_equivalent(mm$predicted, unname(predict(mod, newdata = nd)))


##############################
#  size: variables argument  #
##############################

# `variables` arg: factor
mm <- predictions(mod, variables = "cyl")
expect_equivalent(nrow(mm), 3)


# `variables` arg: logical
mm <- predictions(mod, variables = "am")
expect_equivalent(nrow(mm), 2)


# `variables` arg: numeric
mm <- predictions(mod, variables = "wt")
expect_equivalent(nrow(mm), 5)


# `variables` arg: factor + logical
mm <- predictions(mod, variables = c("am", "cyl"))
# logical 2; cyl factor 3
expect_equivalent(nrow(mm), 2 * 3)



# `variables` arg: logical + numeric
mm <- predictions(mod, variables = c("am", "wt"))
# logical 2; numeric 5 numbers
expect_equivalent(nrow(mm), 2 * 5)


# `variables` arg: factor + numeric
mm <- predictions(mod, variables = c("cyl", "wt"))
# logical 2; numeric 5 numbers
expect_equivalent(nrow(mm), 3 * 5)



#############################
#  size: new data argument  #
#############################

# `newdata`: mtcars has 32 rows
mm <- predictions(mod, newdata = tmp)
expect_equivalent(nrow(mm), 32)


# `typical`: all factors
mm <- predictions(mod, newdata = datagrid(cyl = c(4, 6, 8)))
expect_equivalent(nrow(mm), 3)


# `typical`: two missing factors
mm <- predictions(mod, newdata = datagrid(cyl = 4))
expect_equivalent(nrow(mm), 1)


# `typical`: one missing factor
mm <- predictions(mod, newdata = datagrid(cyl = c(4, 6)))
expect_equivalent(nrow(mm), 2)


# `typical`: all logical
mm <- predictions(mod, newdata = datagrid(am = c(TRUE, FALSE)))
expect_equivalent(nrow(mm), 2)
expect_equivalent(length(unique(mm$predicted)), nrow(mm))


# `typical`: missing logical
mm <- predictions(mod, newdata = datagrid(am = TRUE))
expect_equivalent(nrow(mm), 1)


#########################################################################
#  some models do not return data.frame under `insight::get_predicted`  #
#########################################################################

# hurdle predictions
data("bioChemists", package = "pscl")
mod <- hurdle(art ~ phd + fem | ment, data = bioChemists, dist = "negbin")
pred <- predictions(mod)
expect_inherits(pred, "data.frame")
expect_true("predicted" %in% colnames(pred))




