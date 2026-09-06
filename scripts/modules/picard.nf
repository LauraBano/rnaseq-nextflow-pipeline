process PICARD {

    tag "${meta.id}"

    container "quay.io/biocontainers/picard:3.4.0--hdfd78af_0"

    publishDir "${params.outdir}/picard",
        mode: 'symlink'

    input:
    tuple val(meta), path(bam), path(bai)

    output:
    tuple val(meta),
        path("${meta.id}_marked_duplicates.bam"),
        emit: bam

    tuple val(meta),
        path("${meta.id}_duplication_metrics.txt"),
        emit: metrics

    script:
    """
    picard MarkDuplicates \
        INPUT=${bam} \
        OUTPUT=${meta.id}_marked_duplicates.bam \
        METRICS_FILE=${meta.id}_duplication_metrics.txt \
        REMOVE_DUPLICATES=false \
        READ_NAME_REGEX=null
    """
}