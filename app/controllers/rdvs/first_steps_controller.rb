class Rdvs::FirstStepsController < DashboardAuthController
  def new
    rdv = Rdv.new(query_params)
    @first_step = Rdv::FirstStep.new(rdv.to_step_params)
    @first_step.organisation = current_pro.organisation
    authorize(@first_step)
  end

  def create
    build_first_step
    authorize(@first_step)
    if @first_step.valid?
      redirect_to new_organisation_second_step_path(@first_step.to_query)
    else
      render 'new'
    end
  end

  private

  def build_first_step
    rdv = Rdv.new(first_step_params)
    @first_step = Rdv::FirstStep.new(rdv.to_step_params)
    @first_step.organisation = current_pro.organisation
  end

  def first_step_params
    params.require(:rdv).permit(:evenement_type_id)
  end

  def query_params
    params.permit(:evenement_type_id)
  end
end
