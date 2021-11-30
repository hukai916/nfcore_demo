//
// Check input samplesheet and get read channels
//

params.options = [:]

include { CHECK_SAMPLESHEET } from '../../modules/local/check_samplesheet' addParams( options: params.options )

workflow CHECK_INPUT {
    take:
    samplesheet // file: /path/to/samplesheet.csv

    main:
    CHECK_SAMPLESHEET ( samplesheet )
        .splitCsv(header:true, sep:'\t')
        .unique()
        .map { create_fastq_channels(it) }
        .set { reads }

    emit:
    reads // channel: [ val(meta), [ reads ] ]
}

// Function to get list of [ meta, [ fastq_1, fastq_2 ] ]
def create_fastq_channels(LinkedHashMap row) {
    def meta = [:]
    meta.id           = row.id
    meta.single_end   = row.single_end.toBoolean()
    meta.md5_1        = row.md5_1
    meta.md5_2        = row.md5_2

    def array = []
    array = [ meta, [ row.fastq_1, row.fastq_2 ] ]

    return array
}
