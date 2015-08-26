require 'rails_helper'

describe SwaggeruiController, type: :controller do
  let!(:authservice) { FactoryGirl.create(:authentication_service) }
  describe 'index' do
    it 'should set the auth_service and state' do
      get :index
      expect(assigns(:auth_service)).to be
      expect(assigns(:auth_service).uuid).to eq(authservice.uuid)
      expect(assigns(:state)).to be
    end
  end
end
