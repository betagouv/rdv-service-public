# frozen_string_literal: true

class Admin::RdvsController < AgentAuthController
  include RdvsHelper

  respond_to :html, :json

  before_action :set_rdv, :set_optional_agent, except: %i[index create export rdvs_users_export]

  def index
    set_scoped_organisations
    @breadcrumb_page = params[:breadcrumb_page]

    order = { starts_at: :asc }
    @rdvs = policy_scope(Rdv).search_for(@scoped_organisations, parsed_params)
      .order(order).page(params[:page]).per(10)

    # On fait cette requête en deux temps pour éviter de faire un `order` et un `include` sur le même scope,
    # parce que ça fait un sort et beaucoup de left outer joins
    @rdvs_in_page = Rdv.where(id: @rdvs.pluck(:id)).order(order).includes(
      [
        :agents_rdvs, :organisation, :lieu, :motif,
        {
          rdvs_users: [:prescripteur, { user: :user_profiles }],
          agents: :service,
          users: %i[responsible organisations user_profiles],
        },
      ]
    )

    @form = Admin::RdvSearchForm.new(parsed_params)
    @lieux = Lieu.joins(:organisation).where(organisations: { id: @scoped_organisations.select(:id) }).enabled.order(:name)
    @motifs = Motif.joins(:organisation).where(organisations: { id: @scoped_organisations.select(:id) })
  end

  def export
    skip_authorization # RDV will be scoped in SendExportJob
    set_scoped_organisations

    Agents::ExportMailer.rdv_export(
      current_agent,
      @scoped_organisations.ids,
      parsed_params
    ).deliver_later
    flash[:notice] = I18n.t("layouts.flash.confirm_export_send_when_done", agent_email: current_agent.email)
    redirect_to admin_organisation_rdvs_path(organisation_id: current_organisation.id)
  end

  def rdvs_users_export
    authorize(current_agent)
    set_scoped_organisations

    Agents::ExportMailer.rdvs_users_export(
      current_agent,
      @scoped_organisations.ids,
      parsed_params
    ).deliver_later
    flash[:notice] = I18n.t("layouts.flash.confirm_rdvs_users_export_send_when_done", agent_email: current_agent.email)
    redirect_to admin_organisation_rdvs_path(organisation_id: current_organisation.id)
  end

  def show
    @uncollapsed_section = params[:uncollapsed_section]
    authorize(@rdv)
  end

  def edit
    add_user_ids = params[:add_user].to_a + params[:user_ids].to_a
    users_to_add = User.where(id: add_user_ids)
    users_to_add.ids.each { @rdv.rdvs_users.build(user_id: _1) }

    @rdv_form = Admin::EditRdvForm.new(@rdv, pundit_user)
    authorize(@rdv_form.rdv)
  end

  def update
    authorize(@rdv)
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
    authorize(@rdv, :update?)

    Notifiers::RdvUpcomingReminder.perform_with(@rdv, nil)

    redirect_to admin_organisation_rdv_path, flash: { notice: I18n.t("admin.receipts.reminder_manually_sent") }
  end

  def destroy
    authorize(@rdv)
    if @rdv.soft_delete
      flash[:notice] = "Le rendez-vous a été supprimé."
      redirect_to admin_organisation_rdvs_path(current_organisation)
    else
      flash[:error] = @rdv.errors.full_messages.to_sentence
      redirect_to admin_organisation_rdv_path(current_organisation, @rdv)
    end
  end

  private

  def set_scoped_organisations
    @scoped_organisations = if params[:scoped_organisation_id].blank?
                              # l'agent n'a pas accès au filtre d'organisations ou a réinitialisé la page
                              policy_scope(Organisation).where(id: current_organisation.id)
                            elsif params[:scoped_organisation_id] == "0"
                              # l'agent a sélectionné 'Toutes'
                              policy_scope(Organisation)
                            else
                              # l'agent a sélectionné une organisation spécifique
                              policy_scope(Organisation).where(id: parsed_params["scoped_organisation_id"])
                            end

    # An empty scope means the agent tried to access a foreign organisation
    raise Pundit::NotAuthorizedError unless @scoped_organisations.any?
  end

  def set_optional_agent
    @agent = policy_scope(Agent).find(params[:agent_id]) if params[:agent_id].present?
  end

  def parse_date_from_params(date_param)
    return nil if date_param.blank? || date_param == "__/__/____"

    Date.parse(date_param)
  end

  def set_rdv
    @rdv = policy_scope(Rdv).find(params[:id])
  end

  def rdv_params
    allowed_params = params.require(:rdv).permit(:motif_id, :status, :lieu_id, :duration_in_min, :starts_at, :context, :ignore_benign_errors, :max_participants_count, :name,
                                                 agent_ids: [],
                                                 user_ids: [],
                                                 rdvs_users_attributes: %i[user_id send_lifecycle_notifications send_reminder_notification id _destroy],
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
    params.permit(:organisation_id, :agent_id, :user_id, :lieu_id, :motif_id, :status, :start, :end, :scoped_organisation_id,
                  lieu_attributes: %i[name address latitude longitude]).to_hash.to_h do |param_name, param_value|
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
