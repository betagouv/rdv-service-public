RSpec.describe Prescripteur, type: :model do
  describe "#set_token" do
    it "ajoute le token si celui-ci n’existe pas" do
      prescripteur = described_class.new(first_name: "John", last_name: "Doe", email: "john@doe.fr")
      expect(prescripteur.token).to be_nil
      prescripteur.save!
      expect(prescripteur.reload.token).not_to be_nil
    end

    it "ne modifie pas le token s’il existe déjà" do
      prescripteur = described_class.new(first_name: "John", last_name: "Doe", email: "john@doe.fr", token: "existing")
      prescripteur.save!
      expect(prescripteur.reload.token).to eq("existing")
    end
  end
end
