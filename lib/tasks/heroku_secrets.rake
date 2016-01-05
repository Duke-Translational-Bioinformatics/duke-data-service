namespace :heroku_secrets do
  desc "deploys vault secrets for the app described in application_info and RAILS_ENV to the heroku target"
  task deploy: :environment do
    unless ENV['VAULT_ADDR']
      raise "Make sure to run with the correct VAULT_ADDR Environment Variable"
    end
    n = Netrc.read
    api_token = n["api.heroku.com"][1]
    unless api_token
      raise "Make sure to run this with your ~/.netrc mounted to /root/.netrc"
    end
    app_info = YAML.load_file(Rails.root.join('application_info.yml'))
    heroku = PlatformAPI.connect_oauth(api_token)
    user_id = heroku.app.info(app_info[Rails.env]["target"])["id"]
    app_id = app_info[Rails.env]["id"]
    current_config = heroku.config_var.info(app_info[Rails.env]["target"])
    token_response = HTTParty.post("#{ENV['VAULT_ADDR']}/v1/auth/app-id/login", body: {"app_id": app_id, "user_id": user_id}.to_json)
    if token_response.has_key? "errors"
      raise "Authentication #{token_response.to_json}"
    end
    auth_token = token_response["auth"]["client_token"]
    new_config = {}
    secrets = HTTParty.get("#{ENV['VAULT_ADDR']}/v1/duke_data_service/#{Rails.env}", headers: {'X-Vault-Token' => auth_token})["data"]
    unless secrets.length > 0
      raise "There are no secrets for duke_data_service/#{Rails.env}"
    end
    secrets.each do |k,v|
      unless current_config.has_key?(k) && current_config[k] == secrets[k]
        new_config[k] = v
      end
    end
    if new_config.length > 0
      $stderr.puts "Updating"
      heroku.config_var.update(app_info[Rails.env]["target"], new_config)
    else
      $stderr.puts "Nothing has changed"
    end
  end
end
