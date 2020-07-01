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

  def user_details(user, organisation, *attributes, li_class: nil, show_empty: true)
    displayable_user = DisplayableUser.new(user, organisation)
    attributes.map do |attr_name|
      next unless show_empty || displayable_user.send(attr_name).present?

      i18n_ns = [:logement, :notes].include?(attr_name.to_sym) ? :user_profile : :user
      content_tag(:li, class: li_class) do
        content_tag(:strong, "#{t("activerecord.attributes.#{i18n_ns}.#{attr_name}")} : ") +
          content_tag(:span, displayable_user.send(attr_name))
      end
    end.join.html_safe
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
    UserProfile.human_enum_name(:logement, @user_profile.logement)
  end
end
