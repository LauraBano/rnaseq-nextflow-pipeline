nextflow.enable.dsl=2


params.input = "${projectDir}/assets/samplesheet.csv"

params.fastq_dir = "${projectDir}/../data/fastq"


workflow {

    samples_ch = Channel
        .fromPath(params.input, checkIfExists: true)
        .splitCsv(header: true)
        .map { row ->

            def meta = [
                id: row.sample_id,
                donor: row.donor,
                condition: row.condition,
                sra: row.sra
            ]

            def reads = [
                file(
                    "${params.fastq_dir}/${row.sra}_1.fastq.gz",
                    checkIfExists: true
                ),
                file(
                    "${params.fastq_dir}/${row.sra}_2.fastq.gz",
                    checkIfExists: true
                )
            ]

            tuple(meta, reads)
        }

    samples_ch.view { meta, reads ->
        "${meta.id} | ${meta.donor} | ${meta.condition} | ${reads*.name}"
    }
}