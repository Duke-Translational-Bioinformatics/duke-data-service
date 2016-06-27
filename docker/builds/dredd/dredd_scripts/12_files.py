import dredd_hooks as hooks
import imp
import os
import json
import uuid
#if you want to import another module for use in this workflow
utils = imp.load_source("utils",os.path.join(os.getcwd(),'utils.py'))

###############################################################################
###############################################################################
#           Files
###############################################################################
############################################################################### 
@hooks.before("Files > Files collection > Create file")
@hooks.before("Files > File instance > View file")
@hooks.before("Files > File instance > Update file")
@hooks.before("Files > File instance > Delete file")
@hooks.before("Files > File instance > Get file download URL")
@hooks.before("Files > File instance > Move file")
@hooks.before("Files > File instance > Rename file")
def justPass12_1(transaction):
    utils.pass_this_endpoint(transaction)
