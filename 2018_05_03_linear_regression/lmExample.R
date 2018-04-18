library(car)
library(tidyverse)
library(ggplot2)
library(broom)


# Introduction with anscombe dataset
head(datasets::anscombe)
anscombe %>% skimr::skim()
anscombe %>% select(x1, y1)
ggplot(anscombe, aes(x1, y1)) + geom_point()

data("WeightLoss") # from library(car)
head(WeightLoss[c(1,13,25),])
WeightLoss %>% skimr::skim()

# "Weight Loss at 1 month" ~ "Self Esteem at 1 month
m1 <- lm(wl1 ~ se1, data = WeightLoss)
m1 %>% summary()
m1 %>% broom::tidy()
m1 %>% broom::glance()

# Calculating coefficient using pearson correlation & standard deviation 
# lm(Y ~ X) coefficient of X is equal to "cor(X, Y) * (SD(Y) / SD(X))"
with(WeightLoss, {
  cor(se1, wl1) * (sd(wl1) / sd(se1))
})

WeightLoss <- WeightLoss %>% 
  mutate(wl1_std = as.vector(scale(wl1, center = T, scale = T)), 
         se1_std = as.vector(scale(se1, center = T, scale = T)))
m2 <- lm(wl1_std ~ se1_std, data = WeightLoss)
m2 %>% broom::tidy() %>% mutate_if(is.numeric, round, digits = 4)
with(WeightLoss, cor(se1, wl1))

m2 %>% broom::glance()


# Calculating regression with loss function and optim()
  # B: vector of parameters over which minimization is to take place, i.e. coefficients
  # X: data in form of design matrix / model matrix, i.e. indepedent var(s)
  # y: continuous variable to be modeled, i.e. dependent var
ssrLossFunction <- function(B, X, y){
  mu <- X %*% B
  sum((y - mu)^2)
}
X <- model.matrix( ~ se1, data = WeightLoss)
y <- WeightLoss[, "wl1", drop=FALSE]
(m3 <- optim(c(0,0), fn = ssrLossFunction, X = X, y = y))
m1_m3_comparsion <- data.frame(rbind(
    c(m3$par, m3$value), 
    c(coef(m1), sum(resid(m1)^2))
))
rownames(m1_m3_comparsion) <-  c("optim() method", "lm() method")
colnames(m1_m3_comparsion) <- c("Intercept", "se1", "SSR")
m1_m3_comparsion


# Looking at model.matrix() in depth

# Create new categorical variable
WeightLoss <- WeightLoss %>% 
  mutate(HighSelfEsteem = ifelse(se1 >= mean(se1), "High", "Low"))
X_with_cat <- model.matrix( ~ se1 + HighSelfEsteem, data = WeightLoss)


WeightLoss$group


# ----
df <- dfTrain %>% 
  left_join(
    dfResources,
    by = "id"
  ) %>% 
  # arrange(id) %>% 
  # slice(1:1000) %>% 
  # Aggregate quantity & price so that each row is a single project
  group_by(id) %>% 
  summarise(
    project_is_approved = unique(project_is_approved),
    project_grade_category = unique(project_grade_category),
    project_resource_total_price = as.double(sum(quantity * price)),
    project_resource_total_quantity = as.double(sum(quantity)),
    project_resource_unique_item_count = as.double(length(unique(quantity)))
  )

df_lm  <- df %>% 
  select(-id, -project_grade_category, -project_is_approved)



datasets::PlantGrowth %>% head

# Project Price vs # of unique items
cor_Price_ItemCount <- with(df_lm,cor(project_resource_unique_item_count, project_resource_total_price))
df_lm %>% 
  ggplot(
    aes(x = jitter(project_resource_unique_item_count), 
        y = project_resource_total_price)) +
  geom_point(alpha=0.5, stroke = 0, pch = 16) +
  scale_x_continuous(breaks = c(1:13)) + 
  ggtitle(paste0("Project Price vs # of unique items (cor = ", round(cor_Price_ItemCount, 4) ,")"))

df_lm_std <- df_lm %>% 
  mutate(
    project_resource_unique_item_count = as.vector(scale(project_resource_unique_item_count)),
    project_resource_total_price = as.vector(scale(project_resource_total_price))
  )
df_lm_std %>% 
  ggplot(
    aes(x = jitter(project_resource_unique_item_count), 
        y = project_resource_total_price)) +
  scale_x_continuous(breaks = round(unique(df_lm_std$project_resource_unique_item_count),4)) + 
  geom_point(alpha=0.5, stroke = 0, pch = 16) +
  ggtitle(paste0("Normalized : Project Price vs # of unique items (cor = ", round(cor_Price_ItemCount, 4) ,")"))


# lm(project_resource_total_price ~ project_resource_unique_item_count)
df_lm %>% skimr::skim()
df_lm_std %>% skimr::skim()
# df_lm %>% skimr::skim_to_wide()

m_Price_totQuantity <- lm(project_resource_total_price ~ project_resource_unique_item_count, data = df_lm) 
m_Price_totQuantity %>% summary()
m_Price_totQuantity %>% broom::tidy()
m_Price_totQuantity %>% broom::glance()

# Calculating coefficient using pearson correlation & standard deviation 
# lm(Y ~ X) coefficient of X is equal to "cor(X, Y) * (SD(Y) / SD(X))"
with(df_lm, {
  cor(project_resource_unique_item_count, project_resource_total_price) *
    (
      sd(project_resource_total_price) / sd(project_resource_unique_item_count)
    )
})
