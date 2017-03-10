class Container < ActiveRecord::Base
  default_scope { order('created_at DESC') }
  include Kinded
  include RequestAudited

  include Elasticsearch::Model

  audited
  belongs_to :project
	belongs_to :parent, class_name: "Folder"
  has_many :project_permissions, through: :project
  has_many :tags, as: :taggable

  define_model_callbacks :set_parent_attribute
  validates :name, presence: true, unless: :is_deleted

  after_commit :create_elasticsearch_index, on: [:create]
  after_commit :update_elasticsearch_index, on: [:update]

  def ancestors
    if parent
      [parent.ancestors, parent].flatten
    else
      [project]
    end
  end

  def parent=(val)
    run_callbacks(:set_parent_attribute) do
      super(val)
    end
  end

  def parent_id=(val)
    run_callbacks(:set_parent_attribute) do
      super(val)
    end
  end

  def set_project_to_parent_project
    self.project = self.parent.project if self.parent
  end

  def update_elasticsearch_index
    ElasticsearchIndexJob.perform_later(self, update: true)
  end

  def create_elasticsearch_index
    ElasticsearchIndexJob.perform_later(self)
  end
end
