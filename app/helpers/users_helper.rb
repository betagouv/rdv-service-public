module UsersHelper
  def birth_date_and_age(user)
    return unless user.birth_date

    "#{l(user.birth_date)} - #{user.age}"
  end

  def formatted_phone_number(user)
    user.phone_number.chars.each_slice(2).map(&:join).join(' ') unless user.phone_number.blank?
  end

  def user_show_path(user)
    user.child? ? organisation_child_path(current_organisation, user) : organisation_user_path(current_organisation, user)
  end

end
