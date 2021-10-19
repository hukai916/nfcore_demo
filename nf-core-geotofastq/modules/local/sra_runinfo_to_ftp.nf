// Import generic module functions
include { saveFiles; getSoftwareName } from './functions'

params.options = [:]

process SRA_RUNINFO_TO_FTP {
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
    path runinfo

    output:
    path "*.tsv"         , emit: tsv
    path  "*.version.txt", emit: version

    script:
    """
    sra_runinfo_to_ftp.py \\
        ${runinfo.join(',')} \\
        ${runinfo.toString().tokenize(".")[0]}.runinfo_ftp.tsv

    python --version | sed -e "s/Python //g" > python.version.txt
    """
}
