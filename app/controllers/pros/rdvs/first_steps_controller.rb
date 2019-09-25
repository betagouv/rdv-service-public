class Pros::Rdvs::FirstStepsController < DashboardAuthController
  layout 'application-small'

  def new
    rdv = Rdv.new(query_params)
    @first_step = Rdv::FirstStep.new(rdv.to_step_params)
    @first_step.organisation_id = current_pro.organisation_id
    authorize(@first_step)
  end

  def create
    build_first_step
    authorize(@first_step)
    if @first_step.valid?
      redirect_to new_second_step_path(@first_step.to_query)
    else
      render 'new'
    end
  end

  private

  def build_first_step
    rdv = Rdv.new(first_step_params)
    @first_step = Rdv::FirstStep.new(rdv.to_step_params)
    @first_step.organisation_id = current_pro.organisation_id
  end

  def first_step_params
    params.require(:rdv).permit(:motif_id, :starts_at, :location)
  end

  def query_params
    params.permit(:motif_id, :starts_at, :location)
  end
end
