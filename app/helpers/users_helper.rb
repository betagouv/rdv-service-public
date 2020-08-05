module UsersHelper
  def birth_date_and_age(user)
    return unless user.birth_date

    "#{I18n.l(user.birth_date)} - #{user.age}"
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
      I18n.t("users.soft_delete_confirm_message.relatives", count: user.relatives.active.count),
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
