
library(readxl)
library(dplyr)
library(cluster)     
library(factoextra)  
library(gridExtra)
library(NbClust)
library(ggplot2)
library(tidyr)

df <- read_excel(file.choose())

vars_interes <- c("Nr_paturi", "Nr_medici", "Nr_asistenti_medicali", 
                  "Cheltuieli", "Nr_externari", "Nr_zile_spitalizare")
cod_judet <- c(
  "ALBA"="AB","ARAD"="AR","ARGES"="AG","BACAU"="BC","BIHOR"="BH",
  "BISTRITA NASAUD"="BN","BOTOSANI"="BT","BRASOV"="BV","BRAILA"="BR",
  "BUCURESTI"="B","BUZAU"="BZ","CARAS SEVERIN"="CS","CALARASI"="CL",
  "CLUJ"="CJ","CONSTANTA"="CT","COVASNA"="CV","DAMBOVITA"="DB",
  "DOLJ"="DJ","GALATI"="GL","GIURGIU"="GR","GORJ"="GJ","HARGHITA"="HR",
  "HUNEDOARA"="HD","IALOMITA"="IL","IASI"="IS","ILFOV"="IF",
  "MARAMURES"="MM","MEHEDINTI"="MH","MURES"="MS","NEAMT"="NT",
  "OLT"="OT","PRAHOVA"="PH","SATU MARE"="SM","SALAJ"="SJ",
  "SIBIU"="SB","SUCEAVA"="SV","TELEORMAN"="TR","TIMIS"="TM",
  "TULCEA"="TL","VASLUI"="VS","VALCEA"="VL","VRANCEA"="VN"
)

