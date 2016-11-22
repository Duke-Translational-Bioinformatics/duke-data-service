import dredd_hooks as hooks
import imp
import os
import json
import uuid
#if you want to import another module for use in this workflow
utils = imp.load_source("utils",os.path.join(os.getcwd(),'utils.py'))

###############################################################################
###############################################################################
#           PROJECT ROLES
###############################################################################
###############################################################################
@hooks.before("Project Roles > Project Roles collection > List project roles")
@hooks.before("Project Roles > Project Role instance > View project role")
def skippy07_1(transaction):
    pass
