include { SPADES } from './modules/nf-core/spades/main'
include { KRAKEN2_KRAKEN2 } from './modules/nf-core/kraken2/kraken2/main'
 
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

    if(params.kraken_db){
	db_ch = channel.fromPath(params.kraken_db, checkIfExists: true)

	kraken_input_ch = SPADES.out.contigs
          .combine(db_ch)
	  .map { meta, contigs, db -> tuple( meta + [ single_end: true ], contigs, db) }

	// TODO: .multiMap will be legacy code as we move toward static typing, replace this later
	kraken_input_ch = kraken_input_ch.multiMap { meta, contigs, db ->
	  reads: tuple(meta, contigs)
	  db: db
	  save_output_fastqs: false
	  save_reads_assignment: true
	  }

	KRAKEN2_KRAKEN2(
	  kraken_input_ch.reads,
	  kraken_input_ch.db,
	  kraken_input_ch.save_output_fastqs,
	  kraken_input_ch.save_reads_assignment
	)
    }
}
