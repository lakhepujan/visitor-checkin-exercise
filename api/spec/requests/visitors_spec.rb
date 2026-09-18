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

  RSpec.describe "API:: Visitors Checkout", type: :request do 
    describe "PATCH /api/visitors/:id/checkout" do 
        let!(:host) {Host.create(name: "Emil Clarke")}
        it "souldnt overwrite the intital checkout time" do
          visitor = Visitor.create!(
          full_name: "Emil Clarke",
          company_name: "Quantum Edge",
          host_id: host.id,
          active: true,
          checked_out_at: nil
          )

          patch "/api/visitors/#{visitor.id}/check_out"
          expect(response).to have_http_status(:ok)

          intital_checkout_time = visitor.reload.checked_out_at

          patch "/api/visitors/#{visitor.id}/check_out"
          expect(response).to have_http_status(:ok)
        expect(visitor.reload.checked_out_at).to eq(intital_checkout_time)
        end
     end
end

RSpec.describe "Visitors API", type: :request do
  describe "GET /api/visitors" do
    it "does not make an N+1 query for hosts" do
      host = Host.create!(name: "Test Host")

      20.times do |i|
        Visitor.create!(
          full_name: "Visitor #{i}",
          company_name: "Company #{i}",
          host: host,
          purpose: "Meeting",
          active: true,
          checked_out_at: nil
        )
      end

      queries = []

      subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |*args|
        payload = args.last

        unless payload[:name].in?(["SCHEMA", "CACHE"])
          queries << payload[:sql]
        end
      end

      get "/api/visitors"

      ActiveSupport::Notifications.unsubscribe(subscriber)

      expect(response).to have_http_status(:ok)

      host_queries = queries.count do |sql|
        sql.match?(/FROM ["`]hosts["`]/i)
      end

      expect(host_queries).to be <= 1
    end
  end
end
