require 'rails_helper'

describe ApidocsController, type: :controller do
  describe 'index' do
    it {
      get :index
      assert_response 200
    }
  end
end
