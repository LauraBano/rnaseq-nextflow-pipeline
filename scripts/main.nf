/* Especificar la arquitectura (DSL2) del lenguaje de programación Groovy */
nextflow.enable.dsl=2

/* Importar los módulos .nf */
include { FASTQC as FASTQC_RAW } from './modules/fastqc'
include { FASTQC as FASTQC_TRIMMED } from './modules/fastqc'
include { TRIMMOMATIC } from './modules/trimmomatic'


/* Especificar las rutas para inputs y outputs */
params.input = "${projectDir}/assets/samplesheet.csv"
params.fastq_dir = "${projectDir}/../data/fastq"
params.outdir = "${projectDir}/../results"


/* Crear los canales y orquestar los procesos en un flujo de trabajo general */
workflow {

    /* Crea un canal por cada fila del archivo de muestras */
    samples_ch = Channel
        .fromPath(params.input, checkIfExists: true) /* Busca en la ruta de input y comprueba que existe el archivo de muestras */
        .splitCsv(header: true) /* Divide cada fila del .csv y la convierte en un canal */
        .map { row -> /*  */

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

    FASTQC_RAW(samples_ch)

    TRIMMOMATIC(samples_ch)

    FASTQC_TRIMMED(TRIMMOMATIC.out.paired)

    FASTQC_TRIMMED.out.zip.view { meta, files ->
    "POST-TRIM FASTQC: ${meta.id} | ${files*.name}"
    }
}