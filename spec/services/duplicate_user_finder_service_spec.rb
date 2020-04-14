describe DuplicateUserFinderService, type: :service do
  describe ".perform" do
    let(:user) { build(:user, first_name: "Mathieu", last_name: "Lapin", email: "lapin@beta.fr", birth_date: '21/10/2000', phone_number: '0658032518') }

    subject { DuplicateUserFinderService.new(user).perform }

    context "there is no other user" do
      before { subject }
      it { is_expected.to be_nil }
    end

    context "there is an homonym" do
      let!(:homonym) { create(:user, first_name: "Mathieu", last_name: "Lapin") }
      before { subject }
      it { is_expected.to be_nil }
    end

    context "there is an duplicate" do
      context "same email" do
        let!(:duplicate) { create(:user, email: "lapin@beta.fr") }
        before { subject }
        it { is_expected.to eq(duplicate) }
      end

      context "same main first_name, last_name, birth_date" do
        let!(:duplicate) { create(:user, first_name: "Mathieu", last_name: "Lapin", birth_date: '21/10/2000') }
        before { subject }
        it { is_expected.to eq(duplicate) }
      end

      context "same phone_number" do
        let!(:duplicate) { create(:user, phone_number: '0658032518') }
        before { subject }
        it { is_expected.to eq(duplicate) }
      end

      context "multiple account" do
        let!(:duplicate_1) { create(:user, phone_number: '0658032518') }
        let!(:duplicate_2) { create(:user, first_name: "Mathieu", last_name: "Lapin", birth_date: '21/10/2000') }
        let!(:rdv) { create(:rdv, users: [duplicate_1]) }
        before { subject }
        it { is_expected.to eq(duplicate_1) }
      end
    end
  end
end
