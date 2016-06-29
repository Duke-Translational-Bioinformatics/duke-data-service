class DataFilePreviewSerializer < ActiveModel::Serializer
  attributes :id, :name

  has_one :project, serializer: ProjectPreviewSerializer
end
