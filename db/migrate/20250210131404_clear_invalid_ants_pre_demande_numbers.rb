class ClearInvalidAntsPreDemandeNumbers < ActiveRecord::Migration[7.1]
  def up
    users = User.where.not(ants_pre_demande_number: [nil, ""]).select(:id, :ants_pre_demande_number).to_a
    Rails.logger.info "Found #{users.size} users with an ANTS pre-demande number…"
    users_with_invalid_numbers = users.reject { _1.ants_pre_demande_number.strip.upcase.match?(/\A[A-Z0-9]{10}\z/) }
    Rails.logger.info "Found #{users_with_invalid_numbers.size} users with an invalid ANTS pre-demande number…"
    Rails.logger.info "Batch update these users to clear their ANTS numbers…"
    User
      .where(id: users_with_invalid_numbers.map(&:id))
      .update_all(ants_pre_demande_number: nil)
    Rails.logger.info "Success ✅"
  end
end
