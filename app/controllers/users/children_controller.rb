class Users::ChildrenController < UserAuthController
  before_action :set_user, only: [:edit, :update]

  def new
    @user = User.new(parent_id: current_user.id)
    authorize(@user)
  end

  def create
    @user = User.new(user_params)
    @user.parent_id = current_user.id
    @user.organisation_ids = current_user.organisation_ids
    authorize(@user)
    if @user.save
      flash[:notice] = "#{@user.full_name} a été ajouté comme enfant."
      redirect_to users_informations_path
    else
      render :new
    end
  end

  def edit
    authorize(@user)
  end

  def update
    authorize(@user)
    if @user.update(user_params)
      flash[:notice] = "Les informations de l'enfant #{@user.full_name} ont été mises à jour."
      redirect_to users_informations_path
    else
      render :edit
    end
  end

  def destroy
    authorize(@user)
    flash[:notice] = "L'enfant a été supprimé." if @user.soft_delete(current_organisation)
    redirect_to organisation_user_path(current_organisation, @user.parent)
  end

  private

  def set_user
    @user = policy_scope(User).find(params.require(:id))
  end

  def user_params
    params.require(:user).permit(:first_name, :last_name, :birth_date)
  end
end
