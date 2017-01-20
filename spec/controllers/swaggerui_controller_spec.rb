require 'rails_helper'

describe SwaggeruiController, type: :controller do
  let!(:authservice) { FactoryGirl.create(:duke_authentication_service) }
  describe 'index' do
    it 'should set the auth_service and state' do
      get :index
      expect(assigns(:auth_service)).to be
      expect(assigns(:auth_service).id).to eq(authservice.id)
      expect(assigns(:state)).to be
    end
  end
end
