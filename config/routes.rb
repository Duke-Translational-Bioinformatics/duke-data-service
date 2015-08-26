Rails.application.routes.draw do
  mount DDS::Base, at: '/'
  get "swaggerui" => "swaggerui#index"
end
