describe FindDuplicateUsersService, type: :service do
  describe ".perform" do
    it "return empty array when no duplicate" do
      assert_duplication_found(build(:user), [])
    end

    it "return user that match perfectly with given user" do
      organisation = create(:organisation)
      user = create(:user, first_name: "André", last_name: "André", organisations: [organisation])
      duplicate = create(:user, first_name: "André", last_name: "Andrée", organisations: [organisation])
      assert_duplication_found(user, [duplicate])
    end

    it "not return a user that to different" do
      organisation = create(:organisation)
      user = create(:user, first_name: "André", last_name: "André", organisations: [organisation])
      create(:user, first_name: "Stéphane", last_name: "Henri", organisations: [organisation])
      assert_duplication_found(user, [])
    end

    it "match with monsieur in the name" do
      organisation = create(:organisation)
      user = create(:user, organisations: [organisation], first_name: "Monsieur / Madame Jean", last_name: "JACQUES")
      duplicate = create(:user, organisations: [organisation], first_name: "Monsieur / Madame Jean", last_name: "JACQUS")
      assert_duplication_found(user, [duplicate])
    end

    it "not match, even with monsieur / madame" do
      organisation = create(:organisation)
      user = create(:user, organisations: [organisation], first_name: "Monsieur / Madame Jean", last_name: "JACQUES")
      duplicate = create(:user, organisations: [organisation], first_name: "Monsieur / Madame Jean", last_name: "JANY")
      assert_duplication_found(user, [])
    end
  end

  def assert_duplication_found(user, users)
    duplicateUsers = FindDuplicateUsersService.perform_with(user)
    expect(duplicateUsers).to eq(users)
  end
end
