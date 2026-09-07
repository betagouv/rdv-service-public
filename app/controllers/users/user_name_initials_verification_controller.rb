class Users::UserNameInitialsVerificationController < ApplicationController
  layout "application_narrow"

  def new
    @form = Form.new
  end

  def create
    auth_state = RestrictedAuthSessionState.new(session)

    if auth_state.user.blank?
      flash[:error] = t("devise.invitations.session_expired") # rubocop:disable Rails/ActionControllerFlashBeforeRender
      redirect_to root_path and return
    end

    @form = Form.new(letters: params[:letters]&.strip&.upcase, user: auth_state.user)
    if @form.valid?
      auth_state.user_name_verification_successful!

      redirect_to after_success_redirect_path
    else
      flash.now[:error] = I18n.t("users.user_name_initials_mismatch")
      render :new
    end
  end

  private

  def after_success_redirect_path
    session.delete(:return_to_after_verification) || root_path
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
