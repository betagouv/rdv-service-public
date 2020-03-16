class Agents::ChildrenController < AgentAuthController
  before_action :set_user, only: [:show, :edit, :update, :destroy]

  def show
    authorize(@user)
  end

  def new
    parent = policy_scope(User).find(params[:user_id])
    @user = User.new(parent: parent)
    @user.organisation_ids = parent.organisation_ids
    authorize(@user)
  end

  def create
    parent = policy_scope(User).find(params[:user_id])
    @user = User.new(user_params)
    @user.parent = policy_scope(User).find(params[:user_id])
    @user.organisation_ids = parent.organisation_ids
    authorize(@user)
    if @user.save
      flash[:notice] = "#{@user.full_name} a été ajouté comme enfant."
      redirect_to organisation_user_path(current_organisation, parent)
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
      redirect_to organisation_child_path(current_organisation, @user)
    else
      render :edit
    end
  end

  def destroy
    authorize(@user)
    flash[:notice] = "L'enfant a été supprimé." if @user.soft_delete
    redirect_to organisation_user_path(current_organisation, @user.parent)
  end

  private

  def set_user
    @user = policy_scope(User).find(params[:id])
  end

  def user_params
    params.require(:user).permit(:first_name, :last_name, :birth_date, :notes)
  end
end
