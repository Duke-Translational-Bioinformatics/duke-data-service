import dredd_hooks as hooks
import imp
import os
import json
import uuid
#if you want to import another module for use in this workflow
utils = imp.load_source("utils",os.path.join(os.getcwd(),'utils.py'))

###############################################################################
###############################################################################
#           Provenance Relations
###############################################################################
############################################################################### 
@hooks.before("Provenance Relations > Relations collection > NOT_IMPLEMENTED Create used relation")
@hooks.before("Provenance Relations > Relations collection > NOT_IMPLEMENTED Create generated relation")
@hooks.before("Provenance Relations > Relations collection > NOT_IMPLEMENTED List provenance relations")
@hooks.before("Provenance Relations > Relation instance > NOT_IMPLEMENTED View relation")
@hooks.before("Provenance Relations > Relation instance > NOT_IMPLEMENTED Delete relation")
def justPass16_1(transaction):
    utils.pass_this_endpoint(transaction)
@hooks.before("Search Provenance > NOT_IMPLEMENTED Search Provenance > NOT_IMPLEMENTED Search Provenance")
def skippy16_2(transaction):
    utils.skip_this_endpoint(transaction)
