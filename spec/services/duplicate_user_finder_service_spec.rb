describe DuplicateUserFinderService, type: :service do
  describe '.perform' do
    let(:user) { build(:user, first_name: 'Mathieu', last_name: 'Lapin', email: 'lapin@beta.fr', birth_date: '21/10/2000', phone_number: '0658032518') }

    subject { DuplicateUserFinderService.new(user).perform }

    context 'there is no other user' do
      it { should be_nil }
    end

    context 'email is nil' do
      let(:user) { build(:user, first_name: 'Mathieu', last_name: 'Lapin', email: nil) }
      let!(:user_without_email) { create(:user, :with_no_email) }
      it { should be_nil }
    end

    context 'there is an homonym' do
      let!(:homonym_user) { create(:user, first_name: 'Mathieu', last_name: 'Lapin') }
      it { should be_nil }
    end

    context 'there is an duplicate' do
      context 'same email' do
        let!(:duplicated_user) { create(:user, email: 'lapin@beta.fr') }
        it { should eq(duplicated_user) }

        context 'but soft deleted' do
          before { duplicated_user.soft_delete }
          it { should be_nil }
        end
      end

      context 'same main first_name, last_name, birth_date' do
        let!(:duplicated_user) { create(:user, first_name: 'Mathieu', last_name: 'Lapin', birth_date: '21/10/2000') }
        it { should eq(duplicated_user) }

        context 'but soft deleted' do
          before { duplicated_user.soft_delete }
          it { should be_nil }
        end
      end

      context 'same phone_number' do
        let!(:duplicated_user) { create(:user, phone_number: '0658032518') }
        it { should eq(duplicated_user) }

        context 'but soft deleted' do
          before { duplicated_user.soft_delete }
          it { should be_nil }
        end
      end

      context 'multiple account' do
        let!(:duplicated_user_1) { create(:user, phone_number: '0658032518') }
        let!(:duplicated_user_2) { create(:user, first_name: 'Mathieu', last_name: 'Lapin', birth_date: '21/10/2000') }
        let!(:rdv) { create(:rdv, users: [duplicated_user_1]) }
        it { should eq(duplicated_user_1) }

        context 'but first soft deleted' do
          before { duplicated_user_1.soft_delete }
          it { should eq(duplicated_user_2) }
        end

        context 'but both soft deleted' do
          before do
            duplicated_user_1.soft_delete
            duplicated_user_2.soft_delete
          end
          it { should be_nil }
        end
      end
    end
  end
end
