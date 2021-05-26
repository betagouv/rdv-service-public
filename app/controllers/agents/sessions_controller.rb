# frozen_string_literal: true

class Agents::SessionsController < Devise::SessionsController
  before_action :exclude_signed_in_users, only: [:new]

  private

  def exclude_signed_in_users
    return true unless user_signed_in?

    redirect_to(
      root_path,
      flash: { error: "Déconnectez-vous d'abord de votre compte usager pour vous connecter en tant qu'agent" }
    )
  end
end
