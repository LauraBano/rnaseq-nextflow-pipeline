process STAR_ALIGN {

    tag "${meta.id}"

    container "quay.io/biocontainers/star:2.7.11b--h5ca1c30_8"

    publishDir "${params.outdir}/star/alignment",
        mode: 'symlink'

    input:
    tuple val(meta), path(reads)
    path index

    output:
    tuple val(meta), path("${meta.id}_Aligned.out.bam"), emit: bam
    tuple val(meta), path("${meta.id}_Log.final.out"), emit: log

    script:
    def r1 = reads[0]
    def r2 = reads[1]

    """
    STAR \
        --runThreadN ${task.cpus} \
        --genomeDir ${index} \
        --readFilesIn ${r1} ${r2} \
        --readFilesCommand zcat \
        --outSAMtype BAM Unsorted \
        --outSAMattrRGline \
            ID:${meta.sra} \
            SM:${meta.id} \
            PL:ILLUMINA \
        --outFileNamePrefix ${meta.id}_ 
    """
}