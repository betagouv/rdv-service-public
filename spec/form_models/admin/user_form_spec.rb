# frozen_string_literal: true

describe Admin::UserForm, type: :form do
  let!(:organisation) { create(:organisation) }

  context "no errors whatsoever" do
    before do
      allow(DuplicateUsersFinderService).to receive(:perform).with(user).and_return(duplicate_users_mock)
    end

    let(:user) { build(:user, first_name: "Jean", last_name: "Jacques") }
    let(:duplicate_users_mock) { [] }

    it "is valid" do
      expect(described_class.new(user, view_locals: { current_organisation: organisation }).valid?).to eq true
    end

    it "saves the user" do
      expect(user).to receive(:save)
      described_class.new(user, view_locals: { current_organisation: organisation }).save
    end
  end

  context "user has model errors" do
    before do
      allow(DuplicateUsersFinderService).to receive(:perform).with(user).and_return(duplicate_users_mock)
    end

    let(:user) { build(:user, first_name: "Jean", last_name: nil) }
    let(:duplicate_users_mock) { [] }

    it "is not valid" do
      user_form = described_class.new(user, view_locals: { current_organisation: organisation })
      expect(user_form.valid?).to eq false
      expect(user_form.errors).to be_present
      expect(user_form.errors[:last_name]).to be_present
    end

    it "does not save the user" do
      expect(user).not_to receive(:save)
      described_class.new(user, view_locals: { current_organisation: organisation }).save
    end
  end

  context "duplication error based on email" do
    before do
      allow(DuplicateUsersFinderService).to receive(:perform).with(user).and_return(duplicate_users_mock)
    end

    let(:user) { build(:user, first_name: "Jean", last_name: "Jacques", email: "jean@jacques.fr") }
    let!(:existing_user) { create(:user, first_name: "Jeannot", email: "jean@jacques.fr") }
    let(:duplicate_users_mock) { [OpenStruct.new(severity: :error, attributes: [:email], user: existing_user)] }

    it "is not valid" do
      user_form = described_class.new(user, view_locals: { current_organisation: organisation })
      expect(user_form.valid?).to eq false
      expect(user_form.errors).to be_present
      expect(user_form.errors[:base]).to be_present
      expect(user_form.errors[:base][0]).to include("Jeannot")
      expect(user_form.errors[:base][0]).to include("Un usager avec le même email existe déjà")
    end

    it "does not save the user" do
      expect(user).not_to receive(:save)
      described_class.new(user, view_locals: { current_organisation: organisation }).save
    end
  end

  context "duplication warning based on phone_number" do
    before do
      allow(DuplicateUsersFinderService).to receive(:perform).with(user).and_return(duplicate_users_mock)
    end

    let(:user) { build(:user, first_name: "Jean", last_name: "Jacques", phone_number: "0101010101") }
    let!(:existing_user) { create(:user, first_name: "Jeannot", phone_number: "0101010101") }
    let(:duplicate_users_mock) { [OpenStruct.new(severity: :warning, attributes: [:phone_number], user: existing_user)] }

    it "is not valid" do
      user_form = described_class.new(user, view_locals: { current_organisation: organisation })
      expect(user_form.valid?).to eq false
      expect(user_form.warnings).to be_present
      expect(user_form.warnings[:base]).to be_present
      expect(user_form.warnings[:base][0]).to include("Jeannot")
      expect(user_form.warnings[:base][0]).to include("Un usager avec le même numéro de téléphone existe déjà")
    end

    it "does not save the user" do
      expect(user).not_to receive(:save)
      described_class.new(user, view_locals: { current_organisation: organisation }).save
    end
  end

  context "duplication warning bypassed" do
    before do
      allow(DuplicateUsersFinderService).to receive(:perform).with(user).and_return(duplicate_users_mock)
    end

    let(:user) { build(:user, first_name: "Jean", last_name: "Jacques", phone_number: "0101010101") }
    let!(:existing_user) { create(:user, first_name: "Jeannot", phone_number: "0101010101") }
    let(:duplicate_users_mock) { [OpenStruct.new(severity: :warning, attributes: [:phone_number], user: existing_user)] }

    it "is valid" do
      expect(described_class.new(user, active_warnings_confirm_decision: true, view_locals: { current_organisation: organisation }).valid?).to eq true
    end

    it "saves the user" do
      expect(user).to receive(:save)
      described_class.new(user, active_warnings_confirm_decision: true, view_locals: { current_organisation: organisation }).save
    end
  end

  context "duplication warning based on phone_number with persisted user, phone just changed" do
    before do
      allow(DuplicateUsersFinderService).to receive(:perform).with(user).and_return(duplicate_users_mock)
    end

    let!(:user) do
      u = create(:user, first_name: "Jean", last_name: "Jacques", phone_number: nil)
      u.phone_number = "0101010101"
      u
    end
    let!(:existing_user) { create(:user, first_name: "Jeannot", phone_number: "0101010101") }
    let(:duplicate_users_mock) { [OpenStruct.new(severity: :warning, attributes: [:phone_number], user: existing_user)] }

    it "is not valid" do
      user_form = described_class.new(user, view_locals: { current_organisation: organisation })
      expect(user_form.valid?).to eq false
      expect(user_form.warnings).to be_present
      expect(user_form.warnings[:base]).to be_present
      expect(user_form.warnings[:base][0]).to include("Jeannot")
      expect(user_form.warnings[:base][0]).to include("Un usager avec le même numéro de téléphone existe déjà")
    end

    it "does not save the user" do
      expect(user).not_to receive(:save)
      described_class.new(user, view_locals: { current_organisation: organisation }).save
    end
  end

  context "duplication warning based on phone_number with persisted user, phone did not change" do
    before do
      allow(DuplicateUsersFinderService).to receive(:perform).with(user).and_return(duplicate_users_mock)
    end

    let!(:user) do
      u = create(:user, first_name: "Jean", last_name: "Jacques", phone_number: "0101010101")
      u.last_name = "Fifou"
      u
    end
    let!(:existing_user) { create(:user, first_name: "Jeannot", phone_number: "0101010101") }
    let(:duplicate_users_mock) { [OpenStruct.new(severity: :warning, attributes: [:phone_number], user: existing_user)] }

    it "is valid" do
      user_form = described_class.new(user, view_locals: { current_organisation: organisation })
      expect(user_form.valid?).to eq true
      expect(user_form.warnings).to be_empty
    end

    it "saves the user" do
      expect(user).to receive(:save)
      described_class.new(user, view_locals: { current_organisation: organisation }).save
    end
  end

  context "duplication warning based on phone number for a user with responsible" do
    before do
      allow(DuplicateUsersFinderService).to receive(:perform).with(user).and_return([])
      allow(DuplicateUsersFinderService).to receive(:perform).with(user.responsible).and_return(duplicate_users_mock)
    end

    let!(:user) { build(:user, first_name: "Paul", last_name: "Jacques", responsible: build(:user, first_name: "Jean", last_name: "Jacques", phone_number: "0101010101")) }
    let!(:existing_user) { create(:user, first_name: "Jeannot", phone_number: "0101010101") }

    let(:duplicate_users_mock) { [OpenStruct.new(severity: :warning, attributes: [:phone_number], user: existing_user)] }

    it "is valid" do
      user_form = described_class.new(user, view_locals: { current_organisation: organisation })
      expect(user_form.valid?).to eq false
      expect(user_form.warnings).to be_present
      expect(user_form.warnings[:base]).to be_present
      expect(user_form.warnings[:base][0]).to include("Jeannot")
      expect(user_form.warnings[:base][0]).to include("Un usager avec le même numéro de téléphone existe déjà")
    end

    it "saves the user" do
      expect(user).not_to receive(:save)
      described_class.new(user, view_locals: { current_organisation: organisation }).save
    end
  end
end
