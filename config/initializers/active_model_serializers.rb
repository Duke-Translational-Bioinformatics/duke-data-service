#ActiveModel::Serializer.root = false # Used in AMS v0.9.x

ActiveModel::Serializer.config.default_includes = '**'
ActiveModel::Serializer.config.adapter = :attributes

#ActiveModel::Serializer.config.adapter = :json #ActiveModel::Serializer::Adapter::Json
#ActiveModel::Serializer.config.root = nil
#ActiveModel::Serializer.config.jsonapi_include_toplevel_object = false
