import dredd_hooks as hooks
import imp
import os
import json
import uuid
#if you want to import another module for use in this workflow
utils = imp.load_source("utils",os.path.join(os.getcwd(),'utils.py'))

###############################################################################
###############################################################################
#         Children Search
###############################################################################
############################################################################### 
@hooks.before("Search Children > Search project children > Search project children")
@hooks.before("Search Children > Search folder children > Search folder children")
def justPass14_1(transaction):
    utils.pass_this_endpoint(transaction)
