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

  def agent_user_form_div_toggle_opts(user)
    {
      relative: {
        "data-target": "agents--user-form--responsability.toggleDiv",
        "data-responsability-type": "relative",
        "class": ("d-none" if user.responsability_type != :relative)
      },
      responsible: {
        "data-target": "agents--user-form--responsability.toggleDiv",
        "data-responsability-type": "responsible",
        "class": ("d-none" if user.responsability_type != :responsible)
      },
    }
  end

  def agent_user_form_input_toggle_opts(user)
    hash = {}
    [:responsible, :relative, :relative_new, :relative_existing].each do |key|
      hash[key] = {
        input_html: {
          "data-target": "agents--user-form--responsability.toggleInput",
          "data-responsability-type": key == :responsible ? "responsible" : "relative",
        }
      }
    end
    hash[:responsible][:disabled] = user.responsability_type != :responsible
    hash[:relative][:disabled] = user.responsability_type != :relative
    hash[:relative_new][:disabled] = !(user.responsability_type == :relative && user.responsible.new_and_blank?)
    hash[:relative_new]["data-relative-type".to_sym] = "new"
    hash[:relative_existing][:disabled] = !(user.responsability_type == :relative && !user.responsible.new_and_blank?)
    hash[:relative_existing]["data-relative-type".to_sym] = "existing"
    hash
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
