class SearchPotentialDuplicateJob < ApplicationJob
  def perform(user_id)
    user = User.find(user_id)
    MarkFirstPotentialDuplicateService.perform_with(user)
  end
end
