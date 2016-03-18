module DDS
  module V1
    class FileVersionsAPI < Grape::API
      desc 'List file versions' do
        detail 'If there are previous versions of a file, this action can be used to retrieve information about the older versions.'
        named 'list file versions'
        failure [
          [200, "Valid API Token in 'Authorization' Header"],
          [401, "Missing, Expired, or Invalid API Token in 'Authorization' Header"],
          [404, 'File does not exist']
        ]
      end
      params do
      end
      get '/files/:id/versions', root: 'results' do
        authenticate!
        file = DataFile.find(params[:id])
        authorize file, :show?
        file.file_versions
      end

      desc 'View file version' do
        detail 'view file version'
        named 'view file version'
        failure [
          [200, "Valid API Token in 'Authorization' Header"],
          [401, "Missing, Expired, or Invalid API Token in 'Authorization' Header"],
          [404, 'File does not exist']
        ]
      end
      params do
      end
      get '/file_versions/:id', root: false do
        authenticate!
        file_version = FileVersion.find(params[:id])
        authorize file_version, :show?
        file_version
      end
    end
  end
end
