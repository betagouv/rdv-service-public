module UsersHelper
  def birth_date_and_age(user)
    return unless user.birth_date

    "#{I18n.l(user.birth_date)} - #{age(user)}"
  end

  def age(user)
    years = age_in_years(user)
    return "#{years} ans" if years >= 3

    months = age_in_months(user)
    return "#{months} mois" if months.positive?

    "#{age_in_days(user).to_i} jours"
  end

  def age_in_years(user)
    today = Time.zone.now.to_date
    years = today.year - user.birth_date.year
    if today.month > user.birth_date.month || (today.month == user.birth_date.month && today.day >= user.birth_date.day)
      years
    else
      years - 1
    end
  end

  def age_in_months(user)
    today = Time.zone.now.to_date
    (today.year - user.birth_date.year) * 12 + today.month - user.birth_date.month - (today.day >= user.birth_date.day ? 0 : 1)
  end

  def age_in_days(user)
    Time.zone.now.to_date - user.birth_date
  end

  def relative_tag(user)
    user.relative? ? content_tag(:span, "Proche", class: "badge badge-info") : nil
  end

  def full_name_and_birthdate(user)
    label = user.full_name
    label += " - #{birth_date_and_age(user)}" if user.birth_date
    label
  end

  def user_soft_delete_confirm_message(user)
    [
      "Confirmez-vous la suppression de cet usager ?",
      (I18n.t("users.soft_delete_confirm_message.relatives", count: user.relatives.active.count) if user.relatives.active.any?),
    ].select(&:present?).join("\n\n")
  end
end

class DisplayableUser
  include UsersHelper

  delegate :first_name, :last_name, :birth_name, :address, :affiliation_number, :number_of_children, to: :user

  attr_reader :user

  def initialize(user, organisation)
    @user = user
    @user_profile = @user.profile_for(organisation)
  end

  def birth_date
    birth_date_and_age(@user)
  end

  def caisse_affiliation
    User.human_enum_name(:caisse_affiliation, @user.caisse_affiliation)
  end

  def family_situation
    User.human_enum_name(:family_situation, @user.family_situation)
  end

  def phone_number
    @user.responsible_phone_number
  end

  def email
    @user.responsible_email
  end

  def logement
    return nil unless @user_profile.present?

    UserProfile.human_enum_name(:logement, @user_profile.logement)
  end
end
