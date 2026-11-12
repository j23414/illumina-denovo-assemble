include { SPADES } from './modules/nf-core/spades/main'

workflow {
    main:
    // Load illumina reads
    if (params.samplesheet) {
      reads_ch = channel.fromPath(params.samplesheet)
        | splitCsv(header: true)
        | map { row ->
            tuple([id: row.sample], [file(row.R1), file(row.R2)])
          }
    } else if (params.reads) {
        reads_ch = channel.fromFilePairs(params.reads, checkIfExists: true)
          | map { name, reads -> tuple([id: name], reads) }
    } else {
        error "Please specify either --samplesheet samplesheet.csv or --reads 'data/*_{R1,R2}.fastq.gz'"
    }

    SPADES(
	reads_ch.map{meta, illumina -> tuple(meta, illumina, [], [])},
	reads_ch.map{_meta, _illumina -> []},
	reads_ch.map{_meta, _illumina -> []}
    )
    SPADES.out.contigs
    .map { meta, contigs -> "${meta.id},spades/${contigs.fileName}" }
    .collectFile(
      name: "${params.outdir}/processed_samplesheet.csv",
      seed: "sample,contigs",
      newLine: true,
    )
}
