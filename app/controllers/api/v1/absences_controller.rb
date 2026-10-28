class Api::V1::AbsencesController < Api::V1::AgentAuthBaseController
  before_action :retrieve_absence, only: %i[show update destroy]
  def index
    absences = policy_scope(Absence, policy_scope_class: Agent::AbsencePolicy::Scope)
    render_collection(absences.by_starts_at)
  end

  def create
    absence = Absence.new(create_params)

    # On ne documente pas encore la possibilité d'utiliser le param recurrence, puisqu'on s'en sert uniquement
    # pour la migration des Conseillers Numériques, et que l'api actuelle permettrait de créer des absences qu'on
    # ne saurait pas gérer sur l'interface web avec le formulaire actuel.
    if params[:recurrence].present?
      absence.recurrence = Montrose::Recurrence.load(params[:recurrence])
    end

    authorize(absence, policy_class: Agent::AbsencePolicy) if absence.valid?

    absence.transaction do
      absence.save!

      if params[:external_reference].present?
        ExternalReference.create!(
          params.require(:external_reference).permit(:external_id, :external_url).merge(
            item: absence,
            oauth_application: doorkeeper_token&.application
          )
        )
      end
    end

    render_record absence
  end

  def show
    authorize(@absence, policy_class: Agent::AbsencePolicy)
    render_record @absence
  end

  def update
    authorize(@absence, policy_class: Agent::AbsencePolicy)
    @absence.update!(update_params)
    render_record @absence
  end

  def destroy
    authorize(@absence, policy_class: Agent::AbsencePolicy)
    @absence.destroy!
    head :no_content
  end

  private

  def retrieve_absence
    @absence = Absence.find(params[:id])
  end

  def create_params
    # Allow creating an absence for an agent identified by their email.
    if params[:agent_id].blank? && params[:agent_email].present?
      agent = policy_scope(Agent, policy_scope_class: Agent::AgentPolicy::Scope).find_by(email: params[:agent_email])
      raise ActiveRecord::RecordNotFound unless agent

      params[:agent_id] = agent.id
      params.delete(:agent_email)
    end

    params[:agent_id] ||= current_agent.id

    params.permit(:agent_id, :title, :first_day, :start_time, :end_day, :end_time)
  end

  def update_params
    params.permit(:title, :first_day, :start_time, :end_day, :end_time)
  end
end
