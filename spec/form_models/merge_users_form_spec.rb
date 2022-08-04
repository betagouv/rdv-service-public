# frozen_string_literal: true

describe MergeUsersForm, type: :form do
  describe "validations" do
    {
      first_name: %w[Dominique Camille],
      birth_date: [Date.new(1970, 4, 25), Date.new(1980, 6, 25)],
      birth_name: %w[Nicolas Mathieu],
    }.each do |frozen_field, values|
      let(:organisation) { create(:organisation) }
      it "invalid when merge #{frozen_field} on franceConnected user1" do
        user1 = create(:user, frozen_field => values[0], logged_once_with_franceconnect: true)
        user2 = create(:user, frozen_field => values[1])
        merge_users_params = { frozen_field => user2.send(frozen_field) }
        merge_users_form = described_class.new(organisation, user1: user1, user2: user2, **merge_users_params)
        expect(merge_users_form).to be_invalid
      end

      it "invalid when merge #{frozen_field} on franceConnected user2" do
        user2 = create(:user, frozen_field => values[0], logged_once_with_franceconnect: true)
        user1 = create(:user, frozen_field => values[1])
        merge_users_params = { frozen_field => user1.send(frozen_field) }
        merge_users_form = described_class.new(organisation, user1: user1, user2: user2, **merge_users_params)
        expect(merge_users_form).to be_invalid
      end
    end
  end
end
