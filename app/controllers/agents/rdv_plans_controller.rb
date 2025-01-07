class Agents::RdvPlansController < AgentAuthController
  layout "application"

  def new
    @rdv_plan = current_agent.rdv_plans.new

    if params[:user_id]
      # TODO: use a proper policy without current context here
      @rdv_plan.users = [User.find(params[:user_id])]
    end

    authorize @rdv_plan, :edit?, policy_class: Agent::RdvPlanPolicy
    render "edit_motif"
  end

  def create
    update_motif
  end

  def edit_motif
    find_rdv_plan
  end

  def update_motif
    @rdv_plan = RdvPlan.find_by(id: params[:id]) || RdvPlan.new
    authorize @rdv_plan, :edit?, policy_class: Agent::RdvPlanPolicy

    user_id = params.require(:rdv_plan)[:user_id]
    if user_id.present?
      # TODO: ajouter un check sur la policy des users
      @rdv_plan.participations.build(user_id: user_id)
    end
    # On réinitialise le lieu si on change le motif
    if params.dig(:rdv_plan, :motif_id).to_i != @rdv_plan.motif_id
      @rdv_plan.lieu_id = nil
    end

    @rdv_plan.assign_attributes(params.require(:rdv_plan).permit(:motif_id).merge(agent: current_agent))

    if @rdv_plan.save
      if @rdv_plan.motif.requires_lieu?
        if @rdv_plan.organisation.lieux.enabled.count > 1
          redirect_to edit_lieu_agents_rdv_plan_path(@rdv_plan)
        else
          @rdv_plan.update(lieu: @rdv_plan.organisation.lieux.enabled.first)

          # TODO: extraire ça dans une méthode ?
          @search_form = AgentCreneauxSearchForm.build_from(@rdv_plan)

          @next_availabilities = if @rdv_plan.motif.individuel?
                                   CreneauxSearch::ForAgent.new(@search_form).next_availabilities
                                 else
                                   CreneauxSearch::RdvCollectifForAgent.new(@search_form).next_availabilities
                                 end

          # TODO: gérer le cas de pas de créneaux
          redirect_to edit_creneau_agents_rdv_plan_path(@rdv_plan, from: @next_availabilities.first.starts_at.to_date)
        end
      else
        redirect_to edit_creneau_agents_rdv_plan_path(@rdv_plan)
      end
    else
      render "edit_motif"
    end
  end

  def edit_lieu
    # TODO: est-ce que cette étape est nécessaire s'il n'y a qu'un seul lieu ? ça peut être une amélioration plus tard
    find_rdv_plan
    @rdv_plan.lieu_id = nil

    @search_form = AgentCreneauxSearchForm.build_from(@rdv_plan)

    @next_availabilities = if @rdv_plan.motif.individuel?
                             CreneauxSearch::ForAgent.new(@search_form).next_availabilities
                           else
                             CreneauxSearch::RdvCollectifForAgent.new(@search_form).next_availabilities
                           end
  end

  def update_lieu
    find_rdv_plan
    if @rdv_plan.update(params.require(:rdv_plan).permit(:lieu_id))
      redirect_to edit_creneau_agents_rdv_plan_path(@rdv_plan, from: params.dig(:rdv_plan, :from_date))
    else
      render "edit_lieu"
    end
  end

  def edit_creneau
    find_rdv_plan
    @search_form = AgentCreneauxSearchForm.build_from(@rdv_plan, from_date: params[:from])

    @results = if @rdv_plan.motif.individuel?
                 CreneauxSearch::ForAgent.new(@search_form).build_result
               else
                 CreneauxSearch::RdvCollectifForAgent.new(@search_form).slot_search
               end
  end

  def update_creneau
    find_rdv_plan
    if @rdv_plan.update(params.require(:rdv_plan).permit(:starts_at, :rdv_agent_id))
      redirect_to edit_user_agents_rdv_plan_path(@rdv_plan)
    else
      render "edit_creneau"
    end
  end

  def edit_user
    find_rdv_plan
  end

  def create_rdv
    find_rdv_plan

    flash[:success] = "Le rendez-vous a été créé."

    redirect_to rdv_agents_rdv_plan_path(@rdv_plan)
  end

  def rdv
    find_rdv_plan
  end

  private

  def find_rdv_plan
    @rdv_plan = current_agent.rdv_plans.find(params[:id])
    authorize @rdv_plan, :edit?, policy_class: Agent::RdvPlanPolicy
  end

  def pundit_user
    current_agent
  end
end
