import dredd_hooks as hooks
import imp
import os
import json
import uuid
#if you want to import another module for use in this workflow
utils = imp.load_source("utils",os.path.join(os.getcwd(),'utils.py'))

###############################################################################
###############################################################################
#           Folders
###############################################################################
############################################################################### 
@hooks.before("Folders > Folders collection > Create folder")
@hooks.before("Folders > Folder instance > View folder")
@hooks.before("Folders > Folder instance > Delete folder")
@hooks.before("Folders > Folder instance > Move folder")
@hooks.before("Folders > Folder instance > Rename folder")
def skippy10_1(transaction):
    utils.pass_this_endpoint(transaction)