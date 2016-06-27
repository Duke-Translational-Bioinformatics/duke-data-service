import dredd_hooks as hooks
import imp
import os
import json
import uuid
#if you want to import another module for use in this workflow
utils = imp.load_source("utils",os.path.join(os.getcwd(),'utils.py'))

###############################################################################
###############################################################################
#           Folders Versions
###############################################################################
############################################################################### 
@hooks.before("File Versions > File Versions collection > List file versions")
@hooks.before("File Versions > File Version instance > View file version")
@hooks.before("File Versions > File Version instance > Update file version")
@hooks.before("File Versions > File Version instance > Delete file version")
@hooks.before("File Versions > File Version instance > Get file version download URL")
def justPass13_1(transaction):
    utils.pass_this_endpoint(transaction)