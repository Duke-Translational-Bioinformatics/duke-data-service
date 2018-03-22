class FileVersionSerializer < ActiveModel::Serializer
  include AuditSummarySerializer
  attributes :id, :kind, :version, :label, :is_deleted, :audit

  has_one :upload, serializer: UploadPreviewSerializer
  has_one :data_file, key: :file, serializer: DataFilePreviewSerializer

  def version
    object.version_number
  end
end
