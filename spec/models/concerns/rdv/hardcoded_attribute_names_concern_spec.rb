RSpec.describe Rdv::HardcodedAttributeNamesConcern, type: :concern do
  describe ".hardcoded_attribute_names" do

    it "is always equal to attribute_names" do
      expect(Rdv.hardcoded_attribute_names).to eq(Rdv.attribute_names)
    end
  end
end