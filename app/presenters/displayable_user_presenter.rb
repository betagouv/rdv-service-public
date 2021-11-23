# frozen_string_literal: true

class DisplayableUserPresenter
  include UsersHelper
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::UrlHelper
  include Rails.application.routes.url_helpers

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
    @user.human_attribute_value(:caisse_affiliation)
  end

  def family_situation
    @user.human_attribute_value(:family_situation)
  end

  def phone_number
    @user.responsible_phone_number
  end

  def phone_number_formatted
    @user.responsible_or_self.phone_number_formatted
  end

  def email
    @user.responsible_email
  end

  def logement
    return nil if @user_profile.blank?

    @user_profile.human_attribute_value(:logement)
  end

  def notes
    return nil if @user_profile.nil? || @user_profile.notes.blank?

    simple_format(@user_profile.notes)
  end

  def notify_by_sms
    return "🔴 pas de numéro de téléphone renseigné" if @user.responsible_phone_number.blank?

    return "🔴 le numéro de téléphone renseigné n'est pas un mobile" unless @user.responsible_phone_number_mobile?

    @user.responsible_notify_by_sms? ? "🟢 Activées" : "🔴 Désactivées"
  end

  def notify_by_email
    return "🔴 pas d'email renseigné" if @user.responsible_email.blank?

    @user.responsible_notify_by_email? ? "🟢 Activées" : "🔴 Désactivées"
  end

  def clickable_email
    return "N/A" if email.blank?

    mail_to(email)
  end

  def clickable_phone_number
    return "N/A" if phone_number.blank?

    link_to(phone_number, "tel:#{phone_number_formatted}")
  end
end
