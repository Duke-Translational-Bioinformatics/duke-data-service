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
@hooks.before("Project Transfer > Project Transfer collection > NOT_IMPLEMENTED_NEW Initiate a project transfer")
@hooks.before("Project Transfer > Project Transfer collection > NOT_IMPLEMENTED_NEW List project transfers")
@hooks.before("Project Transfer > Project Transfer instance > NOT_IMPLEMENTED_NEW View a project transfer")
@hooks.before("Project Transfer > Project Transfer instance > NOT_IMPLEMENTED_NEW Accept a project transfer")
@hooks.before("Project Transfer > Project Transfer instance > NOT_IMPLEMENTED_NEW Reject a project transfer")
@hooks.before("Project Transfer > Project Transfer instance > NOT_IMPLEMENTED_NEW Cancel a project transfer")
@hooks.before("Project Transfer > View All Project Transfers > NOT_IMPLEMENTED_NEW View All Project Transfers")
def skippy20_1(transaction):
    utils.skip_this_endpoint(transaction)
