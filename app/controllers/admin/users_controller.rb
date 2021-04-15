class Admin::UsersController < AgentAuthController
  respond_to :html, :json

  before_action :set_organisation, only: %i[new create]
  before_action :set_user, except: %i[index search new create link_to_organisation]

  PERMITTED_ATTRIBUTES = %i[
    id
    first_name last_name birth_name email phone_number
    birth_date address caisse_affiliation affiliation_number
    family_situation number_of_children
    notify_by_sms notify_by_email
  ].freeze

  PERMITTED_NESTED_ATTRIBUTES = {
    agent_ids: [],
    user_profiles_attributes: %i[notes logement id organisation_id]
  }.freeze

  def index
    @form = Admin::UserSearchForm.new(**params.permit(:organisation_id, :agent_id, :search))
    @users = policy_scope(User).merge(@form.users).active.order_by_last_name.page(params[:page])
  end

  def search
    @users = policy_scope(User).where.not(id: params[:exclude_ids]).active.order_by_last_name.limit(10)
    @users = @users.search_by_text(search_params) if search_params
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

    @user.invite! if invite_user?(@user, params)
    prepare_new unless user_persisted

    if from_modal?
      respond_modal_with @user_form, location: add_query_string_params_to_url(modal_return_location, 'user_ids[]': @user.id)
    elsif user_persisted
      redirect_to admin_organisation_user_path(@organisation, @user), flash: { notice: "L'usager a été créé." }
    else
      render :new
    end
  end

  def show
    authorize(@user)
    @rdvs = policy_scope(Rdv).merge(@user.rdvs)
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
    @user.invite!
    flash[:notice] = "L'usager a été invité."
    respond_right_bar_with @user, location: admin_organisation_user_path(current_organisation, @user)
  end

  def destroy
    authorize(@user)
    if @user.can_be_soft_deleted_from_organisation?(current_organisation)
      @user.soft_delete(current_organisation)
      flash[:notice] = "L'usager a été supprimé."
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
    redirect_to admin_organisation_user_path(current_organisation, @user)
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
    @user.responsible.user_profiles.build(organisation: current_organisation)
  end

  def prepare_create
    @user = User.new(user_params.merge(invited_by: current_agent, created_through: "agent_creation"))
    @user.responsible.created_through = "agent_creation" if @user.responsible&.new_record?
    @user_form = user_form_object
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
      active_warnings_confirm_decision: params.dig(:user, :active_warnings_confirm_decision),
      view_locals: {
        current_organisation: current_organisation,
        from_modal: from_modal?,
        request_referer: request.referer
      }
    )
  end

  def search_params
    params.require(:term) if params[:term].present?
  end

  def set_user
    @user = policy_scope(User).find(params[:id])
  end
end
