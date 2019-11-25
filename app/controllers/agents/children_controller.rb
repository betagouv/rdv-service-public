class Agents::ChildrenController < AgentAuthController
  before_action :set_parent

  def new
    @user = User.new(parent_id: @parent.id)
    @user.organisation_ids = @parent.organisation_ids
    authorize(@user)
  end

  def create
    @user = User.new(user_params)
    @user.parent_id = @parent.id
    @user.organisation_ids = @parent.organisation_ids
    authorize(@user)
    if @user.save
      flash[:notice] = "#{@user.full_name} a été ajouté comme enfant."
      redirect_to edit_organisation_user_path(current_organisation, @parent)
    else
      render :new
    end
  end

  private

  def set_parent
    @parent = policy_scope(User).find(params.require(:user_id))
  end

  def user_params
    params.require(:user).permit(:first_name, :last_name, :birth_date)
  end
end
