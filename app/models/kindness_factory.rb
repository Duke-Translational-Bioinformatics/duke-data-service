class KindnessFactory
  @@kinded_models = []

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

  def self.is_kinded_model?(kind)
    self.kind_map.keys.include? kind
  end

  def self.by_kind(kind)
    kinded_model = kind_map[kind]
    raise NameError.new("#{kind} is not recognized") unless kinded_model
    kinded_model
  end
end
