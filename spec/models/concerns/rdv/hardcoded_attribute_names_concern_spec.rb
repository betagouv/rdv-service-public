RSpec.describe Rdv::HardcodedAttributeNamesConcern, type: :concern do
  describe ".hardcoded_attribute_names" do
    let(:rdv) { create(:rdv) }

    it "is always equal to attribute_names" do
      expect(rdv.hardcoded_attribute_names).to eq(rdv.attribute_names)
    end
  end
end