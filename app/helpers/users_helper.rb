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

  def user_details(user, *attributes, li_class: nil)
    displayable_user = DisplayableUser.new(user)
    attributes.map do |attr_name|
      content_tag(:li, class: li_class) do
        content_tag(:strong, "#{t("activerecord.attributes.user.#{attr_name}")} : ") +
          content_tag(:span, displayable_user.send(attr_name))
      end
    end.join.html_safe
  end
end

class DisplayableUser
  include UsersHelper

  delegate :first_name, :last_name, :birth_name, :address, :affiliation_number, :number_of_children, to: :user

  attr_reader :user

  def initialize(user)
    @user = user
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

  def logement
    User.human_enum_name(:logement, @user.logement)
  end

  def phone_number
    @user.responsible_phone_number
  end

  def email
    @user.responsible_email
  end
end
