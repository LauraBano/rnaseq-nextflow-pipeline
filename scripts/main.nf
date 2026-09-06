/* Especificar la arquitectura (DSL2) del lenguaje de programación Groovy */
nextflow.enable.dsl=2

/* Importar los módulos .nf */
include { FASTQC as FASTQC_RAW } from './modules/fastqc'
include { FASTQC as FASTQC_TRIMMED } from './modules/fastqc'
include { TRIMMOMATIC } from './modules/trimmomatic'
include { STAR_INDEX } from './modules/star_index'
include { STAR_ALIGN } from './modules/star_align'
include { SAMTOOLS } from './modules/samtools'
include { PICARD } from './modules/picard'
include { FEATURECOUNTS } from './modules/featurecounts'
include { MULTIQC } from './modules/multiqc'
include { R_EXPLORATORY } from './modules/r_exploratory'

/* Especificar las rutas para inputs y outputs */
params.input = "${projectDir}/assets/samplesheet.csv"
params.fastq_dir = "${projectDir}/../data/fastq"
params.outdir = "${projectDir}/../results"
params.genome = "${projectDir}/../data/genome/GRCh38.fa"
params.gtf = "${projectDir}/../data/genome/GRCh38.gtf"
/* Parámetro recomendado para STAR_INDEX y calculado a partir del timming: maxlength -1 -> 63 - 1 = 62 */
params.sjdb_overhang = 62

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

    FASTQC_RAW(samples_ch)

    TRIMMOMATIC(samples_ch)

    FASTQC_TRIMMED(TRIMMOMATIC.out.paired)

    /* Generar una tupla con genoma de referencia + gtf */ 
    reference = tuple(
        file(params.genome, checkIfExists: true),
        file(params.gtf, checkIfExists: true),
        params.sjdb_overhang
    )

    STAR_INDEX(reference)

    STAR_ALIGN(
        TRIMMOMATIC.out.paired,
        STAR_INDEX.out.index
    )

    SAMTOOLS(STAR_ALIGN.out.bam)

    PICARD(SAMTOOLS.out.bam)

    counts_bams_ch = PICARD.out.bam
        .map { meta, bam -> bam }
        .collect()

    FEATURECOUNTS(
        counts_bams_ch,
        file(params.gtf, checkIfExists: true)
    )

    R_EXPLORATORY(
        FEATURECOUNTS.out.counts,
        file(params.input, checkIfExists: true),
        file(
            "${projectDir}/bin/rnaseq_exploratory.R",
            checkIfExists: true
        )
    )

    multiqc_inputs_ch = FASTQC_RAW.out.zip
        .map { meta, files -> files }
        .mix(
            FASTQC_TRIMMED.out.zip
                .map { meta, files -> files }
        )
        .mix(
            TRIMMOMATIC.out.log
                .map { meta, file -> file }
        )
        .mix(
            STAR_ALIGN.out.log
                .map { meta, file -> file }
        )
        .mix(
            SAMTOOLS.out.flagstat
                .map { meta, file -> file }
        )
        .mix(
            SAMTOOLS.out.idxstats
                .map { meta, file -> file }
        )
        .mix(
            PICARD.out.metrics
                .map { meta, file -> file }
        )
        .mix(
            FEATURECOUNTS.out.summary
        )
        .flatten()
        .collect()
    
    MULTIQC(multiqc_inputs_ch)
}