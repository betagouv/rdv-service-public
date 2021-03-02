describe Service, type: :model do
  describe "#pmi?" do
    it "returns false when social service" do
      expect(build(:service, :social).pmi?).to be false
    end

    it "returns true when pmi service" do
      expect(build(:service, :pmi).pmi?).to be true
    end
  end
end
