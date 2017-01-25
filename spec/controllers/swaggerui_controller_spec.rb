require 'rails_helper'

describe SwaggeruiController, type: :controller do
  let!(:authservice) { FactoryGirl.create(:duke_authentication_service) }
  describe 'index' do
    it 'should set the auth_service and state' do
      get :index
      expect(response.status).to eq 200
    end
  end
end
