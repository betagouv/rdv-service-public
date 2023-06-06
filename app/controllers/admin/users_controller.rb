# frozen_string_literal: true

class Admin::UsersController < AgentAuthController
  respond_to :html, :json

  before_action :set_organisation, only: %i[new create]
  before_action :set_user, except: %i[index search new create link_to_organisation]

  PERMITTED_ATTRIBUTES = %i[
    id
    first_name last_name birth_name email phone_number
    birth_date caisse_affiliation affiliation_number
    address post_code city_code city_name
    family_situation number_of_children
    notify_by_sms notify_by_email
    case_number address_details
    notes logement ants_pre_demande_number
  ].freeze

  PERMITTED_NESTED_ATTRIBUTES = {
    agent_ids: [],
  }.freeze

  def index
    agent_id = params[:agent_id]
    search_params = params[:search]

    @users = policy_scope(User)
    @users = @users.none if agent_id.blank? && search_params.blank?
    @users = @users.merge(Agent.find(agent_id).users) if agent_id.present?
    @users = @users.search_by_text(search_params) if search_params.present?
    @users = @users.order_by_last_name.page(params[:page])
  end

  def search
    users = policy_scope(User).where.not(id: params[:exclude_ids]).limit(20)
    @users = search_params[:term].present? ? users.search_by_text(search_params[:term]) : users.none
    skip_authorization
  end

  def new
    @role = params[:role] if params[:role]
    @user = User.new
    @user.user_profiles.build(organisation: current_organisation)
    @user.responsible = policy_scope(User).find(params[:responsible_id]) if params[:responsible_id].present?
    prepare_new
    authorize(@user)
    @user_form = user_form_object
    respond_modal_with @user_form
  end

  def create
    prepare_create
    authorize(@user)
    @user.skip_confirmation_notification!
    user_persisted = @user_form.save

    if invite_user?(@user, params)
      @user.invite!(domain: current_domain)
    end

    prepare_new unless user_persisted

    if from_modal?
      respond_modal_with @user_form, location: add_query_string_params_to_url(modal_return_location, "user_ids[]": @user.id, modal: true)
    elsif user_persisted
      redirect_to admin_organisation_user_path(@organisation, @user), flash: { notice: "L'usager a été créé." }
    else
      render :new
    end
  end

  def show
    authorize(@user)
    @rdvs_users = @user.rdvs_users.where(rdvs: policy_scope(Rdv).merge(@user.rdvs))
    @referent_assignations = @user.referent_assignations.includes(agent: :service)
    respond_modal_with @user if from_modal?
  end

  def edit
    @user_form = user_form_object
    authorize(@user)
    respond_modal_with @user_form if from_modal?
  end

  def update
    @user.assign_attributes(user_params)
    @user_form = user_form_object
    authorize(@user)
    @user.skip_reconfirmation! if @user.encrypted_password.blank?
    user_updated = @user_form.save
    if from_modal?
      respond_modal_with @user_form, location: modal_return_location
    elsif user_updated
      redirect_to admin_organisation_user_path(current_organisation, @user), flash: { notice: "L'usager a été modifié" }
    else
      render :edit
    end
  end

  def invite
    authorize(@user)
    @user.invite!(domain: current_domain)
    redirect_to admin_organisation_user_path(current_organisation, @user), notice: "L’usager a été invité."
  end

  def destroy
    authorize(@user)
    if @user.can_be_soft_deleted_from_organisation?(current_organisation)
      @user.soft_delete(current_organisation)
      flash[:notice] = "L’usager a été supprimé."
    else
      flash[:error] = I18n.t("users.can_not_delete_because_has_future_rdvs")
    end

    if @user.relative?
      redirect_to admin_organisation_user_path(current_organisation, @user.responsible)
    else
      redirect_to admin_organisation_users_path(current_organisation)
    end
  end

  def link_to_organisation
    @user = User.find(params.require(:id))
    authorize(current_organisation)
    flash[:notice] = "L'usager a été associé à votre organisation." if @user.add_organisation(current_organisation)

    if from_modal?
      redirect_to add_query_string_params_to_url(modal_return_location, "user_ids[]": @user.id)
    else
      redirect_to admin_organisation_user_path(current_organisation, @user), flash: { notice: "L'usager a été créé." }
    end
  end

  private

  def modal_return_location
    params[:return_location].presence || request.referer
  end

  def invite_user?(user, params)
    user.persisted? && user.email.present? && (params[:invite_on_create] == "1")
  end

  def prepare_new
    return unless @user.responsible.nil?

    @user.responsible = User.new
  end

  def prepare_create
    @user = User.new(user_params.merge(invited_by: current_agent, created_through: "agent_creation"))
    @user.responsible.created_through = "agent_creation" if @user.responsible&.new_record?
    @user_form = user_form_object
    @user.user_profiles.build(organisation: current_organisation)
    @organisation = current_organisation
  end

  def user_params
    params.require(:user).permit(
      *PERMITTED_ATTRIBUTES,
      :responsible_id,
      **PERMITTED_NESTED_ATTRIBUTES,
      responsible_attributes: [PERMITTED_ATTRIBUTES, { **PERMITTED_NESTED_ATTRIBUTES }]
    )
  end

  def user_form_object
    Admin::UserForm.new(
      @user,
      ignore_benign_errors: params.dig(:user, :ignore_benign_errors),
      view_locals: {
        current_organisation: current_organisation,
        from_modal: from_modal?,
        return_location: params[:return_location],
      }
    )
  end

  def index_params
    @index_params ||= params.permit(:organisation_id, :agent_id, :search)
  end

  def search_params
    @search_params ||= params.permit(:term)
  end

  def set_user
    @user = policy_scope(User).find(params[:id])
  end
end
