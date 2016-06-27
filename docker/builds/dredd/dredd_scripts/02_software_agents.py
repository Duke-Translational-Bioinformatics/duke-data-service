import dredd_hooks as hooks
import imp
import os
import json
import uuid
#if you want to import another module for use in this workflow
utils = imp.load_source("utils",os.path.join(os.getcwd(),'utils.py'))

###############################################################################
###############################################################################
#           SOFTWARE AGENTS
###############################################################################
############################################################################### 
@hooks.after("Software Agents > Software Agents collection > Create software agent")
def get_sa_id03_1(transaction):
    global sa_id
    sa_id = json.loads(transaction[u'real'][u'body'])['id']
    print(sa_id)
@hooks.before("Software Agents > Software Agents collection > List software agents")
@hooks.before("Software Agents > Software Agent instance > View software agent")
@hooks.before("Software Agents > Software Agent instance > Update software agent")
def change_trans_id02_1(transaction):
    url = transaction['fullPath']
    transaction['fullPath'] = str(url).replace('9a4c28a2-ec18-40ed-b75c-3bf5b309715',sa_id)
@hooks.before("Software Agents > Software Agent instance > Delete software agent")
def create_a_del_sa(transaction):
    name = str(uuid.uuid4())
    neww = utils.create_a_sa(transaction,name)
    url = transaction['fullPath']
    transaction['fullPath'] = str(url).replace('9a4c28a2-ec18-40ed-b75c-3bf5b309715',neww['id'])
@hooks.before("Software Agents > Software Agent API Key > Generate software agent API key")
@hooks.before("Software Agents > Software Agent API Key > View software agent API key")
###NEED TO FURTHER QC THIS ENDPOINT
@hooks.before("Software Agents > Software Agent API Key > Delete software agent API key")
def change_trans_id02_2(transaction):
    url = transaction['fullPath']
    transaction['fullPath'] = str(url).replace('9a4c28a2-ec18-40ed-b75c-3bf5b309715',sa_id)
    print(transaction)
@hooks.before("Software Agents > Software Agent Access Token > Get software agent access token")
def gen_token02_1(transaction):
    saKey = utils.generate_sa_key(transaction,sa_id)
    userKey = utils.generate_user_key(transaction)
    print(saKey,userKey)
    requestBody = json.loads(transaction[u'request'][u'body'])
    requestBody['agent_key'] = saKey
    requestBody['user_key'] = userKey
    transaction[u'request'][u'body'] = json.dumps(requestBody)
