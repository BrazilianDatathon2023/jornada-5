## -- União dos dados e missing data --

# Definindo local de trabalho
setwd("C:/Users/drt43847/Desktop/DATATHON")

# Carregando bibliotecas
library(dplyr)
library(arrow)
library(readxl)

# Local dos arquivos
sinasc <- 'raw_data/SINASC/'

# Encontre todos os arquivos na pasta que contenham "2020" no nome
arquivos_2020 <- list.files(path = sinasc, pattern = "2020", full.names = TRUE)
arquivos_2019 <- list.files(path = sinasc, pattern = "2019", full.names = TRUE)

# Crie uma lista de dataframes, carregando cada arquivo encontrado
lista_dfs_2020 <- lapply(arquivos_2020, read.csv)
lista_dfs_2019 <- lapply(arquivos_2019, read.csv)


# Una todos os dataframes usando a função rbind()
df_sinasc_2020 <- do.call(rbind, lista_dfs_2020)
df_sinasc_2019 <- do.call(rbind, lista_dfs_2019)

str(df_sinasc_2020)

# Função para checar valores ausentes
verifica_missing <- function(x)
{
  return(colSums(is.na(x)))
  
}

# Juntando os dois anos
df_sinasc <- rbind(df_sinasc_2019, df_sinasc_2020)
write_parquet(df_sinasc, 'curated_data/df_sinasc_19_20.parquet')

# Verificando missing data
miss_sinasc <- data.frame(verifica_missing(df_sinasc))
colnames(miss_sinasc) <- 'qtd_miss'
# Calcular a porcentagem de missing data para cada coluna
for (i in 1:nrow(miss_sinasc)){
  miss_sinasc$percent_missing[i] <- round(miss_sinasc$qtd_miss[i] / nrow(df_sinasc) * 100,2)
}

write.csv2(miss_sinasc, 'curated_data/df_miss_sinasc.csv')

# Limpar colunas missing (acima de 30%)
col_clear <- row.names(subset(miss_sinasc ,miss_sinasc$percent_missing >= 30))
df_sinasc_limpo <- select(df_sinasc, -c(col_clear))

write_parquet(df_sinasc_limpo, 'curated_data/df_sinasc_limpo.parquet')

# Selecionar colunas
cols <- read_excel('curated_data/selecao_colunas.xlsx')

# seleciona as colunas do df_sinasc_limpo
df_sinasc_analytic <- df_sinasc_limpo[, cols$variavel[which(cols$Permanecer == 1)]]

write_parquet(df_sinasc_analytic, 'curated_data/df_sinasc_analytic.parquet')


      