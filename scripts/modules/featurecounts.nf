process FEATURECOUNTS {

    tag "gene_counts"

    container "quay.io/biocontainers/subread:2.1.1--h577a1d6_0"

    publishDir "${params.outdir}/featurecounts",
        mode: 'copy'

    input:
    path bams
    path gtf

    output:
    path "gene_counts.txt", emit: counts
    path "gene_counts.txt.summary", emit: summary

    script:
    """
    featureCounts \
        -T ${task.cpus} \
        -p \
        --countReadPairs \
        -s 0 \
        -t exon \
        -g gene_id \
        -a ${gtf} \
        -o gene_counts.txt \
        ${bams}
    """
}
