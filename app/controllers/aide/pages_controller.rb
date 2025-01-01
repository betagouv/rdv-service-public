class Aide::PagesController < ApplicationController
  def aiguillage_role
    if params[:role] == "usager"
      redirect_to aide_documentation_usager_path
    elsif params[:role] == "agent"
      redirect_to new_aide_demande_support_path(role: :agent)
    end
  end

  def documentation_usager; end

  def aiguillage_usager
    @form = AiguillageUsagerForm.new(
      raison: params.dig(:aiguillage_usager_form, :raison) || params[:raison],
      besoin_contact: params.dig(:aiguillage_usager_form, :besoin_contact) || params[:besoin_contact]
    )
    if @form.should_redirect_to_demande_support?
      redirect_to new_aide_demande_support_path(role: :usager, sujet: @form.raison_label)
    end
  end

  def annuaire
    territories_with_phone_number = Territory.where.not(phone_number_formatted: nil)
    territories_group_by_department = territories_with_phone_number
      .where(departement_number: Territory::DEPARTEMENTS_NAMES.keys)
      .order(:departement_number).ordered_by_name.group_by(&:departement_number)

    territories_without_department = territories_with_phone_number
      .where.not(departement_number: Territory::DEPARTEMENTS_NAMES.keys)
      .ordered_by_name

    render locals: {
      territories_group_by_department: territories_group_by_department,
      territories_without_department: territories_without_department,
    }
  end
end
