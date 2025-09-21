require 'rails_helper'

RSpec.describe "MonthlySummaries", type: :request do
  let!(:admin) { User.create!(name: "管理者", email: "admin@example.com", password: "password", role: :admin, status: :active) }
  let(:year) { 2025 }
  let(:month) { 9 }

  def login(user)
    post "/auth/login", params: { email: user.email, password: "password" }
    JSON.parse(response.body)["token"]
  end

  describe "GET /show" do
    it "returns http success" do
      token = login(admin)
      get "/v1/monthly_summary", params: { year: year, month: month }, headers: { "Authorization" => "Bearer #{token}" }
      expect(response).to have_http_status(:success)
    end
  end
end
