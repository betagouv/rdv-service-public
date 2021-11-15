# frozen_string_literal: true

class Admin::RdvsController < AgentAuthController
  respond_to :html, :json

  before_action :set_rdv, :set_optional_agent, except: %i[index create]

  def index
    @form = Admin::RdvSearchForm.new(
      start: parse_date_from_params(:start),
      end: parse_date_from_params(:end),
      show_user_details: %w[1 true].include?(params[:show_user_details]),
      **params.permit(:organisation_id, :agent_id, :user_id, :lieu_id, :status)
    )
    @rdvs = policy_scope(Rdv).merge(@form.rdvs)
    @breadcrumb_page = params[:breadcrumb_page]
    @filters = params[:filters]
    @title = params[:title]
    respond_to do |format|
      format.xls { send_data(RdvExporter.export(@rdvs.order(starts_at: :desc)), filename: "rdvs.xls", type: "application/xls") }
      format.html { @rdvs = @rdvs.order(starts_at: :asc).page(params[:page]) }
    end
  end

  def show
    @uncollapsed_section = params[:uncollapsed_section]
    authorize(@rdv)
  end

  def edit
    @rdv_form = Admin::EditRdvForm.new(@rdv, pundit_user)
    authorize(@rdv_form.rdv)
  end

  def update
    authorize(@rdv)
    @rdv_form = Admin::EditRdvForm.new(@rdv, pundit_user)
    success = @rdv_form.update(**rdv_params.to_h.symbolize_keys)
    respond_to do |format|
      format.js
      format.html do
        if success
          flash[:notice] = if rdv_params[:status].in? %w[excused revoked]
                             "Le rendez-vous a été annulé."
                           else
                             "Le rendez-vous a été modifié."
                           end
          redirect_to admin_organisation_rdv_path(current_organisation, @rdv, agent_id: params[:agent_id])
        else
          render :edit
        end
      end
    end
  end

  def destroy
    authorize(@rdv)
    if @rdv.destroy
      flash[:notice] = "Le rendez-vous a été supprimé."
    else
      flash[:error] = "Une erreur s’est produite, le rendez-vous n’a pas pu être supprimé."
      Sentry.capture_exception(Exception.new("Deletion failed for rdv : #{@rdv.id}"))
    end
    # TODO : redirection makes no sense when coming from a users#show
    redirect_to admin_organisation_agent_agenda_path(current_organisation, @agent || current_agent)
  end

  private

  def set_optional_agent
    @agent = policy_scope(Agent).find(params[:agent_id]) if params[:agent_id].present?
  end

  def parse_date_from_params(param_name)
    return nil if params[param_name].blank? || params[param_name] == "__/__/____"

    Date.parse(params[param_name])
  end

  def set_rdv
    @rdv = Rdv.find(params[:id])
  end

  def rdv_params
    params.require(:rdv).permit(:motif_id, :status, :lieu_id, :duration_in_min, :starts_at, :context, :active_warnings_confirm_decision, agent_ids: [], user_ids: [])
  end

  def status_params
    params.require(:rdv).permit(:status)
  end
end
