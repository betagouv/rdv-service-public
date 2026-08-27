class Users::UserNameInitialsVerificationController < ApplicationController
  layout "application_narrow"

  def new
    @form = Form.new
  end

  def create
    @form = Form.new(letters: params[:letters]&.strip&.upcase, restricted_auth_token: params[:restricted_auth_token])
    if @form.valid?
      # Cette session sera ensuite utilisée par RestrictedAuthConcern pour connecter l'usager
      session[:restricted_auth] = { invitation_token: params[:restricted_auth_token], expires_at: 10.minutes.from_now }
      redirect_to after_success_redirect_path
    else
      flash.now[:error] = I18n.t("users.user_name_initials_mismatch")
      render :new
    end
  end

  private

  def after_success_redirect_path
    if session[:return_to_after_verification]
      session.delete(:return_to_after_verification)
    else
      root_path
    end
  end

  class Form
    include ActiveModel::Model
    include ActiveModel::Attributes
    attribute :letters, :string
    attribute :restricted_auth_token, :string

    validates :user, presence: true
    validate :letters_match_last_name

    def self.human_attribute_name(attr, _options = {})
      if attr.to_sym == :letters
        "3 premières lettres"
      else
        attr
      end
    end

    def letters_match_last_name
      return if letters == user.last_name.gsub(/\s+/, "").first(3).upcase

      errors.add(:letters, "ne correspondent pas")
    end

    def user
      RestrictedAuth.new(invitation_token: restricted_auth_token).user
    end
  end
end
