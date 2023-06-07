# frozen_string_literal: true

class Users::RdvWizardStepsController < UserAuthController
  RDV_PERMITTED_PARAMS = [:starts_at, :motif_id, :context, { user_ids: [] }].freeze
  EXTRA_PERMITTED_PARAMS = [
    :lieu_id, :departement, :where, :created_user_id, :latitude, :longitude, :city_code, :rdv_collectif_id,
    :street_ban_id, :invitation_token, :address, :motif_search_terms, :user_selected_organisation_id,
    :public_link_organisation_id,
    { organisation_ids: [], referent_ids: [], external_organisation_ids: [] },
  ].freeze
  after_action :allow_iframe
  before_action :set_step_titles

  include TokenInvitable

  def new
    @rdv_wizard = rdv_wizard_for(current_user, query_params)
    @rdv = @rdv_wizard.rdv
    authorize(@rdv)
    if @rdv_wizard.creneau.present?
      render current_step
    else
      flash[:error] = "Ce créneau n'est plus disponible. Veuillez en sélectionner un autre."
      redirect_to(prendre_rdv_path(@rdv_wizard.to_query))
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
    raise "Invalid step: #{step.inspect}" unless step.in?(UserRdvWizard::STEPS)

    step
  end

  def next_step_index
    idx = current_step_index + 2 # steps start at 1 + increment
    idx += 1 if current_step_index.zero? && current_user.only_invited? # we skip the step 2 in the context of an invitation
    idx
  end

  def set_step_titles
    @step_titles = (0..3).map do |idx|
      I18n.t("users.rdv_wizard_steps.step#{idx}.title") unless idx == 2 && current_user.only_invited?
    end.compact
  end

  def current_step_index
    UserRdvWizard::STEPS.index(current_step)
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
                    :email,
                    :address,
                    :caisse_affiliation,
                    :affiliation_number,
                    :family_situation,
                    :number_of_children,
                    :notify_by_email,
                    :notify_by_sms,
                    :ants_pre_demande_number,
                    { user_profiles_attributes: %i[logement id organisation_id] },
                  ])
  end
end
