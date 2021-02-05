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

  def notes
    return nil if @user_profile.nil? || @user_profile.notes.blank?

    simple_format(@user_profile.notes)
  end

  def notify_by_sms
    return "pas de numéro de téléphone renseigné" if @user.responsible_phone_number.blank?

    @user.responsible_notify_by_sms? ? "🟢 Activées" : "🔴 Désactivées"
  end

  def notify_by_email
    return "pas d'email renseigné" if @user.responsible_email.blank?

    @user.responsible_notify_by_email? ? "🟢 Activées" : "🔴 Désactivées"
  end

  def email_and_notification
    return "n/a" unless @user.email

    "#{mail_to(email)} - Notifications par email #{notify_by_email}".html_safe
  end

  def phone_number_and_notification
    return "n/a" unless @user.phone_number

    "#{link_to_phone} - Notifications par SMS #{notify_by_sms}".html_safe
  end

  private

  def link_to_phone
    user = @user.responsible_or_self
    link_to(user.phone_number, "tel:#{user.phone_number_formatted}")
  end
end
