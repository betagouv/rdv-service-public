RSpec.describe DuplicateUsersFinderService, type: :service do
  describe ".perform" do
    subject(:results) { described_class.new(candidate_user: candidate_user, in_scope: org_of_existing_user.territory.users).perform }

    let(:org_of_existing_user) { create(:organisation) }

    context "when there is no existing user in db" do
      let(:candidate_user) { build(:user, first_name: "Mathieu", last_name: "Lapin", birth_date: "21/10/2000") }

      it { is_expected.to be_empty }
    end

    describe "when the candidate user is already persisted, it should not match itself" do
      let(:candidate_user) { build(:user, first_name: "Mathieu", last_name: "Lapin", birth_date: "21/10/2000", organisations: [org_of_existing_user]) }

      before { candidate_user.save! }

      it { is_expected.to be_empty }
    end

    describe "finding by identity (first name + last name + birth date)" do
      context "when there is another user within the given orgs but with different names" do
        let(:candidate_user) { build(:user, first_name: "Mathieu", last_name: "Lapin") }
        let!(:user_with_different_name) { create(:user, first_name: "Mireille", last_name: "Chasseur", organisations: [org_of_existing_user]) }

        it { is_expected.to be_empty }
      end

      context "when there is an homonym (names AND birth date)" do
        let(:candidate_user) { build(:user, first_name: "Mathieu", last_name: "Lapin", birth_date: "21/10/2000") }
        let!(:homonym_user) { create(:user, first_name: "Mathieu", last_name: "Lapin", birth_date: "21/10/2000", organisations: [org_of_existing_user]) }

        it { is_expected.to eq([OpenStruct.new(severity: :warning, attributes: %i[first_name last_name birth_date], user: homonym_user)]) }

        context "but the user is outside the given orgs" do
          before { homonym_user.update!(organisations: [create(:organisation, territory: create(:territory))]) }

          it { is_expected.to be_empty }
        end
      end
    end

    describe "finding by phone number" do
      context "when there is another user within the orgs but with different phone number" do
        let(:candidate_user) { build(:user, phone_number: "0658032518") }
        let!(:user_with_different_phone_number) { create(:user, phone_number: "0611111111", organisations: [org_of_existing_user]) }

        it { is_expected.to be_empty }
      end

      context "when there is a user with the same phone number" do
        let(:candidate_user) { build(:user, phone_number: "0658032518") }
        let!(:user_with_same_phone_number) { create(:user, phone_number: "0658032518", organisations: [org_of_existing_user]) }

        it { is_expected.to eq([OpenStruct.new(severity: :warning, attributes: %i[phone_number], user: user_with_same_phone_number)]) }

        context "but the user is outside the given orgs" do
          before { user_with_same_phone_number.update!(organisations: [create(:organisation, territory: create(:territory))]) }

          it { is_expected.to be_empty }
        end
      end
    end

    describe "finding by email" do
      context "when there is another user within the orgs with different email" do
        let(:candidate_user) { build(:user, email: "candidat@exemple.fr") }
        let!(:user_with_different_email) { create(:user, email: "autre@autre.com", organisations: [org_of_existing_user]) }

        it { is_expected.to be_empty }
      end

      context "when there is another user within the scope with the same email" do
        let(:candidate_user) { build(:user, email: "candidat@exemple.fr") }
        let!(:user_with_same_email) { create(:user, email: "candidat@exemple.fr", organisations: [org_of_existing_user]) }

        it { is_expected.to eq([OpenStruct.new(severity: :error, attributes: [:email], user: user_with_same_email)]) }

        context "but soft deleted" do
          before { user_with_same_email.soft_delete! }

          it { is_expected.to be_empty }
        end
      end

      context "when there is another user OUTSIDE the scope with the same email" do
        let(:candidate_user) { build(:user, email: "candidat@exemple.fr") }
        let!(:user_with_same_email) { create(:user, email: "candidat@exemple.fr", organisations: [create(:organisation, territory: create(:territory))]) }

        # TODO: Ce comportement est problématique et sera bientôt corrigé une fois qu'on aura retiré l'unicité sur `users.email`.
        it "ignores the scope :'(" do
          expect(results).to eq([OpenStruct.new(severity: :error, attributes: [:email], user: user_with_same_email)])
        end

        context "but soft deleted" do
          before { user_with_same_email.soft_delete! }

          it { is_expected.to be_empty }
        end
      end
    end

    describe "finding multiple users with multiple methods" do
      let!(:user_with_matching_identity) { create(:user, first_name: "Mathieu", last_name: "Lapin", birth_date: "21/10/2000", organisations: [org_of_existing_user]) }
      let!(:user_with_matching_phone) { create(:user, phone_number: "0658032518", organisations: [org_of_existing_user]) }
      let!(:user_with_matching_email) { create(:user, email: "candidat@exemple.fr", organisations: [org_of_existing_user]) }

      let(:candidate_user) { build(:user, first_name: "Mathieu", last_name: "Lapin", birth_date: "21/10/2000", phone_number: "0658032518", email: "candidat@exemple.fr") }

      it "works" do
        expected_results = [
          OpenStruct.new(severity: :warning, attributes: %i[first_name last_name birth_date], user: user_with_matching_identity),
          OpenStruct.new(severity: :warning, attributes: [:phone_number],                     user: user_with_matching_phone),
          OpenStruct.new(severity: :error,   attributes: [:email],                            user: user_with_matching_email),
        ]
        expect(results).to match_array(expected_results)
      end
    end
  end

  describe ".find_duplicate_based_on_names_and_phone" do
    subject { described_class.find_duplicate_based_on_names_and_phone(user: candidate_user, scope: org_of_existing_user.users) }

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

      context "but outside the given orgs" do
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
