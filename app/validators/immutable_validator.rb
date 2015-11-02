class ImmutableValidator < ActiveModel::EachValidator
	def validate_each(record, attribute, value)
		if record.id
			if record.changed.include?(attribute.to_s)
				record.errors[attribute] << (options[:message] || "Cannot change #{attribute}.")
			end
		end
	end
end
