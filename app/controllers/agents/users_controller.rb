class Agents::UsersController < AgentAuthController
  respond_to :html, :json

  before_action :set_organisation, only: [:new, :create]
  before_action :set_user, except: [:index, :search, :new, :create, :link_to_organisation]

  helper_method :from_modal?

  def index
    @users = policy_scope(User).order_by_last_name.page(params[:page])
    filter_users if params[:user] && params[:user][:search]
  end

  def search
    @users = policy_scope(User).where.not(id: params[:exclude_ids]).order_by_last_name.limit(10)
    if search_params
      @users = @users.search_by_name_or_email(search_params)
    end
    skip_authorization
  end

  def new
    @user = User.new
    @user.organisation_ids = [current_organisation.id]
    authorize(@user)
    respond_modal_with @user
  end

  def create
    prepare_create
    authorize(@user)
    @user_to_compare = DuplicateUserFinderService.new(@user).perform
    return create_from_modal if from_modal?

    if @user_to_compare.present?
      @user_not_in_organisation = @user_to_compare.organisation_ids.exclude?(current_organisation.id)
      render :compare
    else
      @user.skip_confirmation_notification!
      if @user.save
        flash[:notice] = "L'usager a été créé."
        redirect_to organisation_user_path(@organisation, @user)
      else
        render :new
      end
    end
  end

  def show
    authorize(@user)
    respond_modal_with @user
  end

  def edit
    authorize(@user)
    respond_modal_with @user if from_modal?
  end

  def update
    authorize(@user)
    @user.created_or_updated_by_agent = true
    @user.skip_reconfirmation! if @user.encrypted_password.blank?
    flash[:notice] = "L'usager a été modifié." if @user.update(user_params)
    if from_modal?
      respond_modal_with @user, location: request.referer
    else
      respond_right_bar_with @user, location: organisation_user_path(current_organisation, @user)
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
    flash[:notice] = "L'usager a été supprimé." if @user.soft_delete(current_organisation)
    redirect_to organisation_users_path(current_organisation)
  end

  def link_to_organisation
    @user = User.find(params.require(:id))
    authorize(current_organisation)
    flash[:notice] = "L'usager a été associé à votre organisation." if @user.add_organisation(current_organisation)
    redirect_to organisation_user_path(current_organisation, @user)
  end

  private

  def create_from_modal
    if @user_to_compare.present?
       @user.errors.add(:base, "il y a un doublon")
    else
      @user.save
    end
    # TODO change with Adispasqual PR
    respond_modal_with @user, location: request.referer.to_s + "&user_ids[]=#{@user.id}"
  end

  def prepare_create
    @user = User.new(user_params)
    @user.organisation_ids = [current_organisation.id]
    @user.invited_by = current_agent
    @user.created_or_updated_by_agent = true
    @organisation = current_organisation
  end

  def filter_users
    @users = @users.search_by_name_or_email(params[:user][:search])
    respond_to do |format|
      format.js { render partial: 'search-results' }
    end
  end

  def from_modal?
    params[:modal].present?
  end

  def user_params
    params.require(:user).permit(:first_name, :last_name, :birth_name, :email, :phone_number, :birth_date, :address, :caisse_affiliation, :affiliation_number, :family_situation, :number_of_children, :logement, :invite_on_create, :notes)
  end

  def search_params
    params.require(:term) unless params[:term].blank?
  end

  def set_user
    @user = policy_scope(User).find(params[:id])
  end
end
