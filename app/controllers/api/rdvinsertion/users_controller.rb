class Api::Rdvinsertion::UsersController < Api::Rdvinsertion::AgentAuthBaseController
  before_action :set_user, only: [:show]

  def show
    render_record @user, agent_context: fake_agent_context
  end

  private

  def set_user
    @user = User.find(params[:id])
    authorize @user
  end

  # Pour pouvoir récupérer les ids de toutes les organisations rdv_insertion auxquelles l'usager appartient,
  # on s'appuie sur l'option agent_context que prend en compte le `UserBlueprint`. Pour récupérer tous les organisation ids,
  # il faut un contexte d'un agent appartenant à toutes les organisations rdvi de l'usager. Comme il n'y en a pas toujours,
  # on simule un agent appartenant à toutes ces organisations. Cette endpoint ne pouvant être appelé que par l'appli rdv-insertion,
  # on considère que c'est ok. Voir https://github.com/betagouv/rdv-service-public/pull/4495#issuecomment-2344176006
  def fake_agent_context
    AgentOrganisationContext.new(object_faking_agent_belonging_in_all_user_rdvi_orgs, nil)
  end

  def object_faking_agent_belonging_in_all_user_rdvi_orgs
    OpenStruct.new(organisation_ids: @user.organisations.select(&:rdv_insertion?).map(&:id))
  end
end
