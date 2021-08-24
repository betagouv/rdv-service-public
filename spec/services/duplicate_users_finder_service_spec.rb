# frozen_string_literal: true

describe DuplicateUsersFinderService, type: :service do
  describe ".find_duplicate_based_on_email" do
    it "return nil when email is nil" do
      user = build(:user, first_name: "Mathieu", last_name: "Lapin", email: nil)
      create(:user, :with_no_email)

      expect(described_class.find_duplicate_based_on_email(user)).to be_nil
    end

    it "return a duplicate when email already exist" do
      duplicated_user = create(:user, email: "lapin@beta.fr")
      user = build(:user, email: "lapin@beta.fr")

      expect(described_class.find_duplicate_based_on_email(user)).to eq(duplicated_user)
    end

    it "return nil if duplicated email is soft_deleted" do
      duplicated_user = create(:user, email: "lapin@beta.fr")
      duplicated_user.soft_delete
      user = build(:user, email: "lapin@beta.fr")

      expect(described_class.find_duplicate_based_on_email(user)).to be_nil
    end

    it "return a duplicate when new responsible email already exist" do
      duplicated_user = create(:user, email: "lapin@beta.fr")
      responsible = build(:user, email: "lapin@beta.fr")
      user = build(:user, responsible: responsible)

      expect(described_class.find_duplicate_based_on_email(user)).to eq(duplicated_user)
    end
  end

  describe ".find_duplicate" do
    it "return nothing when no other users" do
      user = build(:user, first_name: "Mathieu", last_name: "Lapin", phone_number: nil)
      expect(described_class.find_duplicate(user)).to be_empty
    end
  end

  shared_examples "find duplicate" do
    describe ".find_duplicate" do
      subject { described_class.find_duplicate(user) }

      context "phone_number is nil" do
        let(:user) { build(:user, first_name: "Mathieu", last_name: "Lapin", phone_number: nil) }
        let!(:user_without_phone_number) { create(:user, phone_number: nil) }

        it { is_expected.to be_empty }
      end

      context "there is an homonym" do
        let!(:homonym_user) { create(:user, first_name: "Mathieu", last_name: "Lapin") }

        it { is_expected.to be_empty }
      end

      context "persisted user" do
        before { user.save! }

        it { is_expected.to be_empty } # to make sure we're not returning self as a duplicate
      end

      context "there is a duplicate" do
        context "same main first_name, last_name, birth_date" do
          let!(:duplicated_user) { create(:user, first_name: "Mathieu", last_name: "Lapin", birth_date: "21/10/2000") }

          it { is_expected.to include(duplicated_user) }

          context "but soft deleted" do
            before { duplicated_user.soft_delete }

            it { is_expected.to be_empty }
          end
        end

        context "same phone_number" do
          let!(:duplicated_user) { create(:user, phone_number: "0658032518") }

          it { is_expected.to include(duplicated_user) }

          context "but soft deleted" do
            before { duplicated_user.soft_delete }

            it { is_expected.to be_empty }
          end
        end

        context "multiple account" do
          let!(:duplicated_user1) { create(:user, first_name: "Mathieu", last_name: "Lapin", birth_date: "21/10/2000") }
          let!(:duplicated_user2) { create(:user, phone_number: "0658032518") }
          let!(:rdv) { create(:rdv, users: [duplicated_user1]) }

          it { is_expected.to include(duplicated_user1) }
          it { is_expected.to include(duplicated_user2) }

          context "but first soft deleted" do
            before { duplicated_user1.soft_delete }

            it { is_expected.not_to include(duplicated_user1) }
            it { is_expected.to include(duplicated_user2) }
          end

          context "but both soft deleted" do
            before do
              duplicated_user1.soft_delete
              duplicated_user2.soft_delete
            end

            it { is_expected.to be_empty }
          end
        end
      end
    end
  end

  context "for user" do
    let(:user) { build(:user, first_name: "Mathieu", last_name: "Lapin", email: "lapin@beta.fr", birth_date: "21/10/2000", phone_number: "0658032518") }

    it_behaves_like "find duplicate"
  end

  context "for user with responsible" do
    let(:responsible) { build(:user, first_name: "Mathieu", last_name: "Lapin", email: "lapin@beta.fr", birth_date: "21/10/2000", phone_number: "0658032518") }
    let(:user) { build(:user, responsible: responsible) }

    it_behaves_like "find duplicate"
  end

  describe "#find_duplicate_based_on_phone_number with orga context" do
    subject { described_class.find_duplicate_based_on_phone_number(user, organisation) }

    let(:user) { build(:user, first_name: "Mathieu", last_name: "Lapin", email: "lapin@beta.fr", birth_date: "21/10/2000", phone_number: "0658032518") }
    let(:organisation) { create(:organisation) }

    context "same phone_number duplicate in same orga" do
      let!(:duplicated_user) { create(:user, phone_number: "0658032518", organisations: [organisation]) }

      it { is_expected.to eq(duplicated_user) }
    end

    context "same phone_number duplicate in different orga" do
      let!(:duplicated_user) { create(:user, phone_number: "0658032518", organisations: [create(:organisation)]) }

      it { is_expected.to be_nil }
    end

    context "same phone_number duplicate in no orgas" do
      let!(:duplicated_user) { create(:user, phone_number: "0658032518", organisations: []) }

      it { is_expected.to be_nil }
    end
  end
end
