# frozen_string_literal: true

describe "CNFS agent can configure online booking" do
  let!(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, :cnfs, admin_role_in_organisations: [organisation]) }

  before { login_as(agent, scope: :agent) }

  context "when there is a bookable motif and plages d'ouverture" do
    let!(:motif) { create(:motif, organisation: organisation, service: agent.service, reservable_online: true) }

    before { motif.plage_ouvertures << create(:plage_ouverture, organisation: organisation, agent: agent) }

    it "can copy the booking link" do
      visit admin_organisation_online_booking_path(organisation)
      expect(page).not_to have_css('[data-clipboard-target="copy-button"][disabled]')
      expect(page).to have_css('[data-clipboard-target="copy-button"]')
    end
  end
end
