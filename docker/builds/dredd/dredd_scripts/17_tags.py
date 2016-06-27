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
@hooks.before("Tags > Tags collection > NOT_IMPLEMENTED Create object tag")
@hooks.before("Tags > Tags collection > NOT_IMPLEMENTED List object tags")
@hooks.before("Tags > Tags collection > NOT_IMPLEMENTED List tag labels")
@hooks.before("Tags > Tag instance > NOT_IMPLEMENTED View tag")
@hooks.before("Tags > Tag instance > NOT_IMPLEMENTED Delete tag")
def skippy17_1(transaction):
    utils.skip_this_endpoint(transaction)
