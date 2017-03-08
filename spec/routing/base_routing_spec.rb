require "rails_helper"

RSpec.describe "application base routes" do
  it { expect(get('/apiexplorer')).to route_to("swaggerui#index") }

  it "root to apidocs", :type => :request do
    expect(get('/')).to eq(302)
    expect(response).to redirect_to('/apidocs')
  end
end
