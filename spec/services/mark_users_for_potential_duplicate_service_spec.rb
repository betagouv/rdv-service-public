describe MarkUsersForPotentialDuplicateService, type: :service do
  describe ".perform" do
    it "do nothing with an empty list" do
      users = []
      result = MarkUsersForPotentialDuplicateService.perform_with(users)
      expect(result).to be_falsy
    end
  end
end

