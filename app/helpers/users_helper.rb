module UsersHelper
  def birth_date_and_age(user)
    return unless user.birth_date

    "#{I18n.l(user.birth_date)} - #{user.age}"
  end

  def full_name_and_birthdate(user)
    label = user.full_name
    label += " - #{birth_date_and_age(user)}" if user.birth_date
    label
  end

  def full_name(user)
    "#{user.first_name} #{user.last_name}"
  end

  def user_show_path(user)
    user.relative? ? organisation_relative_path(current_organisation, user) : organisation_user_path(current_organisation, user)
  end
end
