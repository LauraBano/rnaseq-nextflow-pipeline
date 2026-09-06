process SAMTOOLS {

    tag "${meta.id}"

    container "quay.io/biocontainers/samtools:1.21--h50ea8bc_0"

    publishDir "${params.outdir}/samtools",
        mode: 'symlink'

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta),
        path("${meta.id}_sorted.bam"),
        path("${meta.id}_sorted.bam.bai"),
        emit: bam

    tuple val(meta),
        path("${meta.id}_flagstat.txt"),
        emit: flagstat

    tuple val(meta),
        path("${meta.id}_idxstats.txt"),
        emit: idxstats

    script:
    """
    samtools sort \
        -@ ${task.cpus} \
        -o ${meta.id}_sorted.bam \
        ${bam}

    samtools index \
        -@ ${task.cpus} \
        ${meta.id}_sorted.bam

    samtools flagstat \
        -@ ${task.cpus} \
        ${meta.id}_sorted.bam \
        > ${meta.id}_flagstat.txt

    samtools idxstats \
        ${meta.id}_sorted.bam \
        > ${meta.id}_idxstats.txt
    """
}