class Search::FolderSerializer < FolderSerializer
  attributes :kind, :id, :parent, :name, :is_deleted, :audit
end
