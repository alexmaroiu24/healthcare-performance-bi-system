# =========================================================
# ANALIZA COMPONENTELOR PRINCIPALE - VARIANTA FACTOMINER
# =========================================================

# 1. Pachete
library(readxl)
library(dplyr)
library(FactoMineR)
library(factoextra)
library(ggplot2)
library(writexl)

# =========================================================
# 2. Import date
# =========================================================
message("Selectati fisierul Excel...")
df <- read_excel(file.choose())


cor_resurse <- cor(X_resurse, use = "complete.obs")
round(cor_resurse, 3)

cor_rezultate <- cor(X_rezultate, use = "complete.obs")
round(cor_rezultate, 3)


library(corrplot)

# împărțire fereastră în 2 grafice
par(mfrow = c(1, 2))

# Matrice corelație - RESURSE
corrplot(cor_resurse,
         method = "color",
         addCoef.col = "black",
         tl.col = "black",
         number.cex = 0.7,
         title = "Matricea de corelație - Indicele de resurse",
         mar = c(0,0,2,0))

# Matrice corelație - REZULTATE
corrplot(cor_rezultate,
         method = "color",
         addCoef.col = "black",
         tl.col = "black",
         number.cex = 0.7,
         title = "Matricea de corelație - Indicele de rezultate",
         mar = c(0,0,2,0))

# revenire la layout normal
par(mfrow = c(1,1))

# =========================================================
# 3. Selectare variabile
# =========================================================

# Indice resurse
X_resurse <- df %>%
  select(Cheltuieli, Nr_paturi, Nr_medici, Nr_asistenti_medicali)

# Indice rezultate
X_rezultate <- df %>%
  select(Nr_externari, Nr_zile_spitalizare)

# =========================================================
# 4. PCA pentru indicele de RESURSE
# scale.unit = TRUE => standardizare automata
# =========================================================
pca_resurse <- PCA(X_resurse, scale.unit = TRUE, graph = FALSE)

# Rezumat
summary(pca_resurse)

# Valori proprii (IMPORTANT pentru tabel)
eig_resurse <- pca_resurse$eig
eig_resurse

# Loadings (corelații variabile - componente)
loadings_resurse <- pca_resurse$var$coord
loadings_resurse

# Scoruri (coordonate observații)
scoruri_resurse <- pca_resurse$ind$coord

# Indice resurse = Dim 1
df$Indice_Resurse_raw <- scoruri_resurse[,1]

# Corecție semn
if(cor(df$Indice_Resurse_raw, df$Cheltuieli, use = "complete.obs") < 0){
  df$Indice_Resurse_raw <- -df$Indice_Resurse_raw
}

# Scalare 0-1
range01 <- function(x){
  (x - min(x, na.rm = TRUE)) / (max(x, na.rm = TRUE) - min(x, na.rm = TRUE))
}
df$Indice_Resurse <- range01(df$Indice_Resurse_raw)

# =========================================================
# 5. PCA pentru indicele de REZULTATE
# =========================================================
pca_rezultate <- PCA(X_rezultate, scale.unit = TRUE, graph = FALSE)

summary(pca_rezultate)

eig_rezultate <- pca_rezultate$eig
eig_rezultate

loadings_rezultate <- pca_rezultate$var$coord
loadings_rezultate

scoruri_rezultate <- pca_rezultate$ind$coord

df$Indice_Rezultate_raw <- scoruri_rezultate[,1]

# Corecție semn
if(cor(df$Indice_Rezultate_raw, df$Nr_externari, use = "complete.obs") < 0){
  df$Indice_Rezultate_raw <- -df$Indice_Rezultate_raw
}

df$Indice_Rezultate <- range01(df$Indice_Rezultate_raw)

# =========================================================
# 6. SCOR DE PERFORMANȚĂ
# =========================================================
eps <- 0.001

