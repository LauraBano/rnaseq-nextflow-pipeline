process TRIMMOMATIC {

    tag "${meta.id}"

    container "quay.io/biocontainers/trimmomatic:0.41--hdfd78af_0"

    publishDir "${params.outdir}/trimmomatic",
        mode: 'symlink'

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta),
        path("${meta.sra}_[12]_paired.fastq.gz"),
        emit: paired

    tuple val(meta),
        path("${meta.sra}_[12]_unpaired.fastq.gz"),
        emit: unpaired

    tuple val(meta),
        path("${meta.id}_trimmomatic.log"),
        emit: log

    script:

    def r1 = reads[0]
    def r2 = reads[1]

    """
    trimmomatic PE \
        -threads ${task.cpus} \
        -phred33 \
        ${r1} \
        ${r2} \
        ${meta.sra}_1_paired.fastq.gz \
        ${meta.sra}_1_unpaired.fastq.gz \
        ${meta.sra}_2_paired.fastq.gz \
        ${meta.sra}_2_unpaired.fastq.gz \
        ILLUMINACLIP:/usr/local/share/trimmomatic/adapters/TruSeq3-PE-2.fa:2:30:10 \
        LEADING:3 \
        TRAILING:3 \
        SLIDINGWINDOW:4:15 \
        MINLEN:36 \
        2> ${meta.id}_trimmomatic.log
    """
}