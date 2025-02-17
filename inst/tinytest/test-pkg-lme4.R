source("helpers.R", local = TRUE)
if (ON_CRAN) exit_file("on cran")
requiet("margins")
requiet("haven")
requiet("lme4")
requiet("insight")
requiet("emmeans")
requiet("broom")


# satterthwaite (no validity)
#skip_if_not_installed("insight", minimum_version = "0.17.1")
dat <- mtcars
dat$cyl <- factor(dat$cyl)
mod <- lmer(mpg ~ hp + (1 | cyl), data = dat)
x <- predictions(mod)
y <- predictions(mod, vcov = "satterthwaite")
z <- predictions(mod, vcov = "kenward-roger")
expect_true(all(x$conf.low != y$conf.low))
expect_true(all(x$conf.low != z$conf.low))
expect_true(all(y$conf.low != z$conf.low))
# kenward-roger adjusts vcov but not satterthwaite
expect_true(all(x$std.error == y$std.error))
expect_true(all(x$std.error != z$std.error))
expect_true(all(y$std.error != z$std.error))

x <- plot_cap(mod, condition = "hp", draw = FALSE)
y <- plot_cap(mod, condition = "hp", vcov = "satterthwaite", draw = FALSE)
z <- plot_cap(mod, condition = "hp", vcov = "kenward-roger", draw = FALSE)
expect_true(all(x$conf.low != y$conf.low))
expect_true(all(x$conf.low != z$conf.low))
expect_true(all(y$conf.low != z$conf.low))
expect_true(all(x$std.error == y$std.error))
expect_true(all(x$std.error != z$std.error))
expect_true(all(y$std.error != z$std.error))

# comparisons
x <- comparisons(mod)
y <- comparisons(mod, vcov = "satterthwaite")
z <- comparisons(mod, vcov = "kenward-roger")
expect_true(all(x$conf.low != y$conf.low))
expect_true(all(x$conf.low != z$conf.low))
expect_true(all(y$conf.low != z$conf.low))
expect_true(all(x$std.error == y$std.error))
expect_true(all(x$std.error != z$std.error))
expect_true(all(y$std.error != z$std.error))

# at the mean (regression test)
mfx <- marginaleffects(
mod,
newdata = datagrid(),
vcov = "satterthwaite")
expect_inherits(mfx, "marginaleffects")

# GLM not supported
mod <- glmer(am ~ hp + (1 | cyl), family = binomial, data = dat)
expect_error(comparisons(mod, vcov = "satterthwaite"), pattern = "Satter")
expect_error(comparisons(mod, vcov = "kenward-roger"), pattern = "Satter")
expect_error(predictions(mod, vcov = "satterthwaite"), pattern = "Satter")
expect_error(predictions(mod, vcov = "kenward-roger"), pattern = "Satter")



# get_predict: low-level tests

dat <- haven::read_dta("stata/databases/lme4_02.dta")
dat <- haven::read_dta(testing_path("stata/databases/lme4_02.dta"))
mod <- lme4::glmer(y ~ x1 * x2 + (1 | clus), data = dat, family = binomial)

# incompatible arguments
expect_error(get_predict(mod, re.form = ~0, include_random = TRUE), pattern = "together")

# type = "link"
w <- predict(mod, type = "link")
x <- get_predict(mod, type = "link")
y <- get_predict(mod, type = "link", conf.level = .9)
z <- get_predicted(mod, predict = "link")
expect_equivalent(w, x$predicted)
expect_equivalent(w, y$predicted)
expect_equivalent(w, as.numeric(z))

# type = "response"
w <- predict(mod, type = "response")
x <- get_predict(mod, type = "response")
y <- get_predict(mod, type = "response", conf.level = .9)
z <- get_predicted(mod, predict = "expectation")
expect_equivalent(w, x$predicted)
expect_equivalent(w, y$predicted)
expect_equivalent(w, as.numeric(z))

# confidence intervals (weak test)
w <- get_predict(mod, conf.level = .95)
x <- get_predict(mod, conf.level = .90)
expect_true(all(w$conf.low < x$conf.low))
expect_true(all(w$conf.high > x$conf.high))

# no random effects: grand mean
w <- predict(mod, re.form = NA, type = "response")
x <- get_predict(mod, re.form = NA, type = "response")
y <- get_predict(mod, include_random = FALSE, type = "response")
expect_equivalent(w, x$predicted)
expect_equivalent(w, y$predicted)

