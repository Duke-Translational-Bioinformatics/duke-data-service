Rails.application.routes.draw do
  mount DDS::Base, at: '/'
  get "apiexplorer" => "swaggerui#index"
end
