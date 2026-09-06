process R_EXPLORATORY {

    tag "exploratory_analysis"

    container "quay.io/biocontainers/bioconductor-edger:4.8.2--r45h01b2380_0"

    publishDir "${params.outdir}/r_exploratory",
        mode: 'copy'

    input:
    path counts
    path samplesheet
    path r_script

    output:
    path "boxplot_antes.png", emit: boxplot_before
    path "boxplot_despues.png", emit: boxplot_after
    path "pca_plot_post-norm.png", emit: pca
    path "expression_matrix.tsv", emit: expression_matrix

    script:
    """
    Rscript \
        ${r_script} \
        ${counts} \
        ${samplesheet}
    """
}