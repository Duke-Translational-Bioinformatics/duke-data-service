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
@hooks.before("Search Objects > Search Objects > Search Objects")
def skippy19_1(transaction):
    utils.skip_this_endpoint(transaction)
