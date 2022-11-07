# frozen_string_literal: true

describe "CNFS agent can configure online booking" do
  let!(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, :cnfs, admin_role_in_organisations: [organisation]) }

  before { login_as(agent, scope: :agent) }

  context "when there is no bookable motifs" do
    it "goes to the right apge but can't copy the booking link", js: true do
      visit authenticated_agent_root_path
      click_link "Paramètres"
      click_link "Réservation en ligne"

      expect(page).to have_current_path(admin_organisation_online_booking_path(organisation))
      expect(page).to have_css('[data-clipboard-target="copy-button"][disabled]')
    end
  end

  context "when there is a bookable motif" do
    let!(:motif) { create(:motif, organisation: organisation, service: agent.service, reservable_online: true) }

    context "when there is no related plage d'ouverture" do
      it "can't copy the booking link" do
        visit admin_organisation_online_booking_path(organisation)
        expect(page).to have_css('[data-clipboard-target="copy-button"][disabled]')
      end
    end

    context "when there is a related plage d'ouverture" do
      before { motif.plage_ouvertures << create(:plage_ouverture, organisation: organisation, agent: agent) }

      it "can copy the booking link" do
        visit admin_organisation_online_booking_path(organisation)
        expect(page).not_to have_css('[data-clipboard-target="copy-button"][disabled]')
        expect(page).to have_css('[data-clipboard-target="copy-button"]')
      end
    end
  end
end
