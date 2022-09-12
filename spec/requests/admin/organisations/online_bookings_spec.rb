# frozen_string_literal: true

RSpec.describe "Admin::Organisations::OnlineBookings", type: :request do
  let(:organisation) { create(:organisation) }
  let(:service_cnfs) { create(:service, :conseiller_numerique) }
  # TODO: SEB factory to create a conseiller numerique:
  let(:agent) { create(:agent, admin_role_in_organisations: [organisation], service: service_cnfs) }

  before { sign_in agent }

  describe "GET /admin/organisations/:organisation_id/online_booking" do
    subject(:show_request) { get admin_organisation_online_booking_path(organisation) }

    before { show_request }

    it { expect(response).to be_successful }
    it { expect(response).to render_template(:show) }

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
