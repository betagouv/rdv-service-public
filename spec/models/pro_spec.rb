describe Pro, type: :model do
  describe 'test' do
    let(:pro) { build(:pro) }

    it { expect(pro.email).not_to eq("toto@test") }
  end
end
