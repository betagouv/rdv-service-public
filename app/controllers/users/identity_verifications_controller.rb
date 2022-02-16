# frozen_string_literal: true

class Users::IdentityVerificationsController < UserAuthController
  skip_before_action :authenticate_user!
  skip_after_action :verify_authorized

  def new; end

  def create
    if first_three_letters_matching?
      set_user_identity_verified
      redirect_to session[:return_to_after_verification]
    else
      flash.now[:error] = "Les 3 lettres ne correspondent pas au nom de famille."
      render :new
    end
  end

  private

  def letter_params
    params.permit(:letter0, :letter1, :letter2)
  end

  def first_three_letters
    letter_params.to_h.values.join.strip
  end

  def first_three_letters_matching?
    current_user.last_name.gsub(/\s+/, "").first(3).upcase == first_three_letters.upcase
  end
end
