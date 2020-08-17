describe FindDuplicateUsersService, type: :service do
  describe ".perform" do
    it "return empty array when no duplicate" do
      user = build(:user)
      duplicateUsers = FindDuplicateUsersService.perform_with(user)
      expect(duplicateUsers).to eq([])
    end
  end
end
