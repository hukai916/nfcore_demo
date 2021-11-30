#!/usr/bin/env nextflow
/*
========================================================================================
    nf-core/geotofastq
========================================================================================
    Github : https://github.com/nf-core/geotofastq
    Website: https://nf-co.re/geotofastq
    Slack  : https://nfcore.slack.com/channels/geotofastq
----------------------------------------------------------------------------------------
*/

nextflow.enable.dsl = 2

/*
========================================================================================
    VALIDATE & PRINT PARAMETER SUMMARY
========================================================================================
*/

WorkflowMain.initialise(workflow, params, log)

/*
========================================================================================
    NAMED WORKFLOW FOR PIPELINE
========================================================================================
*/

include { GEOTOFASTQ } from './workflows/geotofastq'

//
// WORKFLOW: Run main nf-core/geotofastq analysis pipeline
//
workflow NFCORE_GEOTOFASTQ {
    GEOTOFASTQ ()
}

/*
========================================================================================
    RUN ALL WORKFLOWS
========================================================================================
*/

//
// WORKFLOW: Execute a single named workflow for the pipeline
// See: https://github.com/nf-core/rnaseq/issues/619
//
workflow {
    NFCORE_GEOTOFASTQ ()
}

/*
========================================================================================
    THE END
========================================================================================
*/
