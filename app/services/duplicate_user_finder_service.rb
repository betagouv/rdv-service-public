class DuplicateUserFinderService
  attr_reader :user

  def initialize(user)
    @user = user
  end

  def perform
    same_phone = @user.phone_number.present? ? User.where(phone_number: @user.phone_number) : User.none
    duplicate_data = if @user.birth_date.present? && @user.first_name.present? && @user.last_name.present?
                       User.where(first_name: @user.first_name.capitalize, last_name: @user.last_name.upcase, birth_date: @user.birth_date)
                     else
                       User.none
                     end

    User.find_by(email: @user.email) ||
      same_phone.or(duplicate_data)
                .left_joins(:rdvs)
                .group(:id)
                .order('COUNT(rdvs.id) DESC')
                .first
  end
end
