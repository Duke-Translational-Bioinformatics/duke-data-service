class DataFileSerializer < ActiveModel::Serializer
  def self.options_with_conditional(name, options)
    key = options[:key] || name
    except = {unless: "instance_options&.fetch(:except, nil)&.include?('#{key}'.to_sym)"}
    options.merge(except)
  end

  def self.attribute(name, options = {}, &block)
    super(name, options_with_conditional(name, options), &block)
  end

  def self.has_many(name, options = {}, &block)
    super(name, options_with_conditional(name, options), &block)
  end

  def self.has_one(name, options = {}, &block)
    super(name, options_with_conditional(name, options), &block)
  end

  def self.belongs_to(name, options = {}, &block)
    super(name, options_with_conditional(name, options), &block)
  end

  include AuditSummarySerializer
  attributes :kind, :id, :parent, :name, :audit, :is_deleted

  has_one :current_file_version, serializer: FileVersionPreviewSerializer, key: :current_version
  has_one :project, serializer: ProjectPreviewSerializer
  has_many :ancestors, serializer: AncestorSerializer

  def parent
    parent = object.parent || object.project
    { kind: parent.kind, id: parent.id }
  end

  def is_deleted
    object.is_deleted?
  end
end
