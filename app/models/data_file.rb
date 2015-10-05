class DataFile < ActiveRecord::Base
  include SerializedAudit
  audited
  belongs_to :project
  belongs_to :parent, class_name: "Folder"
  belongs_to :upload
  has_many :project_permissions, through: :project

  validates :name, presence: true
  validates :project_id, presence: true
  validates :upload_id, presence: true

  validates_each :upload do |record, attr, value|
    record.errors.add(attr, 'upload cannot have an error') if value &&
      value.error_at
  end

  def virtual_path
    if parent
      [parent.virtual_path, self.name].join('/')
    else
      "/#{self.name}"
    end
  end
end
