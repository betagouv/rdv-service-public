RSpec.describe SearchPotentialDuplicateJob, type: :job do
  describe "#perform" do
    it "should call mark_first_potential_duplicate_service" do
      user = create(:user)
      SearchPotentialDuplicateJob.perform_now(user.id)
    end
  end
end
