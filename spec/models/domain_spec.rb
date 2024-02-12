RSpec.describe Domain do
  it "has domains initialized with all the required keys" do
    Domain::ALL.each do |domain|
      expect(domain.to_h.compact.keys).to match_array(described_class.members)
    end
  end
end
