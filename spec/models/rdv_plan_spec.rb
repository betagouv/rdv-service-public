RSpec.describe RdvPlan do
  describe "#create_rdv_or_send_invitation" do
    context "for an invitation" do
      let(:user) { create(:user, email: nil) }

      let(:organisation) { create(:organisation) }
      let(:motif) { create(:motif, organisation:) }
      let(:lieu) { create(:lieu, organisation:) }

      let(:rdv_plan) { create(:rdv_plan, by_invitation: true, user:, motif:, lieu:) }

      it "creates an invitation" do
        rdv_plan.create_rdv_or_send_invitation(user_attributes: { email: "francis@factice.org" })
        expect(rdv_plan.reload.rdv_invitation).to have_attributes(
          motif: rdv_plan.motif,
          lieu: rdv_plan.lieu,
          user: rdv_plan.user,
          persisted?: true
        )
      end

      it "sends an email" do
        rdv_plan.create_rdv_or_send_invitation(user_attributes: { email: "francis@factice.org" })
        perform_enqueued_jobs
        expect(ActionMailer::Base.deliveries.map(&:to).flatten).to include("francis@factice.org")
      end

      it "adds the user to the organisation to make sure they are visible" do
        rdv_plan.create_rdv_or_send_invitation(user_attributes: { email: "francis@factice.org" })
        expect(user.reload.organisations).to eq [organisation]
      end
    end
  end

  describe "#return_url" do
    let(:application) do
      create(:oauth_application,
             redirect_uri: "http://localhost:4567/omniauth/rdvservicepublic/callback\nhttps://demo.demarches-simplifiees.fr/omniauth/rdvservicepublic/callback")
    end
    let(:user) { create(:user) }
    let(:agent) { create(:agent) }

    it "can only be in a a whitelisted domain name from the corresponding oauth application" do
      rdv_plan = build(:rdv_plan, oauth_application: application)
      rdv_plan.return_url = "nimportequoi.fr/asdf"
      expect(rdv_plan).not_to be_valid

      rdv_plan.return_url = "https://nimportequoi.fr/asdf#test.gouv.fr"
      expect(rdv_plan).not_to be_valid

      rdv_plan.return_url = "http://localhost:4567/beneficiaires/123"
      expect(rdv_plan).to be_valid

      rdv_plan.return_url = "https://demo.demarches-simplifiees.fr/beneficiaires/123"
      expect(rdv_plan).to be_valid
    end

    it "needs to be a http url" do
      rdv_plan = build(:rdv_plan, oauth_application: application, return_url: "javascript:alert(1)")
      expect(rdv_plan).not_to be_valid

      rdv_plan.return_url = "ssh://test.gouv.fr"
      expect(rdv_plan).not_to be_valid
    end
  end
end
