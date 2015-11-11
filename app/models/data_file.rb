# Folder and DataFile are siblings in the Container class through single table inheritance.

class DataFile < Container
  belongs_to :upload

  validates :project_id, presence: true
  validates :upload_id, presence: true

  validates_each :upload, :upload_id do |record, attr, value|
    if record.upload
      if record.upload.error_at
        record.errors.add(attr, 'cannot have an error')
      elsif !record.upload.completed_at
        record.errors.add(attr, 'must be completed successfully')
      end
    end
  end

  def kind
    super('file')
  end
end
