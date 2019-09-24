class Rdvs::SecondStepsController < DashboardAuthController
  layout 'application-small'

  def new
    rdv = Rdv.new(query_params)
    rdv.pros << current_pro unless query_params[:pro_ids].present?
    @second_step = Rdv::SecondStep.new(rdv.to_step_params)
    @second_step.start_at ||= Time.zone.now
    @second_step.duration_in_min ||= @second_step.motif.default_duration_in_min
    @second_step.max_users_limit ||= @second_step.motif.max_users_limit
    @second_step.organisation_id = current_pro.organisation_id
    authorize(@second_step)
  end

  def create
    build_second_step
    authorize(@second_step)
    if @second_step.valid?
      redirect_to new_third_step_path(@second_step.to_query)
    else
      render 'new'
    end
  end

  private

  def build_second_step
    rdv = Rdv.new(second_step_params)
    @second_step = Rdv::SecondStep.new(rdv.to_step_params)
    @second_step.organisation_id = current_pro.organisation_id
  end

  def second_step_params
    params.require(:rdv).permit(:motif_id, :duration_in_min, :start_at, :max_users_limit, :location, pro_ids: [])
  end

  def query_params
    params.permit(:motif_id, :duration_in_min, :start_at, :max_users_limit, :location, pro_ids: [])
  end
end
