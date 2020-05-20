module UsersHelper
  def birth_date_and_age(user)
    return unless user.birth_date

    "#{I18n.l(user.birth_date)} - #{user.age}"
  end

  def relative_tag(user)
    user.relative? ? content_tag(:span, 'Proche', class: 'badge badge-info') : nil
  end

  def full_name_and_birthdate(user)
    label = user.full_name
    label += " - #{birth_date_and_age(user)}" if user.birth_date
    label
  end

  def agent_user_form_url(user)
    if user.persisted?
      organisation_user_path(current_organisation, user)
    else
      organisation_users_path(current_organisation)
    end
  end
end
