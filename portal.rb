require 'sinatra/base'

class Portal < Sinatra::Base
  set :root, File.dirname(__FILE__)
  set :views, settings.root + '/portal'

  get /asset\/*(.*)/ do |asset|
    send_file "#{settings.root}/portal/#{asset}"
  end

  get '/*' do
    @asset_path = "/portal/asset/"
    @serviceID = ENV['SERVICE_ID']
    @baseUrl = request.url.gsub(request.path, '')
    @authServiceUri = ENV['AUTH_SERVICE_BASE_URI']
    @authServiceName = ENV['AUTH_SERVICE_NAME']
    @securityState = SecureRandom.hex
    erb :index
  end
end
