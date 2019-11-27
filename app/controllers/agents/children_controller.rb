class Agents::ChildrenController < AgentAuthController

  def show
    @user = policy_scope(User).find(params[:id])
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
    @user = policy_scope(User).find(params[:id])
    authorize(@user)
  end

  def update
    @user = policy_scope(User).find(params[:id])
    authorize(@user)
    if @user.update(user_params)
      flash[:notice] = "Les informations de l'enfant #{@user.full_name} ont été mises à jour."
      redirect_to organisation_child_path(current_organisation, @user)
    else
      render :edit
    end
  end

  private
  def user_params
    params.require(:user).permit(:first_name, :last_name, :birth_date)
  end
end
