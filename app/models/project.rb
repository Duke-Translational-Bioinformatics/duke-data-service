class Project < ActiveRecord::Base
  default_scope { order('created_at DESC') }
  include Kinded
  include ChildMinder
  include JobTransactionable
  include UnRestorable
  audited

  belongs_to :creator, class_name: "User"
  has_many :folders
  has_many :project_permissions
  has_many :uploads
  has_many :affiliations
  has_many :data_files
  has_many :children, -> { where parent_id: nil }, class_name: "Container", autosave: true
  has_many :containers

  validates :name, presence: true, unless: :is_deleted
  validates :description, presence: true, unless: :is_deleted
  validates :creator_id, presence: true, unless: :is_deleted
  validates :slug, uniqueness: {allow_blank: true}, format: {with: /\A[a-z0-9_]*\z/}
  validates :is_deleted, immutable: true, if: :was_deleted?

  before_validation :generate_slug, if: :slug_is_blank?
  after_create :set_project_admin
  after_create :initialize_storage
  after_update :manage_container_index_project

  def was_deleted?
    will_save_change_to_is_deleted? && !is_deleted
  end

  def set_project_admin
    project_admin_role = AuthRole.where(id: 'project_admin').first
    if project_admin_role
      last_audit = self.audits.last
      pp = self.project_permissions.create(
        user: self.creator,
        auth_role: project_admin_role,
        audit_comment: last_audit.comment
      )
      pp
    end
  end

  def initialize_storage
    storage_provider = StorageProvider.default
    ProjectStorageProviderInitializationJob.perform_later(
      job_transaction: ProjectStorageProviderInitializationJob.initialize_job(self),
      storage_provider: storage_provider,
      project: self
    )
  end

  def manage_container_index_project
    if will_save_change_to_name?
      if containers.count > 0
        (1..paginated_containers.total_pages).each do |page|
          ProjectContainerElasticsearchUpdateJob.perform_later(
            ProjectContainerElasticsearchUpdateJob.initialize_job(self),
            self,
            page
          )
        end
      end
    end
  end

  def update_container_elasticsearch_index_project(page)
    bulk_request = paginated_containers(page).map {|container|
      { update:
        {
          _index: container.__elasticsearch__.index_name,
          _type: container.__elasticsearch__.document_type,
          _id: container.__elasticsearch__.id,
          data: {
            doc: {
              project: ProjectPreviewSerializer.new(self).as_json,
              ancestors: container.ancestors.map{ |a|
                AncestorSerializer.new(a).as_json
              }
            }
          }
        }
      }
    }
    bulk_response = Elasticsearch::Model.client.bulk(
      body: bulk_request
    )
    Elasticsearch::Model.client.indices.flush
    if bulk_response["errors"]
      logger.info "Page #{page} has errors:"
      bulk_response["items"].select {|item|
        item["update"]["status"] >= 400
      }.map {|i|
        logger.info "#{i["update"]["_id"]} #{i["update"]["status"]} #{i["update"]["response"]}"
      }
    end
  end

  def slug_is_blank?
    slug.blank?
  end

  def generate_slug
    self.slug = slug_prefix = name.gsub('-','_').parameterize(separator: '_')
    self.slug = '_' if slug_is_blank?
    if invalid? && errors.details[:slug].any? {|x| x[:error]==:taken}
      existing_slugs = self.class.where("slug LIKE '#{slug_prefix}_%'").pluck(:slug)
      mock_slugs = (1..existing_slugs.length + 1).to_a.collect {|i| "#{slug_prefix}_#{i}"}
      self.slug = (mock_slugs - existing_slugs).first
      valid?
    end
    self.slug
  end

  def restore(child)
    raise IncompatibleParentException.new("#{kind} #{id} is permenantly deleted, and cannot restore children.::Restore to a different project.") if is_deleted?
    raise IncompatibleParentException.new("Projects can only restore dds-file or dds-folder objects.::Perhaps you mistyped the object_kind.") unless child.is_a? Container
    child.restore_from_trashbin self
  end

  private

  def paginated_containers(page=1)
    containers.page(page).per(Rails.application.config.max_children_per_job)
  end
end
