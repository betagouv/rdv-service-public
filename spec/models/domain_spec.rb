describe Domain do
  it "has domains initialized with all the required keys" do
    Domain::ALL.each do |domain|
      expect(domain.to_h.keys).to match_array(described_class.members)
    end
  end
end
