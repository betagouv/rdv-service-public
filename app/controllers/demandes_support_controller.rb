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
      role: params.dig(:demande_support_form, :role) || params[:role],
      raison: params.dig(:demande_support_form, :raison) || params[:raison],
      message: params.dig(:demande_support_form, :message) || params[:message],
      current_domain:,
    }
  end
end
