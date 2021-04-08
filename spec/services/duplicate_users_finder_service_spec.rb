describe DuplicateUsersFinderService, type: :service do
  let(:user) { build(:user, first_name: "Mathieu", last_name: "Lapin", email: "lapin@beta.fr", birth_date: "21/10/2000", phone_number: "0658032518") }

  describe ".perform" do
    subject { described_class.new(user).perform }

    context "there is no other user" do
      it { is_expected.to be_empty }
    end

    context "email is nil" do
      let(:user) { build(:user, first_name: "Mathieu", last_name: "Lapin", email: nil) }
      let!(:user_without_email) { create(:user, :with_no_email) }

      it { is_expected.to be_empty }
    end

    context "phone_number is nil" do
      let(:user) { build(:user, first_name: "Mathieu", last_name: "Lapin", phone_number: nil) }
      let!(:user_without_phone_number) { create(:user, phone_number: nil) }

      it { is_expected.to be_nil }
    end

    context "there is an homonym" do
      let!(:homonym_user) { create(:user, first_name: "Mathieu", last_name: "Lapin") }

      it { is_expected.to be_empty }
    end

    context "persisted user" do
      before { user.save! }

      it { is_expected.to be_nil } # to make sure we're not returning self as a duplicate
    end

    context "there is a duplicate" do
      context "same email" do
        let!(:duplicated_user) { create(:user, email: "lapin@beta.fr") }

        it { is_expected.to eq(OpenStruct.new(severity: :error, attributes: [:email], user: duplicated_user)) }

        context "but soft deleted" do
          before { duplicated_user.soft_delete }

          it { is_expected.to be_nil }
        end
      end

      context "same main first_name, last_name, birth_date" do
        let!(:duplicated_user) { create(:user, first_name: "Mathieu", last_name: "Lapin", birth_date: "21/10/2000") }

        it { is_expected.to eq(OpenStruct.new(severity: :error, attributes: [:first_name, :last_name, :birth_date], user: duplicated_user)) }

        context "but soft deleted" do
          before { duplicated_user.soft_delete }

          it { is_expected.to be_nil }
        end
      end

      context "same phone_number" do
        let!(:duplicated_user) { create(:user, phone_number: "0658032518") }

        it { is_expected.to eq(OpenStruct.new(severity: :warning, attributes: [:phone_number], user: duplicated_user)) }

        context "but soft deleted" do
          before { duplicated_user.soft_delete }

          it { is_expected.to be_nil }
        end
      end

      context "multiple account" do
        let!(:duplicated_user1) { create(:user, first_name: "Mathieu", last_name: "Lapin", birth_date: "21/10/2000") }
        let!(:duplicated_user2) { create(:user, phone_number: "0658032518") }
        let!(:rdv) { create(:rdv, users: [duplicated_user1]) }

        it { is_expected.to eq(OpenStruct.new(severity: :error, attributes: [:first_name, :last_name, :birth_date], user: duplicated_user1)) }
        it { is_expected.to eq(OpenStruct.new(severity: :warning, attributes: [:phone_number], user: duplicated_user2)) }

        context "but first soft deleted" do
          before { duplicated_user1.soft_delete }

          it { is_expected.not_to include(OpenStruct.new(severity: :error, attributes: [:first_name, :last_name, :birth_date], user: duplicated_user1)) }
          it { is_expected.to include(OpenStruct.new(severity: :warning, attributes: [:phone_number], user: duplicated_user2)) }
        end

        context "but both soft deleted" do
          before do
            duplicated_user1.soft_delete
            duplicated_user2.soft_delete
          end

          it { is_expected.to be_nil }
        end
      end
    end
  end

  describe "#perform with orga context" do
    subject { described_class.new(user, organisation).perform }

    let(:organisation) { create(:organisation) }

    context "same phone_number duplicate in same orga" do
      let!(:duplicated_user) { create(:user, phone_number: "0658032518", organisations: [organisation]) }

      it { is_expected.to include(OpenStruct.new(severity: :warning, attributes: [:phone_number], user: duplicated_user)) }
    end

    context "same phone_number duplicate in different orga" do
      let!(:duplicated_user) { create(:user, phone_number: "0658032518", organisations: [create(:organisation)]) }

      it { is_expected.to be_empty }
    end

    context "same phone_number duplicate in no orgas" do
      let!(:duplicated_user) { create(:user, phone_number: "0658032518", organisations: []) }

      it { is_expected.to be_empty }
    end
  end

  describe "#perform with only arg" do
    let!(:duplicated_email) { create(:user, email: "lapin@beta.fr") }
    let!(:duplicated_phone_number) { create(:user, phone_number: "0658032518") }

    context "no only passed" do
      it "returns the email duplicate" do
        result = described_class.new(user).perform
        expect(result).not_to be_nil
        expect(result.attributes).to eq([:email])
        expect(result.user).to eq(duplicated_email)
      end
    end

    context "only email passed" do
      it "returns the email duplicate" do
        result = described_class.new(user, only: [:email]).perform
        expect(result).not_to be_nil
        expect(result.attributes).to eq([:email])
        expect(result.user).to eq(duplicated_email)
      end
    end

    context "only phone_number passed" do
      it "returns the phone_number duplicate" do
        result = described_class.new(user, only: [:phone_number]).perform
        expect(result).not_to be_nil
        expect(result.attributes).to eq([:phone_number])
        expect(result.user).to eq(duplicated_phone_number)
      end
    end
  end
end
