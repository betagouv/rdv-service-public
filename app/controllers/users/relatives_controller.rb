class Users::RelativesController < UserAuthController
  respond_to :html

  before_action :set_user, only: [:edit, :update, :destroy]

  def create
    @user = User.new(user_params)
    @user.responsible_id = current_user.id
    @user.organisation_ids = current_user.organisation_ids
    authorize(@user)
    flash[:notice] = "#{@user.full_name} a été ajouté comme proche." if @user.save
    location = params[:callback_path].present? ? params[:callback_path] : users_informations_path
    redirect_to location
  end

  def edit
    authorize(@user)
  end

  def update
    authorize(@user)
    if @user.update(user_params)
      flash[:notice] = "Les informations de votre proche #{@user.full_name} ont été mises à jour."
      redirect_to users_informations_path
    else
      render :edit
    end
  end

  def destroy
    authorize(@user)
    flash[:notice] = "Votre proche a été supprimé." if @user.soft_delete
    redirect_to users_informations_path
  end

  private

  def set_user
    @user = policy_scope(User).find(params.require(:id))
  end

  def user_params
    params.require(:user).permit(:first_name, :last_name, :birth_date)
  end
end
