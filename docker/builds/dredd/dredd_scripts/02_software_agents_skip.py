import dredd_hooks as hooks
import imp
import os
import json
import uuid


###############################################################################
###############################################################################
#           SOFTWARE AGENTS
###############################################################################
###############################################################################
@hooks.before("Software Agents > Software Agents collection > Create software agent")
@hooks.before("Software Agents > Software Agents collection > List software agents")
@hooks.before("Software Agents > Software Agent instance > View software agent")
@hooks.before("Software Agents > Software Agent instance > Update software agent")
@hooks.before("Software Agents > Software Agent instance > Delete software agent")
@hooks.before("Software Agents > Software Agent API Key > Generate software agent API key")
@hooks.before("Software Agents > Software Agent API Key > View software agent API key")
@hooks.before("Software Agents > Software Agent API Key > Delete software agent API key")
@hooks.before("Software Agents > Software Agent Access Token > Get software agent access token")
def skippewn(transaction):
    transaction['skip'] = True
