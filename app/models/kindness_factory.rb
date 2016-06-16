class KindnessFactory
  @@kinded_models = [
    Activity,
    User,
    FileVersion,
    Project,
    DataFile,
    Folder,
    AssociatedWithUserProvRelation,
    AssociatedWithSoftwareAgentProvRelation,
    AttributedToUserProvRelation,
    AttributedToSoftwareAgentProvRelation,
    DerivedFromFileVersionProvRelation,
    GeneratedByActivityProvRelation,
    InvalidatedByActivityProvRelation,
    SoftwareAgent,
    UsedProvRelation
  ]

  def self.kinded_models
    @@kinded_models
  end

  def self.kind_map
    @@kinded_models.each_with_object({}) do |rc, h|
      requested_kind = rc.new.kind
      raise "#{requested_kind} exists more than once!" if h[requested_kind]
      h[requested_kind] = rc
    end
  end

  def self.is_kinded_model?(klass)
    @@kinded_models.include? klass
  end

  def self.by_kind(kind)
    kinded_model = kind_map[kind]
    raise NameError.new("object_kind #{kind} Not Supported") unless kinded_model
    kinded_model
  end
end
