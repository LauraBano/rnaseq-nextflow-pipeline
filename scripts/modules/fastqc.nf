process FASTQC {

    tag "${meta.id}"

    container "quay.io/biocontainers/fastqc:0.12.1--hdfd78af_0"

    publishDir "${params.outdir}/fastqc",
        mode: 'copy',
        saveAs: { filename ->
            filename.contains('_paired_fastqc') ?
            "trimmed/${filename}" :
            "raw/${filename}"
    }

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*_fastqc.html"), emit: html
    tuple val(meta), path("*_fastqc.zip"),  emit: zip

    script:
    """
    fastqc \
        --threads ${task.cpus} \
        ${reads}
    """
}