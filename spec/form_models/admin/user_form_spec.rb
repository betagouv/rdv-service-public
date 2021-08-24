# frozen_string_literal: true

describe Admin::UserForm, type: :form do
  let!(:organisation) { create(:organisation) }

  describe "valid?" do
    it "valid without error" do
      user = build(:user)
      allow(DuplicateUsersFinderService).to receive(:find_duplicate).with(user).and_return([])
      allow(DuplicateUsersFinderService).to receive(:find_duplicate_based_on_email).with(user).and_return(nil)
      expect(described_class.new(user, view_locals: { current_organisation: organisation })).to be_valid
    end

    it "invalid without last name" do
      user = build(:user, first_name: "Jean", last_name: nil)
      allow(DuplicateUsersFinderService).to receive(:find_duplicate).with(user).and_return([])
      allow(DuplicateUsersFinderService).to receive(:find_duplicate_based_on_email).with(user).and_return(nil)
      user_form = described_class.new(user, view_locals: { current_organisation: organisation })
      expect(user_form.valid?).to be false
      expect(user_form.errors[:last_name]).to be_present
    end

    it "invalid if duplicate found on email" do
      user = build(:user, email: "jean@jacques.fr")
      existing_user = create(:user, email: "jean@jacques.fr")
      allow(DuplicateUsersFinderService).to receive(:find_duplicate_based_on_email).with(user).and_return(existing_user)
      allow(DuplicateUsersFinderService).to receive(:find_duplicate).with(user).and_return([])
      user_form = described_class.new(user, view_locals: { current_organisation: organisation })
      expect(user_form.valid?).to be false
      expect(user_form.errors[:base][0]).to include("jean@jacques.fr")
      expect(user_form.errors[:base][0]).to include("Un usager avec des informations similaires existe déjà")
    end

    it "invalid if duplicate on phone number" do
      user = build(:user, phone_number: "0101010101")
      existing_user = create(:user, phone_number: "0101010101")
      allow(DuplicateUsersFinderService).to receive(:find_duplicate).with(user).and_return([existing_user])
      allow(DuplicateUsersFinderService).to receive(:find_duplicate_based_on_email).with(user).and_return(nil)
      user_form = described_class.new(user, view_locals: { current_organisation: organisation })
      expect(user_form.valid?).to be false
      expect(user_form.errors[:base][0]).to include("0101010101")
      expect(user_form.errors[:base][0]).to include("Un usager avec des informations similaires existe déjà")
    end

    it "invalid with persisted user, phone just changed" do
      user = create(:user, phone_number: nil)
      user.phone_number = "0101010101"
      existing_user = create(:user, phone_number: "0101010101")

      allow(DuplicateUsersFinderService).to receive(:find_duplicate).with(user).and_return([existing_user])
      allow(DuplicateUsersFinderService).to receive(:find_duplicate_based_on_email).with(user).and_return(nil)

      user_form = described_class.new(user, view_locals: { current_organisation: organisation })
      expect(user_form.valid?).to be false
      expect(user_form.errors[:base][0]).to include("0101010101")
      expect(user_form.errors[:base][0]).to include("Un usager avec des informations similaires existe déjà")
    end

    it "valid with persisted user, phone did not change" do
      user = create(:user, phone_number: nil)
      user.last_name = "Fifou"
      create(:user, phone_number: "0101010101")

      allow(DuplicateUsersFinderService).to receive(:find_duplicate).with(user).and_return([])
      allow(DuplicateUsersFinderService).to receive(:find_duplicate_based_on_email).with(user).and_return(nil)

      user_form = described_class.new(user, view_locals: { current_organisation: organisation })
      expect(user_form).to be_valid
    end

    it "invalid without responsible last name" do
      responsible = build(:user, first_name: "Jean", last_name: nil)
      user = build(:user, responsible: responsible)
      allow(DuplicateUsersFinderService).to receive(:find_duplicate).with(user).and_return([])
      allow(DuplicateUsersFinderService).to receive(:find_duplicate_based_on_email).with(user).and_return(nil)
      user_form = described_class.new(user, view_locals: { current_organisation: organisation })
      expect(user_form.valid?).to be false
      expect(user_form.errors["responsible.last_name"]).to eq(["doit être rempli(e)"])
    end

    it "invalid if duplicate found on responsible email" do
      responsible = build(:user, email: "jean@jacques.fr")
      user = build(:user, responsible: responsible)
      existing_user = create(:user, email: "jean@jacques.fr")
      allow(DuplicateUsersFinderService).to receive(:find_duplicate_based_on_email).with(user).and_return(existing_user)
      allow(DuplicateUsersFinderService).to receive(:find_duplicate).with(user).and_return([])
      user_form = described_class.new(user, view_locals: { current_organisation: organisation })
      expect(user_form.valid?).to be false
      expect(user_form.errors[:base][0]).to include("jean@jacques.fr")
      expect(user_form.errors[:base][0]).to include("Un usager avec des informations similaires existe déjà")
    end

    it "invalid if duplicate on responsible phone number" do
      responsible = build(:user, phone_number: "0101010101")
      user = build(:user, responsible: responsible)
      existing_user = create(:user, phone_number: "0101010101")
      allow(DuplicateUsersFinderService).to receive(:find_duplicate).with(user).and_return([existing_user])
      allow(DuplicateUsersFinderService).to receive(:find_duplicate_based_on_email).with(user).and_return(nil)
      user_form = described_class.new(user, view_locals: { current_organisation: organisation })
      expect(user_form.valid?).to be false
      expect(user_form.errors[:base][0]).to include("0101010101")
      expect(user_form.errors[:base][0]).to include("Un usager avec des informations similaires existe déjà")
    end
  end
end
