# frozen_string_literal: true

class Users::RdvWizardStepsController < UserAuthController
  RDV_PERMITTED_PARAMS = [:starts_at, :motif_id, :context, { user_ids: [] }].freeze
  EXTRA_PERMITTED_PARAMS = %i[lieu_id departement where created_user_id latitude longitude city_code street_ban_id].freeze
  after_action :allow_iframe
  skip_before_action :authenticate_user!, if: :current_user_set?

  def new
    @rdv_wizard = rdv_wizard_for(current_user, query_params)
    @rdv = @rdv_wizard.rdv
    authorize(@rdv)
    if @rdv_wizard.creneau.present?
      render current_step
    else
      flash[:error] = "Ce créneau n'est plus disponible. Veuillez en sélectionner un autre."
      redirect_to lieux_path(search: @rdv_wizard.to_query)
    end
  end

  def create
    @rdv_wizard = rdv_wizard_for(current_user, rdv_params.merge(user_params))
    @rdv = @rdv_wizard.rdv
    skip_authorization
    if @rdv_wizard.valid? && @rdv_wizard.save
      redirect_to new_users_rdv_wizard_step_path(@rdv_wizard.to_query.merge(step: next_step_index))
    else
      render current_step
    end
  end

  protected

  def current_step
    return UserRdvWizard::STEPS.first if params[:step].blank?

    step = "step#{params[:step]}"
    raise InvalidStep unless step.in?(UserRdvWizard::STEPS)

    step
  end

  def next_step_index
    UserRdvWizard::STEPS.index(current_step) + 2 # steps start at 1 + increment
  end

  def rdv_wizard_for(current_user, request_params)
    klass = "UserRdvWizard::#{current_step.camelize}".constantize
    klass.new(current_user, request_params)
  end

  def rdv_params
    params.require(:rdv).permit(*RDV_PERMITTED_PARAMS).merge(params.permit(*EXTRA_PERMITTED_PARAMS))
  end

  def query_params
    params.permit(*RDV_PERMITTED_PARAMS, *EXTRA_PERMITTED_PARAMS)
  end

  def user_params
    params.permit(user: [
                    :first_name,
                    :last_name,
                    :birth_name,
                    :phone_number,
                    :birth_date,
                    :address,
                    :caisse_affiliation,
                    :affiliation_number,
                    :family_situation,
                    :number_of_children,
                    :notify_by_email,
                    :notify_by_sms,
                    { user_profiles_attributes: %i[logement id organisation_id] }
                  ])
  end
end
