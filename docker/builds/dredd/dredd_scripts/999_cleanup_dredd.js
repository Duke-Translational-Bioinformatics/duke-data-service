from dataservice.config import create_config
from dataservice.core.remotestore import RemoteStore
from dataservice.core.ddsapi import DataServiceApi
config = create_config()

remote_store = RemoteStore(config)
all_projs = remote_store.get_project_names()
del_projs = list(filter(('QDACT').__ne__, all_projs))

[remote_store.delete_project_by_name(x) for x in del_projs]
