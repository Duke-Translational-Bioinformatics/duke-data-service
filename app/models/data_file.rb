# Folder and DataFile are siblings in the Container class through single table inheritance.

class DataFile < Container
  belongs_to :upload

  validates :project_id, presence: true
  validates :upload_id, presence: true

  validates_each :upload do |record, attr, value|
    record.errors.add(attr, 'upload cannot have an error') if value && value.error_at
  end

  def kind
    super('file')
  end
end
