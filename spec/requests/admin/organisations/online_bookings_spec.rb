# frozen_string_literal: true

RSpec.describe "Admin::Organisations::OnlineBookings", type: :request do
  let(:organisation) { create(:organisation) }
  let(:agent) { create(:agent, :cnfs, admin_role_in_organisations: [organisation]) }

  before { sign_in agent }

  describe "GET /admin/organisations/:organisation_id/online_booking" do
    subject(:show_request) { get admin_organisation_online_booking_path(organisation) }

    it "is successful" do
      show_request
      expect(response).to be_successful
    end

    it { expect(show_request).to render_template(:show) }

    context "when there is at least one motif that can be booked online" do
      let!(:motif) { create(:motif, organisation: organisation, service: agent.service, reservable_online: true) }

      it "shows the motif" do
        show_request
        expect(response.body).to include("conserver au moins un motif ouvert à la réservation en ligne")
        expect(response.body).to include(motif.name)
      end
    end

    context "when there is no motifs that can be booked online" do
      it "shows a message to create motifs" do
        show_request
        expect(response.body).to include("aucun n'est ouvert à la réservation en ligne")
      end
    end

    describe "edge cases" do
      context "when the current agent is not a conseiller numerique" do
        let(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }

        it "redirects to the authenticated agent root page" do
          show_request
          expect(response).to redirect_to(authenticated_agent_root_path)
        end
      end
    end
  end
end
