RSpec.describe RdvPlan do
  describe "#return_url" do
    it "can only be ina a whitelisted domain name" do
      rdv_plan = build(:rdv_plan)
      rdv_plan.return_url = "nimportequoi.fr/asdf"
      expect(rdv_plan).not_to be_valid

      rdv_plan.return_url = "https://nimportequoi.fr/asdf#test.gouv.fr"
      expect(rdv_plan).not_to be_valid

      rdv_plan.return_url = "https://monsuivisocial.incubateur.anct.gouv.fr/beneficiaires/123"
      expect(rdv_plan).to be_valid
    end
  end
end
