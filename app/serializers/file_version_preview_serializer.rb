class FileVersionPreviewSerializer < ActiveModel::Serializer
  attributes :id, :version, :label 

  has_one :upload, serializer: UploadPreviewSerializer

  def version
    object.version_number
  end
end