df <- df %>%
  mutate(
    Scor_Performanta_brut = Indice_Rezultate / (Indice_Resurse + eps),
    Scor_Performanta = 100 * (
      (Scor_Performanta_brut - min(Scor_Performanta_brut, na.rm = TRUE)) /
        (max(Scor_Performanta_brut, na.rm = TRUE) - min(Scor_Performanta_brut, na.rm = TRUE))
    )
  )

# =========================================================
# 7. GRAFICE (exact ca în seminarii)
# =========================================================

# Scree plot - resurse
fviz_eig(pca_resurse, addlabels = TRUE) +
  labs(title = "Varianța explicată - indicele de resurse")

# Scree plot - rezultate
fviz_eig(pca_rezultate, addlabels = TRUE) +
  labs(title = "Varianța explicată - indicele de rezultate")

# Cercul corelațiilor - resurse
fviz_pca_var(pca_resurse, col.var = "contrib") +
  labs(title = "Cercul corelațiilor - resurse")

# Cercul corelațiilor - rezultate
fviz_pca_var(pca_rezultate, col.var = "contrib") +
  labs(title = "Cercul corelațiilor - rezultate")

# Observațiile (unități) în planul principal
fviz_pca_ind(
  pca_resurse,
  geom = "point",
  habillage = df$Nivel_competenta,
  repel = FALSE
) +
  labs(title = "Unități sanitare - indice resurse")

fviz_pca_ind(
  pca_rezultate,
  geom = "point",
  habillage = df$Nivel_competenta,
  repel = FALSE
) +
  labs(title = "Unități sanitare - indice rezultate")

# Scatter final
ggplot(df, aes(x = Indice_Resurse, y = Indice_Rezultate, color = Nivel_competenta)) +
  geom_point(size = 2.5) +
  labs(
    title = "Relația dintre indicele de resurse și indicele de rezultate",
    x = "Indice resurse",
    y = "Indice rezultate"
  ) +
  theme_minimal()

# =========================================================
# 8. TABELE PENTRU WORD
# =========================================================

# Rezumat ACP resurse
rezumat_resurse <- as.data.frame(eig_resurse)
colnames(rezumat_resurse) <- c("Valoare_proprie", "Procent_varianță", "Procent_cumulat")
rezumat_resurse$Componenta <- paste0("PC", 1:nrow(rezumat_resurse))

# Rezumat ACP rezultate
rezumat_rezultate <- as.data.frame(eig_rezultate)
colnames(rezumat_rezultate) <- c("Valoare_proprie", "Procent_varianță", "Procent_cumulat")
rezumat_rezultate$Componenta <- paste0("PC", 1:nrow(rezumat_rezultate))

# =========================================================
# 9. EXPORT
# =========================================================
write_xlsx(
  list(
    date_finale = df,
    rezumat_resurse = rezumat_resurse,
    rezumat_rezultate = rezumat_rezultate,
    loadings_resurse = as.data.frame(loadings_resurse),
    loadings_rezultate = as.data.frame(loadings_rezultate)
  ),
  "rezultate_PCA_factominer.xlsx"
)



# =========================================================
# SCREE PLOT COMPARATIV (RESURSE + REZULTATE)
# =========================================================

library(factoextra)
library(gridExtra)

# Scree plot - resurse
plot_resurse <- fviz_eig(pca_resurse, addlabels = TRUE) +
  labs(
    title = "Varianța explicată - Indicele de resurse",
    x = "Componente principale",
    y = "Procent din varianța explicată"
  ) +
  theme_minimal()

# Scree plot - rezultate
plot_rezultate <- fviz_eig(pca_rezultate, addlabels = TRUE) +
  labs(
    title = "Varianța explicată - Indicele de rezultate",
    x = "Componente principale",
    y = "Procent din varianța explicată"
  ) +
  theme_minimal()

# Afișare în aceeași fereastră
grid.arrange(plot_resurse, plot_rezultate, ncol = 2)