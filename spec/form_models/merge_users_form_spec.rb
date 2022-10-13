# frozen_string_literal: true

describe MergeUsersForm, type: :form do
  let(:organisation) { create(:organisation) }

  it "is valid when no franceConnected user" do
    user1 = create(:user, logged_once_with_franceconnect: false)
    user2 = create(:user, logged_once_with_franceconnect: false)
    merge_users_params = { email: "1", first_name: "1", last_name: "1", birth_name: "1", birth_date: "1", phone_number: "2", address: "2" }
    merge_users_form = described_class.new(organisation, user1: user1, user2: user2, **merge_users_params)
    expect(merge_users_form).to be_valid
  end

  it "is valid when franceconencted user frozen fields are selected" do
    user2 = create(:user, birth_name: "Henri", first_name: "Bob", birth_date: Date.new(2000, 11, 13), logged_once_with_franceconnect: true)
    user1 = create(:user, birth_name: nil, first_name: "Bob", birth_date: Date.new(2000, 11, 13))
    merge_users_params = { email: "1", first_name: "2", last_name: "1", birth_name: "2", birth_date: "2", phone_number: "1", address: "2" }
    merge_users_form = described_class.new(organisation, user1: user1, user2: user2, **merge_users_params)
    expect(merge_users_form).to be_valid
  end

  it "is invalid when not franceconnected user frozen fields are selected" do
    user1 = create(:user, first_name: "Malika", last_name: "PAUL", email: nil, phone_number: "01 23 23 23 23", birth_date: "1967-07-05", birth_name: "GONE", logged_once_with_franceconnect: nil)
    user2 = create(:user, first_name: "Malika", last_name: "GONE", email: "exemple@mail.com", phone_number: nil, birth_date: "1994-12-22", birth_name: "GONE", logged_once_with_franceconnect: true)
    merge_users_params = { email: "1", first_name: "1", last_name: "1", birth_name: "1", birth_date: "1", phone_number: "2", address: "2" }
    merge_users_form = described_class.new(organisation, user1: user1, user2: user2, **merge_users_params)
    expect(merge_users_form).to be_invalid
  end

  it "is invalid when two users logged once with franceconnect" do
    user1 = create(:user, logged_once_with_franceconnect: true, franceconnect_openid_sub: "unechainedecharacteres", organisations: [organisation])
    user2 = create(:user, logged_once_with_franceconnect: true, franceconnect_openid_sub: "uneautrechainedecharacteres", organisations: [organisation])
    merge_users_params = { email: "1", first_name: "2", last_name: "1", birth_name: "1", birth_date: "1", phone_number: "2", address: "2" }
    merge_users_form = described_class.new(organisation, user1: user1, user2: user2, **merge_users_params)
    expect(merge_users_form).to be_invalid
  end
end
