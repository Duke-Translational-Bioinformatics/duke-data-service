module DDS
  module V1
    class SoftwareAgentsAPI < Grape::API
      desc 'List software agents' do
        detail 'Lists all software agents (software_agent gets empty list)'
        named 'list software agents'
        failure [
          [200, 'Success'],
          [401, 'Unauthorized'],
          [403, 'Forbidden']
        ]
      end
      get '/software_agents', root: 'results' do
        authenticate!
        authorize SoftwareAgent.new, :index?
        policy_scope(SoftwareAgent).where(is_deleted: false)
      end

      desc 'Create a software agent' do
        detail 'Creates a software agent for the given payload.'
        named 'create software agent'
        failure [
          [200, 'This will never actually happen'],
          [201, 'Created Successfully'],
          [400, 'Software agent requires a name'],
          [401, 'Unauthorized'],
          [403, 'Forbidden (software_agent restricted)']
        ]
      end
      params do
        requires :name, type: String, desc: 'The Name of the software agent'
        optional :description, type: String, desc: 'The Description of the software agent'
        optional :repo_url, type: String, desc: 'The url of the repository (e.g. Git, Bitbucket, etc.) that contains the agent source code.'
      end
      post '/software_agents', root: false do
        authenticate!
        software_agent_params = declared(params, include_missing: false)
        software_agent = SoftwareAgent.new({
          name: software_agent_params[:name],
          description: software_agent_params[:description],
          repo_url: software_agent_params[:repo_url],
          creator: current_user
        })
        authorize software_agent, :create?
        software_agent.build_api_key(key: SecureRandom.hex)
        if software_agent.save
          software_agent
        else
          validation_error!(software_agent)
        end
      end

      desc 'View software agent details' do
        detail 'Returns the software agent details for a given UUID.'
        named 'view software agent'
        failure [
          [200, 'Success'],
          [401, 'Unauthorized'],
          [403, 'Forbidden (software_agent restricted)'],
          [404, 'Software Agent Does not Exist']
        ]
      end
      params do
        requires :id, type: String, desc: 'Software agent UUID'
      end
      get '/software_agents/:id', root: false do
        authenticate!
        sa = SoftwareAgent.find(params[:id])
        authorize sa, :show?
        sa
      end

      desc 'Update Software Agent' do
        detail 'Updates the software agent details for a given UUID.'
        named 'update software agent'
        failure [
          [200, 'Success'],
          [400, 'Validation Error'],
          [401, 'Unauthorized'],
          [403, 'Forbidden (software_agent restricted)'],
          [404, 'Software Agent Does not Exist']
        ]
      end
      params do
        requires :id, type: String, desc: 'Software Agent UUID'
        optional :name, type: String, desc: 'The Name of the Software Agent'
        optional :description, type: String, desc: 'The Description of the Software Agent'
        optional :repo_url, type: String, desc: 'The Repo url of the Software Agent'
      end
      put '/software_agents/:id', root: false do
        authenticate!
        software_agent_params = declared(params, {include_missing: false}, [:name, :description, :repo_url])
        software_agent = hide_logically_deleted SoftwareAgent.find(params[:id])
        authorize software_agent, :update?
        if software_agent.update(software_agent_params)
          software_agent
        else
          validation_error!(software_agent)
        end
      end

      desc 'Delete a Software Agent' do
        detail 'Marks a software agent as being deleted.'
        named 'delete software agent'
        failure [
          [204, 'Successfully Deleted'],
          [401, 'Unauthorized'],
          [403, 'Forbidden (software_agent restricted)'],
          [404, 'Software Agent Does not Exist']
        ]
      end
      params do
        requires :id, type: String, desc: 'Software Agent UUID'
      end
      delete '/software_agents/:id', root: false do
        authenticate!
        software_agent = hide_logically_deleted SoftwareAgent.find(params[:id])
        authorize software_agent, :destroy?
        software_agent.update(is_deleted: true)
        body false
      end

      desc 'Re-generate software agent API key' do
        detail 'regenerates software_agent api_key'
        named 'regenerate software_agent api_key'
        failure [
          [200, 'Success'],
          [401, 'Unauthorized'],
          [403, 'Forbidden (software_agent restricted)'],
          [404, 'Software Agent Does not Exist']
        ]
      end
      params do
        requires :id, type: String, desc: 'Software agent UUID'
      end
      put '/software_agents/:id/api_key', serializer: ApiKeySerializer do
        authenticate!
        software_agent = SoftwareAgent.find(params[:id])
        authorize software_agent.api_key, :update?
        ApiKey.transaction do
          software_agent.api_key.destroy!
          software_agent.build_api_key(key: SecureRandom.hex)
          software_agent.save
        end
        software_agent.api_key
      end
      desc 'View software agent API key' do
        detail 'View software_agent api_key'
        named 'view software_agent api_key'
        failure [
          [200, 'Success'],
          [401, 'Unauthorized'],
          [403, 'Forbidden (software_agent restricted)'],
          [404, 'Software Agent Does not Exist']
        ]
      end
      params do
        requires :id, type: String, desc: 'Software agent UUID'
      end
      get '/software_agents/:id/api_key', serializer: ApiKeySerializer do
        authenticate!
        ak = SoftwareAgent.find(params[:id]).api_key
        authorize ak, :show?
        ak
      end
      desc 'Delete software agent API key' do
        detail 'delete software_agent api_key'
        named 'delete software_agent api_key'
        failure [
          [204, 'Successfully Deleted'],
          [401, 'Unauthorized'],
          [403, 'Forbidden (software_agent restricted)'],
          [404, 'Software Agent Does not Exist']
        ]
      end
      params do
        requires :id, type: String, desc: 'Software agent UUID'
      end
      delete '/software_agents/:id/api_key', root: false do
        authenticate!
        ak = SoftwareAgent.find(params[:id]).api_key
        authorize ak, :destroy?
        ak.destroy
        body false
      end

      desc 'Get software agent access token'do
        detail 'Get software agent access token'
        named 'get software_agent access token'
        failure [
          [200, 'This will never happen'],
          [201, 'Success'],
          [400, 'Missing Required Keys'],
          [404, 'Software Agent or User Does not Exist']
        ]
      end
      params do
        requires :agent_key, type: String, desc: 'Software agent secret key'
        requires :user_key, type: String, desc: 'User secret key'
      end
      rescue_from Grape::Exceptions::ValidationErrors do |e|
        error_json = {
          "error" => 400,
          "reason" => 'missing key or keys',
          "suggestion" => 'api_key and user_key are required'
        }
        error!(error_json, 400)
      end
      rescue_from ActiveRecord::RecordNotFound do |e|
        error_json = {
          "error" => 404,
          "reason" => "invalid key",
          "suggestion" => "ensure both keys are valid"
        }
        error!(error_json, 404)
      end
      post '/software_agents/api_token', serializer: ApiTokenSerializer do
        secret_params = declared(params, include_missing: false)
        user_key = ApiKey.where(key: secret_params[:user_key]).joins(:user).take!
        software_key = ApiKey.where(key: secret_params[:agent_key]).joins(:software_agent).take!
        user_key.user.update_attribute(:last_login_at, DateTime.now)
        ApiToken.new(user: user_key.user, software_agent: software_key.software_agent)
      end
    end
  end
end
