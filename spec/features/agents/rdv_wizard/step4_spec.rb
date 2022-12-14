require "rails_helper"

RSpec.describe "Step 4 of the rdv wizard" do
  let(:motif) { create(:motif, :by_phone) }
  let(:organisation) { motif.organisation }
  let(:agent) { create(:agent, service: motif.service, basic_role_in_organisations: [organisation]) }

  let(:params) do
    {
      organisation_id: organisation.id,
      user_ids: [user.id],
      duration_in_min: 30,
      motif_id: motif.id,
      starts_at: 2.days.from_now,
      step: 4,
    }
  end

  context "when booking a rdv for a relative" do
    let(:user) { create(:user, :relative, responsible: responsible) }
    let(:responsible) { create(:user, email: nil) }

    before { stub_netsize_ok }

    it "sends a sms with a valid link" do
      login_as(agent, scope: :agent)
      visit new_admin_organisation_rdv_wizard_step_path(params)
      click_button "Créer RDV"
      expect(page).to have_content("Le rendez-vous a été créé.")
      perform_enqueued_jobs
      rdv_url = rdv_short_url(Rdv.last, host: Domain::RDV_SOLIDARITES.dns_domain_name, tkn: RdvsUser.last.raw_invitation_token)
      expect(Receipt.last.content).to include(rdv_url)
    end
  end
end
