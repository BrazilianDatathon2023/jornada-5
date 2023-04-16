## -- Análises -- ##

# Carregando bibliotecas
library(dplyr)
library(arrow)
library(randomForest)
library(caret)
library(broom)

# Carregando banco de dados
df_sinasc <- read_parquet('work/project/datathon/df_ready.parquet')

# Transformando target em factor
df_sinasc$mf <- as.factor(df_sinasc$mf)
df_sinasc$def_parto_prematuro <- as.factor(df_sinasc$def_parto_prematuro)
str(df_sinasc)

## Dividir em treino e teste
index_train <- sample(nrow(df_sinasc), round(0.8 * nrow(df_sinasc)))
train <- df_sinasc[index_train, ]
test <- df_sinasc[-index_train, ]

# Definir as colunas preditoras (excluindo a coluna alvo)
predictors <- names(train)[-which(colnames(train)=='mf')]

# Definir a coluna alvo
target <- names(train)[which(colnames(train)=='mf')]

# Aplicar undersampling na classe "FALSE"
train <- downSample(x = train[predictors], y = train$mf, list = FALSE, yname = "mf")

# Definir hiperparâmetros para ajuste
ntree_range <- c(500, 1000, 1500)
mtry_range <- c(2, 3, 4)

# Ajustar modelo com os melhores parâmetros encontrados
rf_model <- randomForest(mf ~ .,
                         data = train,
                         ntree = 100, mtry = 2, 
                         importance = TRUE)

# Ver o feature importance
importance_rf <- importance(rf_model)
importance_rf <- importance_rf[order(importance_rf[, 1], decreasing = TRUE), ]
write.csv2(importance_rf, 'work/project/datathon/importance_rf.csv')

n_vars <- 10
vars_importantes <- rownames(importance_rf[1:n_vars, ])
vars_importantes <- c(vars_importantes, 'mf')
train_reduced <- train[, vars_importantes]

options(scipen = 999, digits = 2)

# Regressão Logística
glm_model <- glm(mf ~ ., data = train_reduced, family = "binomial")
tb <- tidy(glm_model, exponentiate =  T, conf.int = T)
View(tb)

tb_filtrado <- tb %>%
  filter(p.value < 0.05 & ((conf.low < 1 & conf.high <1) | (conf.low > 1 & conf.high >1))) %>%
  select(term, estimate, conf.low, conf.high)
View(tb_filtrado)
write.csv2(tb_filtrado, 'work/project/datathon/odds_ratio.csv')
