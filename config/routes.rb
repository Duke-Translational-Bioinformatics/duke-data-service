Rails.application.routes.draw do
  mount DDS::Base, at: '/'
  root 'front_end#index'
  get "/*path" => "front_end#index"
end
