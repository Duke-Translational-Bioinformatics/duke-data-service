class TagLabelSerializer < ActiveModel::Serializer
  attributes :label, :count, :last_used_on
end
