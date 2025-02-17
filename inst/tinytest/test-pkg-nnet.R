source("helpers.R", local = TRUE)
if (ON_CRAN) exit_file("on cran")
requiet("nnet")

# warning: standard error mismatch
dat <- read.csv(testing_path("stata/databases/MASS_polr_01.csv"))
void <- capture.output(mod <- 
    nnet::multinom(factor(y) ~ x1 + x2, data = dat, quiet = true)
)
expect_warning(marginaleffects(mod, type = "probs"), pattern = "do not match")


# error: bad type
dat <- read.csv(testing_path("stata/databases/MASS_polr_01.csv"))
void <- capture.output(
    mod <- nnet::multinom(factor(y) ~ x1 + x2, data = dat, quiet = true)
)
expect_warning(expect_error(marginaleffects(mod), pattern = "must be an element"))


# multinom basic
dat <- read.csv(testing_path("stata/databases/MASS_polr_01.csv"))
void <- capture.output(
    mod <- nnet::multinom(factor(y) ~ x1 + x2, data = dat, quiet = true)
)
expect_warning(expect_marginaleffects(mod, type = "probs"))


# marginaleffects summary
dat <- read.csv(testing_path("stata/databases/MASS_polr_01.csv"))
void <- capture.output(
    mod <- nnet::multinom(factor(y) ~ x1 + x2, data = dat, quiet = true)
)
mfx <- suppressWarnings(marginaleffects(mod, type = "probs"))
s <- tidy(mfx)
expect_false(anyNA(s$estimate))
expect_false(anyNA(s$std.error))


# multinom vs. Stata
stata <- readRDS(testing_path("stata/stata.rds"))$nnet_multinom_01
dat <- read.csv(testing_path("stata/databases/MASS_polr_01.csv"))
dat$y <- as.factor(dat$y)
void <- capture.output(
    mod <- nnet::multinom(y ~ x1 + x2, data = dat, quiet = true)
)
mfx <- suppressWarnings(marginaleffects(mod, type = "probs"))
mfx <- merge(tidy(mfx), stata, all = TRUE)
mfx <- na.omit(mfx)
expect_true(nrow(mfx) == 6) # na.omit doesn't trash everything
# standard errors don't match
expect_equivalent(mfx$estimate, mfx$dydxstata, tolerance = .0001)
# expect_equivalent(mfx$std.error, mfx$std.errorstata, tolerance = .0001)


# set_coef
tmp <- mtcars
tmp$cyl <- as.factor(tmp$cyl)
void <- capture.output(
    old <- nnet::multinom(cyl ~ hp + am + mpg, data = tmp, quiet = true)
)
b <- rep(0, length(coef(old)))
new <- set_coef(old, b)
expect_true(all(coef(new) == 0))
b <- rep(1, length(coef(new)))
new <- set_coef(old, b)
expect_true(all(coef(new) == 1))


# bugfix: nnet single row predictions
dat <- read.csv(testing_path("stata/databases/MASS_polr_01.csv"))
void <- capture.output(
    mod <- nnet::multinom(factor(y) ~ x1 + x2, data = dat, quiet = true)
)
expect_warning(marginaleffects(mod, newdata = datagrid(), type = "probs"))
mfx <- suppressWarnings(marginaleffects(mod, variables = "x1",
                                    newdata = datagrid(), type = "probs"))
expect_inherits(mfx, "data.frame")
expect_equivalent(nrow(mfx), 4)
mfx <- suppressWarnings(marginaleffects(mod,
                                    newdata = datagrid(), type = "probs"))
expect_inherits(mfx, "data.frame")
expect_equivalent(nrow(mfx), 8)


# predictions with multinomial outcome
set.seed(1839)
n <- 1200
x <- factor(sample(letters[1:3], n, TRUE))
y <- vector(length = n)
y[x == "a"] <- sample(letters[4:6], sum(x == "a"), TRUE)
y[x == "b"] <- sample(letters[4:6], sum(x == "b"), TRUE, c(1 / 4, 2 / 4, 1 / 4))
y[x == "c"] <- sample(letters[4:6], sum(x == "c"), TRUE, c(1 / 5, 3 / 5, 2 / 5))
dat <- data.frame(x = x, y = factor(y))
tmp <- as.data.frame(replicate(20, factor(sample(letters[7:9], n, TRUE))))
dat <- cbind(dat, tmp)
void <- capture.output({
    m1 <- multinom(y ~ x, dat)
    m2 <- multinom(y ~ ., dat)
})

# class outcome not supported
expect_error(predictions(m1, type = "class", variables = "x"), pattern = "type")
expect_error(marginalmeans(m1, type = "class", variables = "x"), pattern = "type")

# small predictions
pred1 <- predictions(m1, type = "probs")
pred2 <- predictions(m1, type = "probs", variables = "x")
expect_predictions(pred1, n_row = nrow(dat) * 3)
expect_predictions(pred2, n_row = 9)

# large predictions
idx <- 3:5
n_row <- sapply(dat[, idx], function(x) length(unique(x)))
n_row <- prod(n_row) * length(unique(dat$y))
pred <- predictions(m2, type = "probs", variables = colnames(dat)[idx])
expect_predictions(pred, n_row = n_row)

# massive prediction raises error
expect_error(predictions(m2, type = "probs", variables = colnames(dat)[3:ncol(dat)]),
         pattern = "1 billion rows")



# bugs stay dead #218
set.seed(42)
dat <- data.frame(
    y = factor(sample(c(rep(4, 29), rep(3, 15), rep(2, 4), rep(1, 2)))),
    x = factor(sample(c(rep(1, 17), rep(2, 12), rep(2, 12), rep(1, 9)))),
    z1 = sample(1:2, 50, replace=TRUE), z2=runif(50, 16, 18))
void <- capture.output(
    model <- nnet::multinom(y ~ x + z1 + z2, data = dat, verbose = FALSE, hessian = TRUE)
)
mfx <- suppressWarnings(marginaleffects(model, type = "probs"))
expect_inherits(mfx, "marginaleffects")

