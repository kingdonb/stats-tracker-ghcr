require 'rails_helper'

RSpec.describe "Cookies", type: :request do
  describe "GET /accept" do
    it "returns http success" do
      get "/cookies/accept"
      expect(response).to have_http_status(:success)
    end
  end

end
