module DDS
  class Base < Grape::API
    mount DDS::V1::Base
  end
end
