# frozen_string_literal: true

describe User::ImprovedUnicityErrorConcern do
  context "email is not yet taken" do
    let(:user) { build(:user) }

    it "does not add any errors" do
      expect(user).to be_valid
      expect(user.errors.keys).not_to include(:email)
    end
  end

  context "email is already taken" do
    let!(:existing_user) { create(:user, email: "jean@jacques.fr") }
    let(:user) { build(:user, email: "jean@jacques.fr") }

    it "adds id to errors details" do
      expect(user).not_to be_valid
      expect(user.errors.keys).to include(:email)
      expect(user.errors.details.keys).to include(:email)
      expect(user.errors.details[:email].first["id"]).to eq(existing_user.id)
    end
  end

  context "email is invalid" do
    let(:user) { build(:user, email: "jeanjacquesfr") }

    it "adds id to errors details" do
      expect(user).not_to be_valid
      expect(user.errors.keys).to include(:email)
      expect(user.errors.details.keys).to include(:email)
      expect(user.errors.details[:email].first.keys).not_to include("id")
    end
  end
end
