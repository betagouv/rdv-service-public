class Agents::UsersController < AgentAuthController
  respond_to :html, :json

  before_action :set_organisation, only: [:new, :create]
  before_action :set_user, except: [:index, :search, :new, :create, :link_to_organisation]

  PERMITTED_ATTRIBUTES = [
    :id,
    :first_name, :last_name, :birth_name, :email, :phone_number,
    :birth_date, :address, :caisse_affiliation, :affiliation_number,
    :family_situation, :number_of_children, :invite_on_create
  ].freeze

  PERMITTED_NESTED_ATTRIBUTES = {
    agent_ids: [],
    user_profiles_attributes: [:notes, :logement, :id, :organisation_id],
  }.freeze

  def index
    @users = policy_scope(User).order_by_last_name.page(params[:page])
    filter_users if params[:user] && params[:user][:search]
  end

  def search
    @users = policy_scope(User).where.not(id: params[:exclude_ids]).order_by_last_name.limit(10)
    @users = @users.search_by_text(search_params) if search_params
    skip_authorization
  end

  def new
    @user = User.new
    @user.user_profiles.build(organisation: current_organisation)
    @user.responsible = policy_scope(User).find(params[:responsible_id]) if params[:responsible_id].present?
    prepare_new
    authorize(@user)
    respond_modal_with @user
  end

  def create
    prepare_create
    authorize(@user)
    return render :compare, **(from_modal? ? { layout: 'modal' } : {}) if duplicate_found?

    @user.skip_confirmation_notification!
    user_persisted = @user.save
    return respond_modal_with @user, location: add_query_string_params_to_url(request.referer, 'user_ids[]': @user.id) if from_modal?

    if user_persisted
      flash[:notice] = "L'usager a été créé."
      redirect_to organisation_user_path(@organisation, @user)
    else
      prepare_new
      render :new
    end
  end

  def show
    authorize(@user)
    respond_modal_with @user if from_modal?
  end

  def edit
    authorize(@user)
    respond_modal_with @user if from_modal?
  end

  def update
    authorize(@user)
    @user.skip_reconfirmation! if @user.encrypted_password.blank?
    user_updated = @user.update(user_params)
    flash[:notice] = "L'usager a été modifié." if user_updated
    return respond_modal_with @user, location: request.referer if from_modal?

    if user_updated
      redirect_to organisation_user_path(current_organisation, @user)
    else
      render :edit
    end
  end

  def invite
    authorize(@user)
    @user.invite!
    flash[:notice] = "L'usager a été invité."
    respond_right_bar_with @user, location: organisation_user_path(current_organisation, @user)
  end

  def destroy
    authorize(@user)
    if Rdv.future.active.where(users: @user.family.pluck(:id), organisation: current_organisation).empty?
      @user.soft_delete(current_organisation)
      flash[:notice] = "L'usager a été supprimé."
    else
      flash[:error] = "L'usager ou ses proches ont des rendez-vous programmés, vous ne pouvez pas le supprimer."
    end

    if @user.relative?
      redirect_to organisation_user_path(current_organisation, @user.responsible)
    else
      redirect_to organisation_users_path(current_organisation)
    end
  end

  def link_to_organisation
    @user = User.find(params.require(:id))
    authorize(current_organisation)
    flash[:notice] = "L'usager a été associé à votre organisation." if @user.add_organisation(current_organisation)
    redirect_to organisation_user_path(current_organisation, @user)
  end

  private

  def duplicate_found?
    @user_to_compare = DuplicateUserFinderService.new(@user).perform

    return false unless @user_to_compare.present?

    @user_not_in_organisation = @user_to_compare.organisation_ids.exclude?(current_organisation.id)
    true
  end

  def prepare_new
    return unless @user.responsible.nil?

    @user.responsible = User.new
    @user.responsible.user_profiles.build(organisation: current_organisation)
  end

  def prepare_create
    @user = User.new(user_params)
    authorize(@user.responsible) if @user.responsible&.persisted?
    @user.invited_by = current_agent
    authorize(@user.responsible) if @user.responsible.present?
    @organisation = current_organisation
  end

  def filter_users
    @users = @users.search_by_text(params[:user][:search])
    respond_to do |format|
      format.js { render partial: 'search-results' }
    end
  end

  def user_params
    params.require(:user).permit(
      *PERMITTED_ATTRIBUTES,
      :responsible_id,
      **PERMITTED_NESTED_ATTRIBUTES,
      responsible_attributes: [PERMITTED_ATTRIBUTES, **PERMITTED_NESTED_ATTRIBUTES]
    )
  end

  def search_params
    params.require(:term) unless params[:term].blank?
  end

  def set_user
    @user = policy_scope(User).find(params[:id])
  end
end
