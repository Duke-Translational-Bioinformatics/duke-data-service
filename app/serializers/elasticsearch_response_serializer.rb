class ElasticsearchResponseSerializer < ActiveModel::Serializer
  def self.serializer_for(model, options)
    return DataFileSerializer if model.is_a? DataFile
    return FolderSerializer if model.is_a? Folder
    super
  end

  has_many :results
end
