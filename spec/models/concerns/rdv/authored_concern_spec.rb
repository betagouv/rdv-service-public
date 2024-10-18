RSpec.describe Rdv::AuthoredConcern, type: :concern, versioning: true do
  describe ".author" do
    let(:rdv) { create(:rdv) }

    it "returns the whodunnit of the first 'create' version" do
      whodunnit = "a mysterious agent"
      rdv.versions.first.update!(whodunnit: whodunnit)

      expect(rdv.author).to eq(whodunnit)
    end

    context "when the author starts with '[Agent]'" do
      it "removes the '[Agent]' part" do
        rdv.versions.first.update!(whodunnit: "[Agent] Sebastian Creneau")

        expect(rdv.author).to eq("Sebastian Creneau")
      end
    end

    context "when the author starts with '[User]'" do
      it "removes the '[User]' part" do
        rdv.versions.first.update!(whodunnit: "[User] Sebastian Creneau")

        expect(rdv.author).to eq("Sebastian Creneau")
      end
    end

    context "there is no 'create' version"
    it "returns a text explaining that the version was deleted for RGPD purposes" do
      rdv.versions.first.destroy!

      expect(rdv.author).to eq("Dans le cadre du RGPD, cette information n'est plus conservée au delà d'un an.")
    end
  end
end
