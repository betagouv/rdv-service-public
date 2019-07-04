class Rdvs::ThirdStepsController < DashboardAuthController
  def new
    rdv = Rdv.new(query_params)
    @third_step = Rdv::ThirdStep.new(rdv.to_step_params)
    @third_step.organisation = current_pro.organisation
    authorize(@third_step)
  end

  def create
    build_third_step
    authorize(@third_step)
    if @third_step.valid?
      @rdv = @third_step.rdv
      @rdv.save
      redirect_to rdv_path(@rdv), notice: "Le rendez-vous a été créé."
    else
      render 'new'
    end
  end

  private

  def build_third_step
    rdv = Rdv.new(third_step_params)
    @third_step = Rdv::ThirdStep.new(rdv.to_step_params)
    @third_step.organisation = current_pro.organisation
  end

  def third_step_params
    params.require(:rdv).permit(:motif_id, :duration_in_min, :start_at, :user_id)
  end

  def query_params
    params.permit(:motif_id, :duration_in_min, :start_at, :user_id)
  end
end
