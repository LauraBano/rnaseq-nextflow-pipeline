process STAR_INDEX {

    tag "GRCh38"

    container "quay.io/biocontainers/star:2.7.11b--h5ca1c30_8"

    publishDir "${params.outdir}/star",
        mode: 'symlink'

    input:
    tuple path(fasta), path(gtf), val(sjdb_overhang)

    output:
    path "index", emit: index

    script:
    """
    mkdir -p index

    STAR \
        --runMode genomeGenerate \
        --runThreadN ${task.cpus} \
        --genomeDir index \
        --genomeFastaFiles ${fasta} \
        --sjdbGTFfile ${gtf} \
        --sjdbOverhang ${sjdb_overhang} \
        --genomeSAsparseD 3 \
        --genomeSAindexNbases 12 \
        --limitGenomeGenerateRAM 15000000000
    """
}