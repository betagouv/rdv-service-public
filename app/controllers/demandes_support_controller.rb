class DemandesSupportController < ApplicationController
  def new
    @form = DemandeSupportForm.new(**demande_params)
  end

  def create
    @form = DemandeSupportForm.new(**demande_params)
    render :new
  end

  private

  def demande_params
    {
      raison: params.dig(:demande_support_form, :raison) || params[:raison],
      message: params.dig(:demande_support_form, :message) || params[:message],
      besoin_contact: params.dig(:demande_support_form, :besoin_contact) || params[:besoin_contact],
      current_domain:,
    }
  end
end
