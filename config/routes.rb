Rails.application.routes.draw do
  mount DDS::Base, at: '/'
  mount GrapeSwaggerRails::Engine => '/apidocs'
end
