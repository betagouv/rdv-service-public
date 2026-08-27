class Users::UserNameInitialsVerificationController < ApplicationController
  layout "application_narrow"

  def new
    @form = Form.new
  end

  def create
    @form = Form.new(letters: params[:letters]&.strip&.upcase, user: restricted_auth.user)
    if @form.valid?
      cookies.encrypted[:"user_name_initials_verified_#{restricted_auth.user.id}"] = {
        value: true, expires: 10.minutes.from_now,
      }
      redirect_to after_success_redirect_path
    else
      flash.now[:error] = I18n.t("users.user_name_initials_mismatch")
      render :new
    end
  end

  private

  def restricted_auth
    @restricted_auth ||= (session[:restricted_auth].present? ? RestrictedAuth.new(**session[:restricted_auth].symbolize_keys) : nil)
  end

  def after_success_redirect_path
    if session[:return_to_after_verification]
      session.delete(:return_to_after_verification)
    elsif restricted_auth&.rdv
      users_rdv_path(restricted_auth.rdv)
    else
      root_path
    end
  end

  class Form
    include ActiveModel::Model
    include ActiveModel::Attributes
    attribute :letters, :string
    attribute :user

    validate :letters_match_last_name

    def letters_match_last_name
      return if letters == user.last_name.gsub(/\s+/, "").first(3).upcase

      errors.add(:letters, "ne correspondent pas")
    end

    def self.human_attribute_name(attr, _options = {})
      if attr.to_sym == :letters
        "3 premières lettres"
      else
        attr
      end
    end
  end
end