# grand mean with new data
nd <- datagrid(model = mod, clus = NA, x1 = -1:1)
w <- predict(mod, newdata = nd, re.form = NA, type = "response")
x <- get_predict(mod, newdata = nd, re.form = NA)
y <- predictions(mod, newdata = nd, re.form = NA, type = "response")
expect_equivalent(w, x$predicted)
expect_equivalent(w, y$predicted)



# glmer vs. stata vs. emtrends
dat <- haven::read_dta(testing_path("stata/databases/lme4_02.dta"))
mod <- lme4::glmer(y ~ x1 * x2 + (1 | clus), data = dat, family = binomial)
stata <- readRDS(testing_path("stata/stata.rds"))$lme4_glmer
mfx <- merge(tidy(marginaleffects(mod)), stata)
expect_marginaleffects(mod)
expect_equivalent(mfx$estimate, mfx$dydxstata, tolerance = .01)
expect_equivalent(mfx$std.error, mfx$std.errorstata, tolerance = .01)
# emtrends
mod <- glmer(y ~ x1 + x2 + (1 | clus), data = dat, family = binomial)
mfx <- marginaleffects(mod, variables = "x1", newdata = datagrid(x1 = 0, x2 = 0, clus = 1), type = "link")
em <- emtrends(mod, ~x1, "x1", at = list(x1 = 0, x2 = 0, clus = 1))
em <- tidy(em)
expect_equivalent(mfx$dydx, em$x1.trend)
expect_equivalent(mfx$std.error, em$std.error, tolerance = 1e-6)


# lmer vs. stata
dat <- haven::read_dta(testing_path("stata/databases/lme4_01.dta"))
mod <- lme4::lmer(y ~ x1 * x2 + (1 | clus), data = dat)
stata <- readRDS(testing_path("stata/stata.rds"))$lme4_lmer
mfx <- merge(tidy(marginaleffects(mod)), stata)
expect_marginaleffects(mod)
expect_equivalent(mfx$estimate, mfx$dydxstata, tolerance = .001)
expect_equivalent(mfx$std.error, mfx$std.errorstata, tolerance = .001)
# emtrends
mod <- lmer(y ~ x1 + x2 + (1 | clus), data = dat)
mfx <- marginaleffects(mod, variables = "x1",
                   newdata = datagrid(x1 = 0, x2 = 0, clus = 1))
em <- emtrends(mod, ~x1, "x1", at = list(x1 = 0, x2 = 0, clus = 1))
em <- tidy(em)
expect_equivalent(mfx$dydx, em$x1.trend)
expect_equivalent(mfx$std.error, em$std.error, tolerance = .001)


# vs. margins (dydx only)
dat <- haven::read_dta(testing_path("stata/databases/lme4_02.dta"))
mod <- lme4::glmer(y ~ x1 * x2 + (1 | clus), data = dat, family = binomial)
res <- marginaleffects(mod, vcov = FALSE)
mar <- margins::margins(mod)
expect_true(expect_margins(res, mar, tolerance = 1e-3))

dat <- haven::read_dta(testing_path("stata/databases/lme4_01.dta"))
mod <- lme4::lmer(y ~ x1 * x2 + (1 | clus), data = dat)
res <- marginaleffects(mod, vcov = FALSE)
mar <- margins::margins(mod)
expect_true(expect_margins(res, mar))


# sanity check on dpoMatrix
dat <- haven::read_dta(testing_path("stata/databases/lme4_02.dta"))
mod <- lme4::glmer(y ~ x1 * x2 + (1 | clus), data = dat, family = binomial)
k <- marginaleffects(mod, vcov = as.matrix(stats::vcov(mod)))
expect_inherits(k, "data.frame")


# bug stay dead: tidy without std.error
dat <- haven::read_dta(testing_path("stata/databases/lme4_02.dta"))
mod <- lme4::glmer(y ~ x1 * x2 + (1 | clus), data = dat, family = binomial)
res <- marginaleffects(mod, vcov = FALSE)
tid <- tidy(res)
expect_inherits(tid, "data.frame")
expect_equivalent(nrow(tid), 2)


