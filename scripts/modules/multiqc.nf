process MULTIQC {

    tag "report"

    container "quay.io/biocontainers/multiqc:1.35--pyhdfd78af_1"

    publishDir "${params.outdir}",
        mode: 'copy'

    input:
    path qc_files

    output:
    path "multiqc_report.html", emit: report
    path "multiqc_report_data", emit: data

    script:
    """
    multiqc \
        --force \
        --filename multiqc_report.html \
        --outdir . \
        .
    """
}
