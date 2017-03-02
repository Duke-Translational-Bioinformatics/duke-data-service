Rails.application.routes.draw do
  mount DDS::Base, at: '/'
  get "apiexplorer" => "swaggerui#index"
  root to: redirect("/apidocs", status: 302)
end
