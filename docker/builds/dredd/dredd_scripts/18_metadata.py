import dredd_hooks as hooks
import imp
import os
import json
import uuid
#if you want to import another module for use in this workflow
utils = imp.load_source("utils",os.path.join(os.getcwd(),'utils.py'))

###############################################################################
###############################################################################
#           Tags
###############################################################################
###############################################################################
@hooks.before("Properties > Metadata Templates collection > NOT_IMPLEMENTED_NEW Create metadata template")
@hooks.before("Properties > Metadata Templates collection > NOT_IMPLEMENTED_NEW List metadata templates")
@hooks.before("Properties > Metadata Template instance > NOT_IMPLEMENTED_NEW View metadata template")
@hooks.before("Properties > Metadata Template instance > NOT_IMPLEMENTED_NEW Update metadata template")
@hooks.before("Properties > Metadata Template instance > NOT_IMPLEMENTED_NEW Delete metadata template")
@hooks.before("Properties > Metadata Template Properties collection > NOT_IMPLEMENTED_NEW Create metadata template property")
@hooks.before("Properties > Metadata Template Properties collection > NOT_IMPLEMENTED_NEW List metadata template properties")
@hooks.before("Properties > Metadata Template Property instance > NOT_IMPLEMENTED_NEW View metadata template property")
@hooks.before("Properties > Metadata Template Property instance > NOT_IMPLEMENTED_NEW Update metadata template property")
@hooks.before("Properties > Metadata Template Property instance > NOT_IMPLEMENTED_NEW Delete metadata template property")
@hooks.before("Properties > Object Metadata Template instance > NOT_IMPLEMENTED_NEW Create/Update object metatdata template")
@hooks.before("Properties > Object Metadata Template instance > NOT_IMPLEMENTED_NEW View object metadata template")
def skippy18_1(transaction):
    utils.skip_this_endpoint(transaction)
