source("helpers.R", local = TRUE)

# conf.level argument changes conf.int size
dat <- mtcars
dat$cyl <- factor(dat$cyl)
mod <- lm(mpg ~ hp + cyl, data = mtcars)
mfx95 <- marginaleffects(mod, conf.level = .95)
mfx99 <- marginaleffects(mod, conf.level = .99)
cmp95 <- comparisons(mod, conf.level = .95)
cmp99 <- comparisons(mod, conf.level = .99)
pre95 <- predictions(mod, conf.level = .95)
pre99 <- predictions(mod, conf.level = .99)
expect_true(all(mfx95$conf.low > mfx99$conf.low))
expect_true(all(mfx95$conf.high < mfx99$conf.high))
expect_true(all(cmp95$conf.low > cmp99$conf.low))
expect_true(all(cmp95$conf.high < cmp99$conf.high))
expect_true(all(pre95$conf.low > pre99$conf.low))
expect_true(all(pre95$conf.high < pre99$conf.high))



# conf.low manual
mod <- lm(mpg ~ hp, data = mtcars)
cmp <- comparisons(mod)
critical_z <- qnorm(.025)
lb <- cmp$comparison - abs(critical_z) * cmp$std.error
ub <- cmp$comparison + abs(critical_z) * cmp$std.error
expect_equivalent(cmp$conf.low, lb)
expect_equivalent(cmp$conf.high, ub)

