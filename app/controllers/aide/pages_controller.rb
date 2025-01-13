class Aide::PagesController < ApplicationController
  def aiguillage_role
    if params[:role] == "usager"
      redirect_to aide_aiguillage_usager_path
    elsif params[:role] == "agent"
      redirect_to new_aide_demande_support_path(role: :agent)
    end
  end

  def aiguillage_usager
    @form = AiguillageUsagerForm.new(
      raison: params.dig(:aiguillage_usager_form, :raison) || params[:raison],
      besoin_contact: params.dig(:aiguillage_usager_form, :besoin_contact) || params[:besoin_contact]
    )
    if @form.should_redirect_to_demande_support?
      redirect_to new_aide_demande_support_path(role: :usager, sujet: @form.raison_label)
    end
  end
end
