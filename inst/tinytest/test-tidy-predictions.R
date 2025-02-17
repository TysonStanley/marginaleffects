source("helpers.R")
requiet("prediction")
requiet("insight")


# lm: Average prediction vs. {prediction}
mod <- lm(am ~ mpg + drat + factor(cyl), data = mtcars)
pre <- predictions(mod)
tid <- tidy(pre)
expect_equal(nrow(tid), 1)
expect_equal(mean(pre$predicted), tid$estimate)
lee <- data.frame(summary(prediction::prediction(mod)))
expect_equivalent(tid$estimate, lee$Prediction)
expect_equivalent(tid$std.error, lee$SE)

# lm: Group-Average Prediction (no validity)
pre <- predictions(mod)
tid <- tidy(pre, by = "cyl")
expect_equal(nrow(tid), 3)

# glm response scale
# CI retrieved by `insight::get_predicted()` for units
# CI not supported yet for `tidy()`
mod <- glm(am ~ mpg + drat + factor(cyl), data = mtcars, family = binomial)
pre <- predictions(mod)
tid <- tidy(pre)
lee <- data.frame(summary(prediction::prediction(mod)))
ins <- data.frame(insight::get_predicted(mod))
expect_equivalent(tid$estimate, lee$Prediction)
expect_equivalent(pre$predicted, ins$Predicted)
expect_equivalent(pre$std.error, ins$SE)
expect_equivalent(pre$conf.low, ins$CI_low)
expect_equivalent(pre$conf.high, ins$CI_high)
expect_true("std.error" %in% colnames(tid))
expect_true("conf.low" %in% colnames(tid))

# glm link scale: CI fully supported
mod <- glm(am ~ mpg + drat + factor(cyl), data = mtcars, family = binomial)
pre <- predictions(mod, type = "link")
tid <- tidy(pre)
lee <- data.frame(summary(prediction::prediction(mod, type = "link")))
ins <- data.frame(insight::get_predicted(mod, predict = "link"))
expect_equivalent(tid$estimate, lee$Prediction)
expect_equivalent(tid$std.error, lee$SE)
expect_equivalent(tid$conf.low, lee$lower)
expect_equivalent(tid$conf.high, lee$upper)
expect_equivalent(tid$estimate, lee$Prediction)
expect_equivalent(pre$predicted, ins$Predicted)
expect_equivalent(pre$std.error, ins$SE)
expect_equivalent(pre$conf.low, ins$CI_low)
expect_equivalent(pre$conf.high, ins$CI_high)
