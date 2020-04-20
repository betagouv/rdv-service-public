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

  def user_show_path(user)
    user.relative? ? organisation_relative_path(current_organisation, user) : organisation_user_path(current_organisation, user)
  end

  def user_social_attributes(user)
    {
      caisse_affiliation: User.human_enum_name(:caisse_affiliation, user.caisse_affiliation),
      affiliation_number: user.affiliation_number,
      family_situation: User.human_enum_name(:family_situation, user.family_situation),
      number_of_children: user.number_of_children,
      logement: User.human_enum_name(:logement, user.logement),
      working_status: User.human_enum_name(:working_status, user.working_status),
      resource_origin: user.resource_origin,
      resource_amount: user.resource_amount,
      rental_charge: user.rental_charge,
      conjoint_full_name: user.conjoint_full_name,
      conjoint_birth_date: user.conjoint_birth_date,
    }
  end

  def user_general_attributes(user)
    {
      first_name: user.first_name,
      last_name: user.last_name,
      birth_name: user.birth_name,
      birth_date: birth_date_and_age(user),
      phone_number: user.phone_number,
      address: user.address,
      email: user.email,
    }
  end
end
