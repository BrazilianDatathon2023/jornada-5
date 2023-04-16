################################################################################
#               INSTALAÇÃO E CARREGAMENTO DE PACOTES NECESSÁRIOS               #
################################################################################
#Pacotes utilizados 
pacotes <- c("arrow","tidyverse","readxl")

if(sum(as.numeric(!pacotes %in% installed.packages())) != 0){
  instalador <- pacotes[!pacotes %in% installed.packages()]
  for(i in 1:length(instalador)) {
    install.packages(instalador, dependencies = T)
    break()}
  sapply(pacotes, require, character = T) 
} else {
  sapply(pacotes, require, character = T) 
}


#carregar arquivos
df <- read_parquet("df_sinasc_limpo.parquet")
colunas <- read_excel("Colunas do SINASC selecionadas.xlsx")
GeoSES <- read_excel("GeoSES.xls")
str(df)

#definir colunas que serão removidas do SINASC
colunas <- colunas %>% filter(Permanecer==1)
colunas <- colunas [,1]
vetor <- pull(colunas, Variável)
df <- dplyr::select(df, vetor)
str(df)

#definir colunas que serão removidas do GeoSES
GeoSES <- dplyr::select(GeoSES,c(2,10:20))

#filtrar ma formacao desconhecida
df <- filter(df, def_anomalia != "Ignorado")

#criar coluna com dummy má formação
df$mf <- ifelse(df$def_anomalia == "Sim", TRUE, FALSE)
table(df$mf)

#unir dataframe com a base GeoSES
colnames(GeoSES)[colnames(GeoSES) == "MUNIC_CODE6"] <- "CODMUNNASC"
df <- left_join(df,GeoSES)


#limpoeza da base
df <- drop_na(df)
df <-  df %>% filter (def_parto_prematuro != "Inconclusivo-IG")
df <-  df %>% filter (def_parto_prematuro != "Inconclusivo-Peso")
df <-  df %>% filter (IDADEMAE!= 99)
df <- df %>% filter(df$QTDFILVIVO < (df$IDADEMAE - 8))
df <- df %>% filter(df$QTDFILMORT < (df$IDADEMAE - 8))
df <- df %>% filter(df$PESO < (mean(df$PESO) + 3*sd(df$PESO)))
df$QTDPARTNOR <-  NULL
df$QTDPARTCES <-  NULL
df$STCESPARTO <-  NULL
df$TPNASCASSI <-  NULL
df <- df %>% filter(df$CONSPRENAT <= 20)
df$TPAPRESENT <- factor(ifelse(df$TPAPRESENT == 1, "Cefálico", 
                               ifelse(df$TPAPRESENT == 2, "Pélvico",
                               ifelse(df$TPAPRESENT == 3, "Transversa",
                               ifelse(df$TPAPRESENT == 9, "Ignorado",0)))))
df$STTRABPART <- factor(ifelse(df$STTRABPART == 1, "Sim", 
                               ifelse(df$STTRABPART == 2, "Não",
                                      ifelse(df$STTRABPART == 3, "Não se aplica",
                                             ifelse(df$STTRABPART == 9, "Ignorado",0)))))

df$ESCMAEAGR1 <- factor(ifelse(df$ESCMAEAGR1 == 0, "Sem escolaridade", 
                               ifelse(df$ESCMAEAGR1 == 1, "Fund 1 Incompleto",
                                      ifelse(df$ESCMAEAGR1 == 2, "Fund 1 Completo",
                                             ifelse(df$ESCMAEAGR1 == 3, "Fund 2 Incompleto", 
                                                    ifelse(df$ESCMAEAGR1 == 4, "Fund 2 Completo",
                                                           ifelse(df$ESCMAEAGR1 == 5, "Medio incompleto",
                                                                  ifelse(df$ESCMAEAGR1 == 6, "Medio Completo",
                                                                         ifelse(df$ESCMAEAGR1 == 7, "Superior Incompleto",
                                                                                ifelse(df$ESCMAEAGR1 == 8, "Superior Completo",
                                                                                       ifelse(df$ESCMAEAGR1 == 7, "Superior Inompleto",
                                                                                              "Ignorado"
                                                    )))))))))))

df[df==99] <- NA
# Ajuste chr para fator
df$def_loc_nasc <- as.factor(df$def_loc_nasc)
df$def_est_civil <- as.factor(df$def_est_civil)
df$def_gestacao <- as.factor(df$def_gestacao)
df$def_gravidez <- as.factor(df$def_gravidez)
df$def_parto <- as.factor(df$def_parto)
df$def_consultas <- as.factor(df$def_consultas)
df$def_sexo <- as.factor(df$def_sexo)
df$def_raca_cor <- as.factor(df$def_raca_cor)
df$nasc_CAPITAL <- as.factor(df$nasc_CAPITAL)
df$nasc_SIGLA_UF <- as.factor(df$nasc_SIGLA_UF)
df$def_parto_prematuro <- as.factor(df$def_parto_prematuro)

#remover NA e outras colunas
df <- drop_na(df)
df <- df[, -c(1, 17)]
df <- df[, -c(16)]

# Salvando banco de dados
write_parquet(df, 'df_ready.parquet')

#==== ANACOR======
# Definição da quantidade de observações na tabela de contingência
n <- sum(tabela_contingencia)
n