# Creare identificator unic (Cod_Spital)
df$Cod_Spital <- paste0(cod_judet[toupper(df$Denumire_Judet)], 1:nrow(df)
df_clean <- df[complete.cases(df[, vars_interes]), ]
nrow(df_clean)

# STATISTICI DESCRIPTIVE 
calc_cv <- function(x) {
  if(mean(x, na.rm=TRUE) == 0) return(0)
  (sd(x, na.rm=TRUE) / mean(x, na.rm=TRUE)) * 100
}
tabel_stats <- df_clean %>%
  summarise(across(all_of(vars_interes), list(
    Min = ~min(.x, na.rm = TRUE),
    Max = ~max(.x, na.rm = TRUE),
    Media = ~mean(.x, na.rm = TRUE),
    AbatereStd = ~sd(.x, na.rm = TRUE),
    CV = ~calc_cv(.x)
  ), .names = "{.col}.{.fn}")) %>%  
  pivot_longer(everything(), 
               names_to = c("Variabila", "Statistica"), 
               names_sep = "\\.") %>%
  pivot_wider(names_from = Statistica, values_from = value)

options(scipen = 999)
print(as.data.frame(tabel_stats))

#Outlieri
library(dplyr)
date_complete <- complete.cases(vars)
vars_clean <- vars[date_complete, ]
spitale_clean <- df$DENUMIRE_UNITATE[date_complete]
# distanța Mahalanobis
dist_mah <- mahalanobis(
  vars_clean,
  colMeans(vars_clean),
  cov(vars_clean)
)

prag_mah <- qchisq(0.999, df = ncol(vars_clean))

outlieri_mah <- which(dist_mah > prag_mah)

# tabel cu spitalele identificate
rez_mah <- data.frame(
  Index = outlieri_mah,
  Spital = spitale_clean[outlieri_mah],
  Scor_Mahalanobis = dist_mah[outlieri_mah]
)
cat("Outlieri identificați prin Mahalanobis:", nrow(rez_mah), "\n")
print(rez_mah)

install.packages("isotree")   
library(isotree)

iso_model <- isolation.forest(
  as.matrix(vars_clean),
  ntrees = 500,
  sample_size = nrow(vars_clean),
  ndim = 1
)


scor_anomalie <- predict(iso_model, as.matrix(vars_clean), type = "score")
prag_iso <- quantile(scor_anomalie, 0.95)

outlieri_iso <- which(scor_anomalie > prag_iso)

rez_iso <- data.frame(
  Index = outlieri_iso,
  Spital = spitale_clean[outlieri_iso],
  Scor_Anomalie = scor_anomalie[outlieri_iso]
)

cat("Outlieri identificați prin Isolation Forest:", nrow(rez_iso), "\n")
print(rez_iso)


comun_idx <- intersect(outlieri_mah, outlieri_iso)

rez_comun <- data.frame(
  Index = comun_idx,
  Spital = spitale_clean[comun_idx],
  Scor_Mahalanobis = dist_mah[comun_idx],
  Scor_Anomalie = scor_anomalie[comun_idx]
)

cat("Outlieri comuni identificați de ambele metode:", nrow(rez_comun), "\n")
print(rez_comun)

# ANALIZA COMPARATIVĂ A OUTLIERILOR FAȚĂ DE MEDIA TOTALĂ 
library(dplyr)
library(ggplot2)
library(tidyr)

medii_globale <- df %>%
  summarise(
    m_paturi = mean(Nr_paturi, na.rm = TRUE),
    m_medici = mean(Nr_medici, na.rm = TRUE),
    m_asist  = mean(Nr_asistenti_medicali, na.rm = TRUE),
    m_chelt  = mean(Cheltuieli, na.rm = TRUE),
    m_ext    = mean(Nr_externari, na.rm = TRUE),
    m_zile   = mean(Nr_zile_spitalizare, na.rm = TRUE)
  )
df_plot_total <- df %>%
  filter(DENUMIRE_UNITATE %in% c(
    "SPITALUL MUNICIPAL CLINIC \"'FILANTROPIA\" CRAIOVA",
    "SPITALUL ORASENESC \"SF. SPIRIDON\" MIOVENI",
    "SPITALUL MUNICIPAL SIGHETUL MARMATIEI",
    "SPITALUL MUNICIPAL 'SF.DOCTORI COSMA SI DAMIAN' RADAUTI",
    "SPITALUL MUNICIPAL\"DR.GHEORGHE MARINESCU\"TARNAVENI"
  )) %>%
  mutate(
    Paturi = Nr_paturi / medii_globale$m_paturi,
    Medici = Nr_medici / medii_globale$m_medici,
    Asistenți = Nr_asistenti_medicali / medii_globale$m_asist,
    Cheltuieli = Cheltuieli / medii_globale$m_chelt,
    `Pacienți tratați` = Nr_externari / medii_globale$m_ext, 
    `Zile Spitalizare` = Nr_zile_spitalizare / medii_globale$m_zile
  ) %>%
  select(DENUMIRE_UNITATE, Paturi, Medici, Asistenți, Cheltuieli, `Pacienți tratați`, `Zile Spitalizare`) %>%
  pivot_longer(cols = -DENUMIRE_UNITATE, names_to = "Variabila", values_to = "Raport_fata_de_Medie")

ggplot(df_plot_total, aes(x = Variabila, y = Raport_fata_de_Medie, fill = DENUMIRE_UNITATE)) +
  geom_bar(stat = "identity", 
           position = position_dodge(width = 0.8), 
           color = "white", 
           linewidth = 0.2) + 
  geom_hline(yintercept = 1, linetype = "dashed", color = "red", size = 1) +
  scale_fill_brewer(palette = "Set2") + 
  theme_minimal() +
  labs(
    title = "Profilul Unităților Atipice vs. Media Întregului Eșantion",
    subtitle = "Linia roșie (1.0) reprezintă media generală a tuturor spitalelor",
    y = "Abaterea de la Media Totală (Multiplu)",
    x = "Indicatori Analizați",
    fill = "Denumire Spital"
  ) +
  theme(
    legend.position = "bottom",
    legend.text = element_text(size = 7),
    axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1, face = "bold"),
    panel.grid.minor = element_blank()
  ) +
  guides(fill = guide_legend(ncol = 1))

