RSpec.describe "Admin::Organisations::OnlineBookings", type: :request do
  include Rails.application.routes.url_helpers

  let(:organisation) { create(:organisation) }
  let(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }

  before { sign_in agent }

  describe "GET /admin/organisations/:organisation_id/creneaux_search" do
    it "is successful" do
      get admin_organisation_creneaux_search_path(organisation)
      expect(response).to be_successful
    end

    context "search for phone motif with availability in 2 weeks" do
      it "redirect to slot controller for available slots" do
        now = Time.zone.parse("2022-10-17 10:30")
        travel_to(now)
        motif = create(:motif, :by_phone, organisation: organisation)
        create(:plage_ouverture,
               motifs: [motif],
               organisation: organisation,
               lieu: nil,
               agent: agent,
               first_day: now + 2.weeks)

        params = {
          from_date: "2022-10-17",
          motif_id: motif.id,
          commit: true,
        }

        get admin_organisation_creneaux_search_path(organisation, params)

        expect(response).to redirect_to(admin_organisation_creneaux_search_selection_creneaux_path(organisation, from_date: "2022-10-17", motif_id: motif.id))
      end
    end
  end
end
