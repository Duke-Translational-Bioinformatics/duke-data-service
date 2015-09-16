module PaginationParams
  extend Grape::API::Helpers

  params :pagination do
    optional :page, type: Integer, desc: 'Requested Page (default first page)'
    optional :per_page, type: Integer, desc: 'Number of Objects per page (default 25)'
  end
end
