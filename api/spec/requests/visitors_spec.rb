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

RSpec.describe "API::Visitors Search", type: :request do
  describe "GET /api/visitors/search" do
    let!(:host) { Host.create!(name: "Test Host") }

    it "excludes deactivated visitors from search results" do
      active_visitor = Visitor.create!(
        full_name: "Ana Smith",
        company_name: "Active Co",
        host_id: host.id,
        active: true
      )

      deactivated_visitor = Visitor.create!(
        full_name: "Ana Johnson",
        company_name: "Inactive Co",
        host_id: host.id,
        active: true
      )

      patch "/api/visitors/#{deactivated_visitor.id}/deactivate"
      expect(response).to have_http_status(:ok)
      expect(deactivated_visitor.reload.active).to eq(false)

      get "/api/visitors/search", params: { q: "Ana" }
      expect(response).to have_http_status(:ok)

      result_ids = JSON.parse(response.body).map { |v| v["id"] }

      expect(result_ids).to include(active_visitor.id)
      expect(result_ids).not_to include(deactivated_visitor.id)
    end

    it "returns only active visitors matching the search query" do
      matching_active = Visitor.create!(
        full_name: "John Doe",
        company_name: "Test Co",
        host_id: host.id,
        active: true
      )

      matching_inactive = Visitor.create!(
        full_name: "John Smith",
        company_name: "Test Co",
        host_id: host.id,
        active: false
      )

      non_matching = Visitor.create!(
        full_name: "Jane Brown",
        company_name: "Other Co",
        host_id: host.id,
        active: true
      )

      get "/api/visitors/search", params: { q: "John" }
      expect(response).to have_http_status(:ok)

      result_ids = JSON.parse(response.body).map { |v| v["id"] }

      expect(result_ids).to include(matching_active.id)
      expect(result_ids).not_to include(matching_inactive.id)
      expect(result_ids).not_to include(non_matching.id)
    end
  end
end