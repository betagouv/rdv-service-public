describe Admin::UserForm, type: :form do
  let!(:organisation) { create(:organisation) }

  subject { Admin::UserForm.new(user, view_locals: { current_organisation: organisation, }) }
  before do
    expect(DuplicateUsersFinderService).to receive(:perform_with).with(user).and_return(duplicate_users_mock)
  end

  context "no errors whatsoever" do
    let(:user) { build(:user, first_name: "Jean", last_name: "Jacques") }
    let(:duplicate_users_mock) { [] }

    it "should be valid" do
      expect(subject.valid?).to eq true
    end

    it "should save the user" do
      expect(user).to receive(:save)
      subject.save
    end
  end

  context "user has model errors" do
    let(:user) { build(:user, first_name: "Jean", last_name: nil) }
    let(:duplicate_users_mock) { [] }

    it "should not be valid" do
      expect(subject.valid?).to eq false
      expect(subject.errors).to be_present
      expect(subject.errors[:last_name]).to be_present
    end

    it "should not save the user" do
      expect(user).not_to receive(:save)
      subject.save
    end
  end

  context "duplication error based on email" do
    let(:user) { build(:user, first_name: "Jean", last_name: "Jacques", email: "jean@jacques.fr") }
    let!(:existing_user) { create(:user, first_name: "Jeannot", email: "jean@jacques.fr") }
    let(:duplicate_users_mock) { [OpenStruct.new(severity: :error, attributes: [:email], user: existing_user)] }

    it "should not be valid" do
      expect(subject.valid?).to eq false
      expect(subject.errors).to be_present
      expect(subject.errors[:base]).to be_present
      expect(subject.errors[:base][0]).to include("Jeannot")
      expect(subject.errors[:base][0]).to include("Un usager avec le même email existe déjà")
    end

    it "should not save the user" do
      expect(user).not_to receive(:save)
      subject.save
    end
  end

  context "duplication warning based on phone_number" do
    let(:user) { build(:user, first_name: "Jean", last_name: "Jacques", phone_number: "0101010101") }
    let!(:existing_user) { create(:user, first_name: "Jeannot", phone_number: "0101010101") }
    let(:duplicate_users_mock) { [OpenStruct.new(severity: :warning, attributes: [:phone_number], user: existing_user)] }

    it "should not be valid" do
      expect(subject.valid?).to eq false
      expect(subject.warnings).to be_present
      expect(subject.warnings[:base]).to be_present
      expect(subject.warnings[:base][0]).to include("Jeannot")
      expect(subject.warnings[:base][0]).to include("Un usager avec le même numéro de téléphone existe déjà")
    end

    it "should not save the user" do
      expect(user).not_to receive(:save)
      subject.save
    end
  end

  context "duplication warning bypassed" do
    let(:user) { build(:user, first_name: "Jean", last_name: "Jacques", phone_number: "0101010101") }
    let!(:existing_user) { create(:user, first_name: "Jeannot", phone_number: "0101010101") }
    let(:duplicate_users_mock) { [OpenStruct.new(severity: :warning, attributes: [:phone_number], user: existing_user)] }
    subject { Admin::UserForm.new(user, active_warnings_confirm_decision: true, view_locals: { current_organisation: organisation, }) }

    it "should be valid" do
      expect(subject.valid?).to eq true
    end

    it "should save the user" do
      expect(user).to receive(:save)
      subject.save
    end
  end

  context "duplication warning based on phone_number with persisted user, phone just changed" do
    let!(:user) do
      u = create(:user, first_name: "Jean", last_name: "Jacques", phone_number: nil)
      u.phone_number = "0101010101"
      u
    end
    let!(:existing_user) { create(:user, first_name: "Jeannot", phone_number: "0101010101") }
    let(:duplicate_users_mock) { [OpenStruct.new(severity: :warning, attributes: [:phone_number], user: existing_user)] }

    it "should not be valid" do
      expect(subject.valid?).to eq false
      expect(subject.warnings).to be_present
      expect(subject.warnings[:base]).to be_present
      expect(subject.warnings[:base][0]).to include("Jeannot")
      expect(subject.warnings[:base][0]).to include("Un usager avec le même numéro de téléphone existe déjà")
    end

    it "should not save the user" do
      expect(user).not_to receive(:save)
      subject.save
    end
  end

  context "duplication warning based on phone_number with persisted user, phone did not change" do
    let!(:user) do
      u = create(:user, first_name: "Jean", last_name: "Jacques", phone_number: "0101010101")
      u.last_name = "Fifou"
      u
    end
    let!(:existing_user) { create(:user, first_name: "Jeannot", phone_number: "0101010101") }
    let(:duplicate_users_mock) { [OpenStruct.new(severity: :warning, attributes: [:phone_number], user: existing_user)] }

    it "should be valid" do
      expect(subject.valid?).to eq true
      expect(subject.warnings).to be_empty
    end

    it "should save the user" do
      expect(user).to receive(:save)
      subject.save
    end
  end
end
