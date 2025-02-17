source("helpers.R", local = TRUE)
if (ON_CRAN) exit_file("on cran")
requiet("estimatr")
requiet("emmeans")
requiet("margins")
requiet("broom")
requiet("ivreg") # Kmenta data

# lm_lin: no validity
dat <- mtcars
dat$cyl <- factor(dat$cyl)
mod <- lm_lin(mpg ~ am, ~ hp + cyl, data = mtcars)
expect_marginaleffects(mod, n_unique = 9)



# iv_robust vs. stata
data(Kmenta, package = "ivreg")
model <- iv_robust(Q ~ P + D | D + F + A, 
               se_type = "stata",
               data = Kmenta)
stata <- readRDS(testing_path("stata/stata.rds"))$estimatr_iv_robust
mfx <- tidy(marginaleffects(model))
mfx <- merge(mfx, stata)
expect_equivalent(mfx$dydx, mfx$dydxstata)
expect_equivalent(mfx$std.error, mfx$std.errorstata, tolerance = .1)



# lm_robust vs. stata vs. emtrends
model <- lm_robust(carb ~ wt + factor(cyl),
               se_type = "HC2",
               data = mtcars)
stata <- readRDS(testing_path("stata/stata.rds"))$estimatr_lm_robust
mfx <- tidy(marginaleffects(model))
mfx$term <- ifelse(mfx$contrast == "6 - 4", "6.cyl", mfx$term)
mfx$term <- ifelse(mfx$contrast == "8 - 4", "8.cyl", mfx$term)
mfx <- merge(mfx, stata)
expect_equivalent(mfx$dydx, mfx$dydxstata)
expect_equivalent(mfx$std.error, mfx$std.errorstata)
# emtrends
mfx <- marginaleffects(model, newdata = datagrid(cyl = 4, wt = 2), variables = "wt")
em <- emtrends(model, ~wt, "wt", at = list(cyl = 4, wt = 2))
em <- tidy(em)
expect_equivalent(mfx$dydx, em$wt.trend, tolerance = .001)
expect_equivalent(mfx$std.error, em$std.error, tolerance = .001)
# margins does not support standard errors
tmp <- mtcars
tmp$cyl <- factor(tmp$cyl)
mod <- lm_robust(carb ~ wt + cyl, data = tmp, se_type = "stata")
mar <- margins(mod, data = head(tmp))
mfx <- marginaleffects(mod, newdata = head(tmp))
expect_true(expect_margins(mfx, mar, se = FALSE))


# iv_robust: predictions: no validity
#skip_if_not_installed("insight", minimum_version = "0.17.1")
data(Kmenta, package = "ivreg")
model <- iv_robust(Q ~ P + D | D + F + A, 
               se_type = "stata",
               data = Kmenta)
expect_predictions(predictions(model), n_row = nrow(Kmenta))
expect_predictions(predictions(model, newdata = head(Kmenta)), n_row = 6)


# lm_robust: marginalmeans predictions: no validity
#skip_if_not_installed("insight", minimum_version = "0.17.1")
tmp <- mtcars
tmp$cyl <- as.factor(tmp$cyl)
tmp$am <- as.logical(tmp$am)
model <- lm_robust(carb ~ wt + am + cyl,
               se_type = "stata",
               data = tmp)
expect_predictions(predictions(model), n_row = nrow(tmp))
expect_predictions(predictions(model, newdata = head(tmp)), n_row = 6)
expect_marginalmeans(marginalmeans(model))

