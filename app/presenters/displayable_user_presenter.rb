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
    @user_profile&.human_attribute_value(:logement)
  end

  def notes
    formatted_user_notes(@user_profile)
  end

  def notify_by_sms
    notify_by_sms_description(@user)
  end

  def notify_by_email
    notify_by_email_description(@user)
  end

  def clickable_email
    clickable_user_email(@user)
  end

  def clickable_phone_number
    clickable_user_phone_number(@user)
  end
end
