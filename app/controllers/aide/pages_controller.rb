class Aide::PagesController < ApplicationController
  def aiguillage_role
    if params[:role] == "usager"
      redirect_to aide_aiguillage_usager_path
    elsif params[:role] == "agent"
      redirect_to aide_aiguillage_agent_path
    end
  end

  def aiguillage_usager
    raison = params.dig(:aiguillage_usager_form, :raison) || params[:raison]
    @form = AiguillageUsagerForm.new(raison:)
    if @form.should_redirect_to_demande_support?
      redirect_to new_aide_demande_support_path(role: :usager, sujet: @form.raison_label)
    end
  end

  def aiguillage_agent
    raison = params.dig(:aiguillage_agent_form, :raison) || params[:raison]
    @form = AiguillageAgentForm.new(raison:)
    if @form.should_redirect_to_demande_support?
      redirect_to new_aide_demande_support_path(role: :agent, sujet: @form.raison_label)
    end
  end
end
