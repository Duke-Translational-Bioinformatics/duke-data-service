import dredd_hooks as hooks
import imp
import os
import json
import uuid
#if you want to import another module for use in this workflow
utils = imp.load_source("utils",os.path.join(os.getcwd(),'utils.py'))

###############################################################################
###############################################################################
#           Provenance Activities
###############################################################################
############################################################################### 
@hooks.before("Provenance Activities > Activities collection > NOT_IMPLEMENTED Create activity")
@hooks.before("Provenance Activities > Activities collection > NOT_IMPLEMENTED List activities")
@hooks.before("Provenance Activities > Activities instance > NOT_IMPLEMENTED View activity")
@hooks.before("Provenance Activities > Activities instance > NOT_IMPLEMENTED Update activity")
@hooks.before("Provenance Activities > Activities instance > NOT_IMPLEMENTED Delete activity")
def justPass15_1(transaction):
    utils.pass_this_endpoint(transaction)
