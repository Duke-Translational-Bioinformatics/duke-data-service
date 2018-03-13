class FolderFilesResponseSerializer < ActiveModel::Serializer
  attribute :results
  attribute :aggs, if: -> { object.aggs }
end
