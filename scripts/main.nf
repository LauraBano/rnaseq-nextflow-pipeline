nextflow.enable.dsl=2

params.input = "${projectDir}/assets/samplesheet.csv"

workflow {

    samples_ch = Channel
        .fromPath(params.input)
        .splitCsv(header: true)

    samples_ch.view()
}