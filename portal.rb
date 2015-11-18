require 'sinatra/base'

class Portal < Sinatra::Base
  set :root, File.dirname(__FILE__)
  set :views, settings.root + '/portal'
  set :public_folder, settings.root + '/portal'

  get '/' do
    erb :index
  end
end
