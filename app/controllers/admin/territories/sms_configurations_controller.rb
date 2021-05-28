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
    if current_departement_not_allowed_to_configure_sms?
      redirect_to action: :show,
                  alert: "Vous ne pouvez pas modifier la configuration d'envoie de SMS tant que votre département n'a pas de marché distinct"
    end
  end

  def current_departement_not_allowed_to_configure_sms?
    ENV["DEPARTEMENT_ALLOWED_TO_CONFIGURE_SMS"].split.exclude?(current_territory.departement_number)
  end

  def sms_configuration_params
    sms_configuration = {}
    Territory::BASE_SMS_CONFIGURATION.each do |provider, config_fields|
      sms_configuration[provider] = {}
      config_fields.each do |config_field|
        sms_configuration[provider][config_field] = params[provider][config_field] if params[provider].present? && params[provider][config_field].present?
      end
    end

    params.require(:territory).permit(:sms_provider).merge(sms_configuration: sms_configuration.compact)
  end
end
