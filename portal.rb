require 'sinatra/base'

class Portal < Sinatra::Base
  set :root, File.dirname(__FILE__)
  set :views, settings.root + '/portal'

  get /asset\/*(.*)/ do |asset|
    if asset == '/lib/config.js'
      @authServiceName = 'FOO'
      erb :'lib/config.js'
    else
      send_file "#{settings.root}/portal/#{asset}"
    end
  end

  get '/*' do
    @asset_path = "/portal/asset/"
    erb :index
  end
end
