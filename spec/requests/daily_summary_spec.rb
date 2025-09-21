require 'rails_helper'

RSpec.describe "DailySummaries", type: :request do
  describe "GET /show" do
    it "returns http success" do
      get "/daily_summary/show"
      expect(response).to have_http_status(:success)
    end
  end

end
