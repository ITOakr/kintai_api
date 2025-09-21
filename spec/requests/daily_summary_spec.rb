require 'rails_helper'

RSpec.describe "DailySummaries", type: :request do
  let!(:admin) { User.create!(name: "管理者", email: "admin@example.com", password: "password", role: :admin, status: :active) }
  let(:date) { "2025-09-21" }

  def login(user)
    post "/auth/login", params: { email: user.email, password: "password" }
    JSON.parse(response.body)["token"]
  end

  describe "GET /show" do
    it "returns http success" do
      token = login(admin)
      get "/v1/daily_summary", params: { date: date }, headers: { "Authorization" => "Bearer #{token}" }
      expect(response).to have_http_status(:success)
    end
  end
end
