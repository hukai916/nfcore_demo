//
// Check input samplesheet and get read channels
//

params.options = [:]

include { CHECK_GEOSHEET } from '../../modules/local/check_geosheet' addParams( options: params.options )

workflow CHECK_GEO {
    take:
    samplesheet // file: /path/to/samplesheet.csv

    main:
    CHECK_GEOSHEET ( samplesheet )
        .splitCsv(header:false, sep:'\t')
        // .readLines() // only valid for file object or dataflow object
        .map { row -> "${row[0]}"}
        .unique()
        .set { geo }

    // geo = Channel.fromList(CHECK_GEOSHEET.out.geo.readLines())
        // ch_input = Channel
        //                 .fromList(file(params.geo).readLines())
        //                 .map { it.replaceAll("\\s","") }

    emit:
    geo
}
