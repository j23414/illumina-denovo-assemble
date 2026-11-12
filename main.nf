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
}
