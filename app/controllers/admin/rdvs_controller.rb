class Admin::RdvsController < AgentAuthController
  include RdvsHelper

  respond_to :html, :json

  before_action :set_rdv, :set_optional_agent, except: %i[index create export participations_export]
  # Ce mécanisme temporaire est mis en place afin d'assurer une rétro-compatibilité du fait
  # du changement de noms (ou ajout des s) aux paramètres motif_id, lieu_id et scoped_organisation_id
  # Pour plus de contexte, voir https://github.com/betagouv/rdv-service-public/pull/4054#discussion_r1489720373
  before_action do
    params[:motif_ids] ||= Array(params[:motif_id])
    params[:lieu_ids] ||= Array(params[:lieu_id])
    params[:scoped_organisation_ids] ||= Array(params[:scoped_organisation_id])
  end

  def index
    set_scoped_organisations
    @breadcrumb_page = params[:breadcrumb_page]

    order = { starts_at: :asc }
    @rdvs = policy_scope(Rdv, policy_scope_class: Agent::RdvPolicy::Scope).search_for(@scoped_organisations, parsed_params)
      .order(order).page(page_number).per(10)

    # On fait cette requête en deux temps pour éviter de faire un `order` et un `include` sur le même scope,
    # parce que ça fait un sort et beaucoup de left outer joins
    @rdvs_in_page = Rdv.where(id: @rdvs.pluck(:id)).order(order).includes(
      [
        :agents_rdvs, :organisation, :lieu, :motif,
        {
          participations: [{ user: :user_profiles }],
          agents: :services,
          users: %i[responsible organisations user_profiles],
        },
      ]
    )

    @form = Admin::RdvSearchForm.new(parsed_params)
    @lieux = Lieu.joins(:organisation).where(organisations: { id: @scoped_organisations.select(:id) }).enabled.ordered_by_name
    @motifs = Motif.joins(:organisation).where(organisations: { id: @scoped_organisations.select(:id) }).ordered_by_name
  end

  def export
    skip_authorization # RDV will be scoped in SendExportJob
    set_scoped_organisations

    RdvsExportJob.perform_later(
      agent: current_agent,
      organisation_ids: @scoped_organisations.ids,
      options: parsed_params
    )
    flash[:notice] = t("layouts.flash.confirm_export_queued_html", exports_path: agents_exports_path)
    redirect_to admin_organisation_rdvs_path(organisation_id: current_organisation.id)
  end

  def participations_export
    skip_authorization # RDV will be scoped in SendExportJob
    set_scoped_organisations

    ParticipationsExportJob.perform_later(
      agent: current_agent,
      organisation_ids: @scoped_organisations.ids,
      options: parsed_params
    )
    flash[:notice] = t("layouts.flash.confirm_export_queued_html", exports_path: agents_exports_path)
    redirect_to admin_organisation_rdvs_path(organisation_id: current_organisation.id)
  end

  def show
    @uncollapsed_section = params[:uncollapsed_section]
    authorize(@rdv, policy_class: Agent::RdvPolicy)
  end

  def edit
    add_user_ids = params[:add_user].to_a + params[:user_ids].to_a
    users_to_add = User.where(id: add_user_ids)
    users_to_add.ids.each { @rdv.participations.build(user_id: _1) }

    @rdv_form = Admin::EditRdvForm.new(@rdv, pundit_user)
    authorize(@rdv_form.rdv, policy_class: Agent::RdvPolicy)
  end

  def update
    authorize(@rdv, policy_class: Agent::RdvPolicy)
    @rdv_form = Admin::EditRdvForm.new(@rdv, pundit_user)
    @success = @rdv_form.update(**rdv_params.to_h.symbolize_keys)
    respond_to do |format|
      format.js do
        if @success
          flash.now[:notice] = "Rendez-vous mis à jour"
        else
          flash.now[:error] = @rdv.errors.full_messages.to_sentence
        end
        render "admin/rdvs/update"
      end
      format.html do
        if @success
          redirect_to admin_organisation_rdv_path(current_organisation, @rdv, agent_id: params[:agent_id]), rdv_success_flash
        else
          render :edit
        end
      end
    end
  end

  def send_reminder_manually
    authorize(@rdv, :update?, policy_class: Agent::RdvPolicy)

    Notifiers::RdvUpcomingReminder.perform_with(@rdv, nil)

    redirect_to admin_organisation_rdv_path, flash: { notice: I18n.t("admin.receipts.reminder_manually_sent") }
  end

  def destroy
    authorize(@rdv, policy_class: Agent::RdvPolicy)
    if @rdv.destroy
      flash[:notice] = "Le rendez-vous a été supprimé."
      redirect_to admin_organisation_rdvs_path(current_organisation)
    else
      flash[:error] = @rdv.errors.full_messages.to_sentence
      redirect_to admin_organisation_rdv_path(current_organisation, @rdv)
    end
  end

  private

  def set_scoped_organisations
    @selected_organisations_ids = params[:scoped_organisation_ids]&.compact_blank
    accessible_organisations = policy_scope(Organisation, policy_scope_class: Agent::OrganisationPolicy::Scope)
    @scoped_organisations = if @selected_organisations_ids.blank?
                              # l'agent n'a pas accès au filtre d'organisations ou a réinitialisé la page
                              # Nous sélectionnons par défaut l'organisation courante
                              @selected_organisations_ids = [current_organisation.id]
                              accessible_organisations.where(id: current_organisation.id)
                            elsif @selected_organisations_ids.include?("0")
                              # l'agent a sélectionné 'Toutes' parmi les options
                              @selected_organisations_ids = ["0"]
                              accessible_organisations
                            else
                              # l'agent a sélectionné une ou plusieurs organisations spécifiques
                              accessible_organisations.where(id: @selected_organisations_ids)
                            end

    # An empty scope means the agent tried to access a foreign organisation
    raise Pundit::NotAuthorizedError unless @scoped_organisations.any?
  end

  def set_optional_agent
    @agent = policy_scope(Agent, policy_scope_class: Agent::AgentPolicy::Scope).find(params[:agent_id]) if params[:agent_id].present?
  end

  def parse_date_from_params(date_param)
    Date.parse(date_param)
  rescue Date::Error
    nil
  end

  def set_rdv
    @rdv = policy_scope(Rdv, policy_scope_class: Agent::RdvPolicy::Scope).find(params[:id])
  end

  def rdv_params
    allowed_params = params.require(:rdv).permit(:motif_id, :status, :lieu_id, :duration_in_min, :starts_at, :context, :ignore_benign_errors, :max_participants_count, :name,
                                                 agent_ids: [],
                                                 user_ids: [],
                                                 participations_attributes: %i[user_id send_lifecycle_notifications send_reminder_notification id _destroy],
                                                 lieu_attributes: %i[name address latitude longitude id])

    # Quand un lieu ponctuel est saisi, il faut faire en sorte qu'il soit créé dans l'organisation courante.
    # Nous le faisons ici, côté serveur pour empêcher de spécifier une valeur arbitraire.
    if allowed_params[:lieu_attributes].present?
      allowed_params[:lieu_attributes][:organisation] = current_organisation
      allowed_params[:lieu_attributes][:availability] = :single_use
    end

    allowed_params
  end

  def parsed_params
    params.permit(:organisation_id, :agent_id, :user_id, :status, :start, :end,
                  lieu_attributes: %i[name address latitude longitude], motif_ids: [], lieu_ids: [], scoped_organisation_ids: []).to_hash.to_h do |param_name, param_value|
      case param_name
      when "start", "end"
        [param_name, parse_date_from_params(param_value)]
      else
        [param_name, param_value]
      end
    end
  end

  def rdv_success_flash
    {
      notice: if rdv_params[:status].in?(Rdv::CANCELLED_STATUSES)
                I18n.t("admin.rdvs.message.success.cancel")
              else
                I18n.t("admin.rdvs.message.success.update")
              end,
    }
  end
end
