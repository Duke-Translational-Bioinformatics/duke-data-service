class TagLabel
  include ActiveModel::Model
  include ActiveModel::Serialization
  include Comparable

  attr_accessor :label, :count, :last_used_on

  def attributes
    {'label' => label, 'count' => count}
  end

  def <=>(other_tag_label)
    self.attributes <=> other_tag_label.attributes
  end
end
