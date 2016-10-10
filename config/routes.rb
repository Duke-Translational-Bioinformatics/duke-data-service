Rails.application.routes.draw do
  mount DDS::Base, at: '/'
  get "apiexplorer" => "swaggerui#index"
  get "apidocs" => "apidocs#index"
  root to: redirect("/portal", status: 302)
end