#Eliminare Outlieri si Statistici

df_clean <- df[-rez_comun$Index, ]

statistici <- function(x) {
  data.frame(
    Min = min(x, na.rm = TRUE),
    Max = max(x, na.rm = TRUE),
    Medie = mean(x, na.rm = TRUE),
    Abatere_Std = sd(x, na.rm = TRUE),
    CV = (sd(x, na.rm = TRUE) / mean(x, na.rm = TRUE)) * 100
  )
}

rezultate <- do.call(rbind, lapply(vars, statistici))

rezultate$Variabila <- rownames(rezultate)
rownames(rezultate) <- NULL

rezultate <- rezultate[, c("Variabila", "Min", "Max", "Medie", "Abatere_Std", "CV")]

print(rezultate)

rezultate <- rezultate %>%
  mutate(across(where(is.numeric), round, 2))

print(rezultate)



# Cluster -----------------------------------------------------------------


X <- df_clean[, vars_interes]
rownames(X) <- df_clean$Cod_Spital
acp <- princomp(X, cor = TRUE, scores = TRUE)
summary(acp)
loadings(acp)

scoruri <- data.frame(acp$scores[, 1:2])
names(scoruri) <- c("Z1", "Z2")
rownames(scoruri) <- df_clean$Cod_Spital

print(scoruri)
d <- dist(scoruri)

library(factoextra)
library(ggplot2)

fviz_nbclust( scoruri, kmeans, method = "wss" ) +
  geom_vline(
    xintercept = 3, 
    linetype = 2, 
    color = "darkblue"
  ) +
  labs(
    title = "Metoda Elbow",
    x = "Număr de clustere (k)",
    y = "Variabilitate intra-cluster (WSS)"
  ) +
  theme_minimal()


# K-MEANS
set.seed(123)
km <- kmeans(scoruri, centers = 3, nstart = 25)
km

clase <- km$cluster
table(clase)

fviz_cluster(km, data = scoruri, 
             palette = NULL,     )
             ellipse.type = "convex", 
             repel = FALSE,       
             labelsize = 9,      
             pointsize = 1.2,    
             ggtheme = theme_minimal(),
             main = "Cluster Plot")


s_km <- silhouette(clase, d)

plot(
  s_km,
  col = c("#E15759", "#59A14F", "#4E79A7"),)
  border = NA,                    
  main = "Silhouette Plot",
  xlab = "Silhouette Statistic",
  ylab = "Cluster",
  cex.names = 0.7,
  do.n.k = FALSE,                
  do.clus.stat = FALSE             
)

abline(v = mean(s_km[, 3]), lty = 2, col = "gray40", lwd = 1.5)
mtext(
  paste("Average Silhouette Value =", round(mean(s_km[, 3]), 3)),
  side = 3,
  line = 0.3,
  cex = 0.85,
  font = 2
)

mean(s_km[, 3])

# INFORMAȚII DESPRE KMEANS
km$centers       
km$totss         
km$withinss      
km$tot.withinss  
km$betweenss     

df_clean$cluster_kmeans <- clase
table(df_clean$cluster_kmeans)

# PROFILUL CLUSTERELOR PE DATELE ORIGINALE
aggregate(X, list(Cluster = df_clean$cluster_kmeans), mean)
df_clean$Cluster_Kmeans <- as.factor(clase)
statistici_rop <- df_clean %>%
  group_by(Cluster_Kmeans) %>%
  summarise(
    Nr_Spitale    = n(),
    Minim_proc    = min(ROP, na.rm = TRUE),
    Maxim_proc    = max(ROP, na.rm = TRUE),
    Medie_proc    = mean(ROP, na.rm = TRUE),
    Abatere_ST    = sd(ROP, na.rm = TRUE),
    Coef_Var_proc = (sd(ROP, na.rm = TRUE) / mean(ROP, na.rm = TRUE)) * 100
  ) %>%





