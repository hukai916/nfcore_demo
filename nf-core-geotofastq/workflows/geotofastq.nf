/*
========================================================================================
    VALIDATE INPUTS
========================================================================================
*/

def summary_params = NfcoreSchema.paramsSummaryMap(workflow, params)

// Validate input parameters
// WorkflowGeotofastq.initialise(params, log)

// TODO nf-core: Add all file path parameters for the pipeline to the list below
// Check input path parameters to see if they exist
def checkPathParamList = [ params.input, params.multiqc_config, params.fasta ]
for (param in checkPathParamList) { if (param) { file(param, checkIfExists: true) } }

// Check mandatory parameters
// if (params.input) { ch_input = file(params.input) } else { exit 1, 'Input samplesheet not specified!' }

/*
========================================================================================
    CONFIG FILES
========================================================================================
*/

ch_multiqc_config        = file("$projectDir/assets/multiqc_config.yaml", checkIfExists: true)
ch_multiqc_custom_config = params.multiqc_config ? Channel.fromPath(params.multiqc_config) : Channel.empty()

/*
========================================================================================
    IMPORT LOCAL MODULES/SUBWORKFLOWS
========================================================================================
*/

// Don't overwrite global params.modules, create a copy instead and use that within the main script.
def modules = params.modules.clone()

//
// MODULE: Local to the pipeline
//
include { GET_SOFTWARE_VERSIONS } from '../modules/local/get_software_versions' addParams( options: [publish_files : ['tsv':'']] )

//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//
include { INPUT_CHECK } from '../subworkflows/local/input_check' addParams( options: [:] )

/*
========================================================================================
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
========================================================================================
*/

def multiqc_options   = modules['multiqc']
multiqc_options.args += params.multiqc_title ? Utils.joinModuleArgs(["--title \"$params.multiqc_title\""]) : ''

// MODULE: Installed directly from nf-core/modules
include { FASTQC  } from '../modules/nf-core/modules/fastqc/main'  addParams( options: modules['fastqc'] )
include { MULTIQC } from '../modules/nf-core/modules/multiqc/main' addParams( options: multiqc_options   )
include { CUTADAPT } from '../modules/nf-core/modules/cutadapt/main'

// MODULE: Copied from nf-core/fetchngs
include { SRA_IDS_TO_RUNINFO } from '../modules/local/sra_ids_to_runinfo'
include { SRA_RUNINFO_TO_FTP } from '../modules/local/sra_runinfo_to_ftp'
include { SRA_FASTQ_FTP } from '../modules/local/sra_fastq_ftp'

// MODULE: Custom modules
include { MERGE_TSV } from '../modules/local/merge_tsv'

/*
========================================================================================
    RUN MAIN WORKFLOW
========================================================================================
*/

// Info required for completion email and summary
def multiqc_report = []

workflow GEOTOFASTQ {

    ch_software_versions = Channel.empty()

    if (params.geo) {
      log.info "GEO ID supplied, will retrieve sample sheet."
      ch_input = Channel
                      .fromList(file(params.geo).readLines())
                      .map { it.replaceAll("\\s","") }

      SRA_IDS_TO_RUNINFO(ch_input, false)
      SRA_RUNINFO_TO_FTP(SRA_IDS_TO_RUNINFO.out.tsv)

      // Merge all unique samples:
      MERGE_TSV(SRA_RUNINFO_TO_FTP
                    .out
                    .tsv
                    .collect()
                )
    } else if (params.input) {
      log.info "Samplesheet supplied, will download fastq files."
      ch_sra_reads = Channel
                    .fromPath(params.input)
                    .splitCsv(header:true, sep:'\t')
                    .map {
                        meta ->
                        meta.single_end = meta.single_end.toBoolean()
                        [ meta, [ meta.fastq_1, meta.fastq_2 ] ]
                    }
                    .unique()

      SRA_FASTQ_FTP(ch_sra_reads)

      FASTQC(SRA_FASTQ_FTP.out.fastq)

      CUTADAPT(SRA_FASTQ_FTP.out.fastq)
    } else {
      exit 1, 'Pls supply either GEO id text file (--geo) or samplesheet tsv file (--input)!'
    }

    //
    // SUBWORKFLOW: Read in samplesheet, validate and stage input files
    //
    // INPUT_CHECK (
    //     ch_input
    // )
    //
    // //
    // // MODULE: Run FastQC
    // //
    // FASTQC (
    //     INPUT_CHECK.out.reads
    // )
    // ch_software_versions = ch_software_versions.mix(FASTQC.out.version.first().ifEmpty(null))

    //
    // MODULE: Pipeline reporting
    //
    ch_software_versions
        .map { it -> if (it) [ it.baseName, it ] }
        .groupTuple()
        .map { it[1][0] }
        .flatten()
        .collect()
        .set { ch_software_versions }

    GET_SOFTWARE_VERSIONS (
        ch_software_versions.map { it }.collect()
    )

    //
    // MODULE: MultiQC
    //
    workflow_summary    = WorkflowGeotofastq.paramsSummaryMultiqc(workflow, summary_params)
    ch_workflow_summary = Channel.value(workflow_summary)

    ch_multiqc_files = Channel.empty()
    ch_multiqc_files = ch_multiqc_files.mix(Channel.from(ch_multiqc_config))
    ch_multiqc_files = ch_multiqc_files.mix(ch_multiqc_custom_config.collect().ifEmpty([]))
    ch_multiqc_files = ch_multiqc_files.mix(ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    ch_multiqc_files = ch_multiqc_files.mix(GET_SOFTWARE_VERSIONS.out.yaml.collect())
    if (params.input) {
      ch_multiqc_files = ch_multiqc_files.mix(FASTQC.out.zip.collect{it[1]}.ifEmpty([]))
      ch_multiqc_files = ch_multiqc_files.mix(CUTADAPT.out.log.collect{it[1]}.ifEmpty([]))
    }

    MULTIQC (
        ch_multiqc_files.collect()
    )
    multiqc_report       = MULTIQC.out.report.toList()
    ch_software_versions = ch_software_versions.mix(MULTIQC.out.version.ifEmpty(null))
}

/*
========================================================================================
    COMPLETION EMAIL AND SUMMARY
========================================================================================
*/

workflow.onComplete {
    if (params.email || params.email_on_fail) {
        NfcoreTemplate.email(workflow, params, summary_params, projectDir, log, multiqc_report)
    }
    NfcoreTemplate.summary(workflow, params, log)
}

/*
========================================================================================
    THE END
========================================================================================
*/
