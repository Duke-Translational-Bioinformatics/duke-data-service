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

@hooks.before("Authentication Providers > Authentication Providers collection > NOT_IMPLEMENTED_NEW List authentication providers")
@hooks.before("Authentication Providers > Authentication Provider instance > NOT_IMPLEMENTED_NEW View authentication provider")
@hooks.before("Authentication Providers > Authentication Provider instance > NOT_IMPLEMENTED_NEW Get All Authentication Provider Affiliates")
@hooks.before("Authentication Providers > Authentication Provider instance > NOT_IMPLEMENTED_NEW View User by Auth Provider ID")
def skippy21_1(transaction):
    utils.skip_this_endpoint(transaction)
