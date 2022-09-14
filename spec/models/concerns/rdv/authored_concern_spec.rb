# frozen_string_literal: true

describe Rdv::AuthoredConcern, type: :concern do
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

    it "returns nothing when there is no 'create' version" do
      rdv.versions.first.destroy!

      expect(rdv.author).to eq(nil)
    end
  end
end
