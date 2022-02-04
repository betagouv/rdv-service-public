# frozen_string_literal: true

class Admin::Territories::SmsConfigurationsController < Admin::Territories::BaseController
  before_action :check_allowed_departement, only: %i[update edit]

  def show; end

  def edit; end

  def update
    current_territory.update(sms_configuration_params)
    redirect_to action: :show
  end

  private

  def check_allowed_departement
    return if current_territory.has_own_sms_provider?

    flash[:alert] = "Vous ne pouvez pas modifier la configuration d'envoi de SMS tant que votre département n’a pas de marché distinct."
    redirect_to action: :show
  end

  def sms_configuration_params
    params.require(:territory).permit(:sms_provider, :sms_configuration)
  end
end
