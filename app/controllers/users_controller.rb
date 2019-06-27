class UsersController < DashboardAuthController
  respond_to :html, :json

  before_action :set_organisation, only: [:new, :create]
  before_action :set_user, only: [:edit, :update, :destroy]

  def index
    @users = policy_scope(User).includes(:organisation)
    authorize(@users)
  end

  def show
    @user = policy_scope(Specialite).find(params[:id])
    authorize(@user)
  end

  def new
    @user = User.new
    authorize(@user)
    respond_right_bar_with @user
  end

  def create
    @user = User.new(user_params)
    @user.organisation = current_pro.organisation
    authorize(@user)
    flash[:notice] = "L'usager a été créé." if @user.save
    respond_right_bar_with @user, location: organisation_users_path(@user)
  end

  def edit
    authorize(@user)
    respond_right_bar_with @user
  end

  def update
    authorize(@user)
    flash[:notice] = "L'usager a été modifié." if @user.update(user_params)
    respond_right_bar_with @user, location: organisation_users_path(@user)
  end

  def destroy
    authorize(@user)
    @user.destroy
    redirect_to organisation_users_path(@user.organisation), notice: "L'usager a été supprimé."
  end

  private

  def user_params
    params.require(:user).permit(:first_name, :last_name, :email, :phone_number, :birth_date, :address)
  end

  def set_user
    @user = policy_scope(User).find(params[:id])
  end
end
