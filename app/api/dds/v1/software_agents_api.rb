module DDS
  module V1
    class SoftwareAgentsAPI < Grape::API
      desc 'List software agents' do
        detail 'Lists all software agents'
        named 'list software agents'
        failure [
          [200, 'Success'],
          [401, 'Unauthorized']
        ]
      end
      get '/software_agents', root: 'results' do
        authenticate!
        SoftwareAgent.where(is_deleted: false)
      end

      desc 'Create a software agent' do
        detail 'Creates a software agent for the given payload.'
        named 'create software agent'
        failure [
          [200, 'This will never actually happen'],
          [201, 'Created Successfully'],
          [400, 'Software agent requires a name'],
          [401, 'Unauthorized']
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
        Audited.audit_class.as_user(current_user) do
          if software_agent.save
            annotate_audits [software_agent.audits.last]
            software_agent
          else
            validation_error!(software_agent)
          end
        end
      end
    end
  end
end
