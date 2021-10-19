// Import generic module functions
include { saveFiles; getSoftwareName } from './functions'

params.options = [:]

process SRA_IDS_TO_RUNINFO {
    tag "$id"
    label 'error_retry'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName(task.process), meta:[:], publish_by_meta:[]) }

    conda (params.enable_conda ? "conda-forge::python=3.9.5" : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/python:3.9--1"
    } else {
        container "quay.io/biocontainers/python:3.9--1"
    }

    input:
    val id
    val fields

    output:
    path "*.tsv", emit: tsv

    script:
    def metadata_fields = fields ? "--ena_metadata_fields ${fields}" : ''
    """
    echo $id > id.txt
    sra_ids_to_runinfo.py \\
        id.txt \\
        ${id}.runinfo.tsv \\
        $metadata_fields
    """
}
