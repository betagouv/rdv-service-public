RSpec.describe RdvPlan do
  describe "#return_url" do
    let(:application) do
      create(:oauth_application,
             redirect_uri: "http://localhost:4567/omniauth/rdvservicepublic/callback\nhttps://demo.demarches-simplifiees.fr/omniauth/rdvservicepublic/callback")
    end

    it "can only be in a a whitelisted domain name from the corresponding oauth application" do
      rdv_plan = build(:rdv_plan, oauth_application: application)
      rdv_plan.return_url = "nimportequoi.fr/asdf"
      expect(rdv_plan).not_to be_valid

      rdv_plan.return_url = "https://nimportequoi.fr/asdf#test.gouv.fr"
      expect(rdv_plan).not_to be_valid

      rdv_plan.return_url = "http://localhost:4567/beneficiaires/123"
      expect(rdv_plan).to be_valid

      rdv_plan.return_url = "demo.demarches-simplifiees.fr/beneficiaires/123"
      expect(rdv_plan).to be_valid
    end

    it "needs to be a http url" do
      rdv_plan = build(:rdv_plan, return_url: "javascript:alert(1)")
      expect(rdv_plan).not_to be_valid

      rdv_plan.return_url = "ssh://test.gouv.fr"
      expect(rdv_plan).not_to be_valid
    end
  end
end
