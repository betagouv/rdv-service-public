RSpec.describe DuplicateUsersFinderService, type: :service do
  describe ".perform" do
    subject(:results) { described_class.new(candidate_user:, within_territory:).perform }

    let(:org_of_existing_user) { create(:organisation) }

    context "when there is no existing user in db" do
      let(:candidate_user) { build(:user, first_name: "Mathieu", last_name: "Lapin", birth_date: "21/10/2000") }
      let(:within_territory) { create(:territory) }

      it { is_expected.to be_empty }
    end

    describe "when the candidate user is already persisted, it should not match itself" do
      let!(:candidate_user) { create(:user, first_name: "Mathieu", last_name: "Lapin", birth_date: "21/10/2000", organisations: [create(:organisation)]) }
      let(:within_territory) { candidate_user.organisations.first.territory }

      it { is_expected.to be_empty }
    end

    describe "finding by identity (first name + last name + birth date)" do
      context "when there is another user within the given territory but with different names" do
        let(:candidate_user) { build(:user, first_name: "Mathieu", last_name: "Lapin") }
        let!(:user_with_different_name) { create(:user, first_name: "Mireille", last_name: "Chasseur", organisations: [create(:organisation)]) }
        let(:within_territory) { user_with_different_name.organisations.first.territory }

        it { is_expected.to be_empty }
      end

      context "when there is an identity match (names AND birth date)" do
        let(:candidate_user) { build(:user, first_name: "Mathieu", last_name: "Lapin", birth_date: "21/10/2000") }
        let!(:homonym_user) { create(:user, first_name: "Mathieu", last_name: "Lapin", birth_date: "21/10/2000", organisations: [create(:organisation)]) }
        let(:within_territory) { homonym_user.organisations.first.territory }

        it { is_expected.to eq([OpenStruct.new(attributes: %i[first_name last_name birth_date], user: homonym_user)]) }

        context "but the user is outside the given territory" do
          let(:within_territory) { create(:territory) }

          it { is_expected.to be_empty }
        end
      end
    end

    describe "finding by phone number" do
      context "when there is another user within the territory but with different phone number" do
        let(:candidate_user) { build(:user, phone_number: "0658032518") }
        let!(:user_with_different_phone_number) { create(:user, phone_number: "0611111111", organisations: [create(:organisation)]) }
        let(:within_territory) { user_with_different_phone_number.organisations.first.territory }

        it { is_expected.to be_empty }
      end

      context "when there is a user with the same phone number" do
        let(:candidate_user) { build(:user, phone_number: "0658032518") }
        let!(:user_with_same_phone_number) { create(:user, phone_number: "0658032518", organisations: [create(:organisation)]) }
        let(:within_territory) { user_with_same_phone_number.organisations.first.territory }

        it { is_expected.to eq([OpenStruct.new(attributes: %i[phone_number], user: user_with_same_phone_number)]) }

        context "but the user is outside the given territory" do
          let(:within_territory) { create(:territory) }

          it { is_expected.to be_empty }
        end
      end
    end

    describe "finding by email" do
      context "when there is another user within the territory with different email" do
        let(:candidate_user) { build(:user, email: "candidat@exemple.fr") }
        let!(:user_with_different_email) { create(:user, email: "autre@autre.com", organisations: [create(:organisation)]) }
        let(:within_territory) { user_with_different_email.organisations.first.territory }

        it { is_expected.to be_empty }
      end

      context "when there is another user within the territory with the same email" do
        let(:candidate_user) { build(:user, email: "candidat@exemple.fr") }
        let!(:user_with_same_email) { create(:user, email: "candidat@exemple.fr", organisations: [create(:organisation)]) }
        let(:within_territory) { user_with_same_email.organisations.first.territory }

        it { is_expected.to eq([OpenStruct.new(attributes: [:email], user: user_with_same_email)]) }
      end

      context "when there is another user OUTSIDE the territory with the same email" do
        let(:candidate_user) { build(:user, email: "candidat@exemple.fr") }
        let!(:user_with_same_email) { create(:user, email: "candidat@exemple.fr", organisations: [create(:organisation)]) }
        let(:within_territory) { create(:territory) }

        it { is_expected.to be_empty }
      end
    end

    describe "finding multiple users with multiple methods" do
      let(:orga) { create(:organisation) }
      let!(:user_with_matching_identity) { create(:user, first_name: "Mathieu", last_name: "Lapin", birth_date: "21/10/2000", organisations: [orga]) }
      let!(:user_with_matching_phone) { create(:user, phone_number: "0658032518", organisations: [orga]) }
      let!(:user_with_matching_email) { create(:user, email: "candidat@exemple.fr", organisations: [orga]) }

      let(:candidate_user) { build(:user, first_name: "Mathieu", last_name: "Lapin", birth_date: "21/10/2000", phone_number: "0658032518", email: "candidat@exemple.fr") }

      let(:within_territory) { orga.territory }

      it "works" do
        expected_results = [
          OpenStruct.new(attributes: %i[first_name last_name birth_date], user: user_with_matching_identity),
          OpenStruct.new(attributes: [:phone_number],                     user: user_with_matching_phone),
          OpenStruct.new(attributes: [:email],                            user: user_with_matching_email),
        ]
        expect(results).to match_array(expected_results)
      end
    end

    describe "soft deletion" do
      let!(:existing_user) { create(:user, first_name: "Mathieu", last_name: "Lapin", birth_date: "21/10/2000", organisations: [create(:organisation)]) }
      let(:candidate_user) { build(:user, first_name: "Mathieu", last_name: "Lapin", birth_date: "21/10/2000") }
      let(:within_territory) { existing_user.organisations.first.territory }

      it "ensures the duplicate is no longer a duplicate" do
        service = described_class.new(candidate_user:, within_territory:)
        expect do
          existing_user.soft_delete!
        end.to change { service.perform.size }.from(1).to(0)
      end
    end
  end

  describe ".find_duplicate_based_on_names_and_phone" do
    subject { described_class.find_duplicate_based_on_names_and_phone(candidate_user:, scope: org_of_existing_user.users) }

    let(:org_of_existing_user) { create(:organisation) }
    let(:candidate_user) { build(:user, first_name: "Mathieu", last_name: "Lapin", phone_number: "0658032518") }

    context "there is no other user" do
      it { is_expected.to be_nil }
    end

    context "there is a duplicate" do
      let!(:duplicated_user) { create(:user, first_name: "Mathieu", last_name: "Lapin", phone_number: "0658032518", organisations: [org_of_existing_user]) }

      it { is_expected.to eq(duplicated_user) }

      context "but soft deleted" do
        before { duplicated_user.soft_delete! }

        it { is_expected.to be_nil }
      end

      context "but outside the given territory" do
        before { duplicated_user.update!(organisations: [create(:organisation, territory: create(:territory))]) }

        it { is_expected.to be_nil }
      end
    end

    context "there is a duplicate with accent and whitespaces" do
      let!(:duplicated_user) { create(:user, first_name: "Mathiéu  ", last_name: " Lapïn ", phone_number: "0658032518", organisations: [org_of_existing_user]) }

      it { is_expected.to eq(duplicated_user) }
    end
  end
end
