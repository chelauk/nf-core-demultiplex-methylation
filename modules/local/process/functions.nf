def extract_fastq(tsvFile) {
    Channel.from(tsvFile)
        .splitCsv(sep: '\t')
        .map { row ->
            def meta = [:]
            meta.patient = row[0]
            meta.gender  = row[1]
            meta.status  = return_status(row[2].toInteger())
            meta.sample  = row[3]
            meta.run     = row[4]
            meta.id      = "${meta.sample}-${meta.run}"
            def read1    = return_file(row[5])
            def read2    = "null"
            if (has_extension(read1, "fastq.gz") || has_extension(read1, "fq.gz") || has_extension(read1, "fastq") || has_extension(read1, "fq")) {
                check_number_of_item(row, 7)
                read2 = return_file(row[6])
            if (!has_extension(read2, "fastq.gz") && !has_extension(read2, "fq.gz")  && !has_extension(read2, "fastq") && !has_extension(read2, "fq")) exit 1, "File: ${file2} has the wrong extension. See --help for more information"
            if (has_extension(read1, "fastq") || has_extension(read1, "fq") || has_extension(read2, "fastq") || has_extension(read2, "fq")) {
                exit 1, "We do recommend to use gziped fastq file to help you reduce your data footprint."
            }
        }
        else if (has_extension(read1, "bam")) check_number_of_item(row, 6)
        else exit 1, "No recognisable extention for input file: ${read1}"

        return [meta, [read1, read2]]
    }
}