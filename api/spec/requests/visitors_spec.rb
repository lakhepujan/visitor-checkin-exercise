require "rails_helper"

RSpec.describe "API::Visitors", type: :request do
  describe "GET /api/visitors" do
    it "excludes deactivated visitors from the active visitors list" do
      active_visitor = Visitor.create!(active: true, checked_out_at: nil)
      deactivated_visitor = Visitor.create!(active: true, checked_out_at: nil)

      patch "/api/visitors/#{deactivated_visitor.id}/deactivate"
      expect(response).to have_http_status(:ok)

      expect(deactivated_visitor.reload.active).to eq(false)

      get "/api/visitors"
      expect(response).to have_http_status(:ok)

      ids = JSON.parse(response.body).map{ |row| row["id"] }

      expect(ids).to include(active_visitor.id)

      expect(ids).not_to include(deactivated_visitor.id)
    end

    it "returns only visitors that are both not checked out AND active" do
 
      included = Visitor.create!(active: true, checked_out_at: nil)

      checked_out = Visitor.create!(active: true, checked_out_at: Time.current)

      inactive = Visitor.create!(active: false, checked_out_at: nil)

      get "/api/visitors"
      expect(response).to have_http_status(:ok)

      ids = JSON.parse(response.body).map { |row| row["id"] }

      expect(ids).to include(included.id)
      expect(ids).not_to include(checked_out.id)
      expect(ids).not_to include(inactive.id)
    end
  end
end