class Agents::Departements::OrganisationsController < AgentDepartementAuthController
  def show
    @organisations_by_departement = policy_scope(Organisation)
      .where(departement: current_departement.number)
      .to_a
      .concat(inaccessible_organisations)
      .group_by(&:departement)
    @organisations_by_departement.values.flatten.each { authorize _1 }
  end

  def update
    orgas = policy_scope(Organisation)
      .where(departement: current_departement.number)
      .where(id: organisations_params.keys)
    orgas.each do |orga|
      authorize(orga)
      orga.update_attributes(human_id: organisations_params[orga.id.to_s][:human_id])
    end
    if orgas.map(&:valid?).all? && orgas.map(&:save!)
      redirect_to departement_organisations_path(current_departement), flash: { success: "Identifiants mis à jour !" }
    else
      @organisations_by_departement = orgas.to_a
        .concat(inaccessible_organisations)
        .group_by(&:departement)
      render :index
    end
  end

  private

  def organisations_params
    params.permit(organisations: [:id, :human_id])
      .to_h[:organisations]
      .values
      .map(&:symbolize_keys)
      .index_by { _1[:id] }
    # will look like {"1"=>{:id=>"1", :human_id=>"arques"}, "2"=>{:id=>"2", :human_id=>"bapaume"}}
  end

  def inaccessible_organisations
    accessible_ones = policy_scope(Organisation)
      .where(departement: current_departement.number)
    Organisation
      .where(departement: current_departement.number)
      .where.not(id: accessible_ones.pluck(:id))
      .to_a
  end
end