# predictions: glmer: no validity
dat <- haven::read_dta(testing_path("stata/databases/lme4_02.dta"))
dat$clus <- as.factor(dat$clus)
model <- lme4::glmer(y ~ x1 * x2 + (1 | clus), data = dat, family = binomial)
pred1 <- predictions(model, newdata = datagrid())
pred2 <- predictions(model, newdata = head(dat))
expect_predictions(pred1, n_row = 1)
expect_predictions(pred2, n_row = 6)



# glmer.nb: marginaleffects vs. emtrends
set.seed(101)
dd <- expand.grid(f1 = factor(1:3), f2 = LETTERS[1:2], g = 1:9, rep = 1:15,
              KEEP.OUT.ATTRS = FALSE)
dd$x <- rnorm(nrow(dd))
mu <- 5 * (-4 + with(dd, as.integer(f1) + 4 * as.numeric(f2)))
dd$y <- rnbinom(nrow(dd), mu = mu, size = 0.5)
model <- suppressMessages(glmer.nb(y ~ f1 * f2 + (1 | g), data = dd, verbose = FALSE))
void <- capture.output(
expect_marginaleffects(model, n_unique = 2)
)

# emtrends
mod <- suppressMessages(glmer.nb(y ~ x + (1 | g), data = dd, verbose = FALSE))
mfx <- marginaleffects(mod, variables = "x", newdata = datagrid(g = 2), type = "link")
em <- emtrends(mod, ~x, "x", at = list(g = 2))
em <- tidy(em)
expect_equivalent(mfx$dydx, em$x.trend)
expect_equivalent(mfx$std.error, em$std.error, tolerance = 1e-6)

# margins
mar <- tidy(margins(mod))
mfx <- tidy(marginaleffects(mod))
expect_equivalent(mfx$estimate, mar$estimate, tolerance = .0001)
expect_equivalent(mfx$std.error, mar$std.error, tolerance = .0001)



# population-level
# Some contrasts are identical with include_random TRUE/FALSE because on Time has a random effect
mod <- suppressMessages(lmer(
  weight ~ 1 + Time + I(Time^2) + Diet + Time:Diet + I(Time^2):Diet + (1 + Time + I(Time^2) | Chick),
  data = ChickWeight))

mfx1 <- marginaleffects(
mod,
newdata = datagrid(Chick = NA,
                   Diet = 1:4,
                   Time = 0:21),
include_random = FALSE)
mfx2 <- marginaleffects(
mod,
newdata = datagrid(Chick = NA,
                   Diet = 1:4,
                   Time = 0:21),
re.form = NA)
mfx3 <- marginaleffects(
mod,
newdata = datagrid(Chick = "1",
                   Diet = 1:4,
                   Time = 0:21))
expect_inherits(mfx1, "marginaleffects")
expect_inherits(mfx2, "marginaleffects")
expect_inherits(mfx3, "marginaleffects")
expect_equivalent(mfx1$dydx, mfx2$dydx)
expect_equivalent(mfx1$std.error, mfx2$std.error)

pred1 <- predictions(
mod,
newdata = datagrid(Chick = NA,
                   Diet = 1:4,
                   Time = 0:21),
include_random = FALSE)
pred2 <- predictions(
mod,
newdata = datagrid(Chick = NA,
                   Diet = 1:4,
                   Time = 0:21),
re.form = NA)
pred3 <- predictions(
mod,
newdata = datagrid(Chick = "1",
                   Diet = 1:4,
                   Time = 0:21))
expect_inherits(pred1, "predictions")
expect_inherits(pred2, "predictions")
expect_inherits(pred3, "predictions")
expect_equivalent(pred1$dydx, pred2$dydx)
expect_equivalent(pred1$std.error, pred2$std.error)
expect_true(all(pred1$predicted != pred3$predicted))



# # 'group' cannot be a column name because of conflict with tidy output
#     set.seed(1024)
#     N <- 1000
#     tmp <- data.frame(x1 = rnorm(N),
#                       x2 = rnorm(N),
#                       y = sample(0:1, N, replace = TRUE),
#                       group = sample(letters[1:10], N, replace = TRUE))
#     mod <- lme4::glmer(y ~ x1 + x2 + (1 | group), data = tmp, family = binomial)
#     expect_error(marginaleffects(mod), pattern = "more descriptive")
# 
