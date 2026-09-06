
library(edgeR)

# Inputs
args <- commandArgs(trailingOnly = TRUE)
counts_file <- args[1]
samplesheet_file <- args[2]

# Importar matriz de expresión
featurecounts <- read.table(
    counts_file,
    sep = "\t",
    header = TRUE,
    comment.char = "#",
    row.names = 1,
    check.names = FALSE
)

# Filtrar las columnas de interés
expression_matrix <- featurecounts[, 6:ncol(featurecounts)]

# Limpiar los nombres de las muestras
colnames(expression_matrix) <- sub(
    "_marked_duplicates\\.bam$",
    "",
    basename(colnames(expression_matrix))
)

# Importar metadatos
metadata <- read.csv(
    samplesheet_file,
    header = TRUE,
    check.names = FALSE
)

# Ordenar los metadatos según las muestras de la matriz
metadata <- metadata[
    match(colnames(expression_matrix), metadata$sample_id),
]

# Creación del objeto de análisis (crea un objeto S3 cuya estructura se puede visualizar con str.)
dge <- DGEList(expression_matrix)

# Definición del diseño experimental
metadata$donor <- factor(metadata$donor)
metadata$condition <- factor(metadata$condition)

design <- model.matrix(~donor+condition, data=metadata)

# Filtrar por baja expresión de genes
keep <- filterByExpr(dge, design)

# Aplicar el filtro
dge <- dge[keep,, keep.lib.sizes=FALSE]

# Boxplot antes de la normalización
png("boxplot_antes.png",
    width = 1400,
    height = 900,
    res = 150)

boxplot(log2(dge$counts + 1),
        las=2,
        ylab = "log2(counts + 1)",
        main="Expresión antes de la normalización")

dev.off()

# Normalizar por TMM
dge <- calcNormFactors(dge, method="TMM")

# Normalizar valores de expresión mediante logaritmo
logCPM <- cpm(dge, log=TRUE)

# Boxplot después de la normalización
png("boxplot_despues.png",
    width = 1400,
    height = 900,
    res = 150)

boxplot(logCPM,
        las=2,
        ylab = "log2(CPM)",
        main="Expresión después de la normalización")

dev.off()

# PCA
# Transponer la matriz y generar componentes principales
pca <- prcomp(t(logCPM))

# Crear dataframe incluyendo la condición 
pca_df <- data.frame(
  PC1 = pca$x[,1],
  PC2 = pca$x[,2],
  condition = metadata$condition,
  donor = metadata$donor
)

# Calcular el % explicado por los ejes
var_expl <- summary(pca)$importance[2,1:2]

# Definir color según condición y forma según donante
condition <- factor(metadata$condition)
donor <- factor(metadata$donor)

condition_color <- as.integer(condition)
donor_shape <- as.integer(donor) + 14

# Exportar PCA post-normalización
png("pca_plot_post-norm.png",
    width = 1600,
    height = 1200,
    res = 150)

plot(pca_df$PC1,
    pca_df$PC2,
    col = condition_color,
    pch = donor_shape,
    cex = 1.5,
    xlab = paste0("PC1 (",
        round(var_expl[1] * 100, 1),
        "%)"),
    ylab = paste0("PC2 (",
        round(var_expl[2] * 100, 1),
        "%)"),
    main = "PCA post-normalization")

legend("topright",
    legend = levels(condition),
    col = seq_along(levels(condition)),
    pch = 19,
    title = "Condition")

legend("bottomright",
    legend = levels(donor),
    pch = seq_along(levels(donor)) + 14,
    title = "Donor")

dev.off()

# Guardar matriz de expresión
write.table(expression_matrix,
    "expression_matrix.tsv",
    sep = "\t",
    quote = FALSE,
    col.names = NA)