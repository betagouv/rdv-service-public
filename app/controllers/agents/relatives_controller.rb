class Agents::RelativesController < AgentAuthController
  before_action :set_user, only: [:show, :edit, :update, :destroy]

  def show
    authorize(@user)
  end

  def new
    responsible = policy_scope(User).find(params[:user_id])
    @user = User.new(responsible: responsible)
    @user.organisation_ids = responsible.organisation_ids
    authorize(@user)
  end

  def create
    responsible = policy_scope(User).find(params[:user_id])
    @user = User.new(user_params)
    @user.responsible = policy_scope(User).find(params[:user_id])
    @user.organisation_ids = responsible.organisation_ids
    authorize(@user)
    if @user.save
      flash[:notice] = "#{@user.full_name} a été ajouté comme proche."
      redirect_to organisation_user_path(current_organisation, responsible)
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
      flash[:notice] = "Les informations de votre proche #{@user.full_name} ont été mises à jour."
      redirect_to organisation_relative_path(current_organisation, @user)
    else
      render :edit
    end
  end

  def destroy
    authorize(@user)
    flash[:notice] = "Votre proche a été supprimé." if @user.soft_delete
    redirect_to organisation_user_path(current_organisation, @user.responsible)
  end

  private

  def set_user
    @user = policy_scope(User).find(params[:id])
  end

  def user_params
    params.require(:user).permit(:first_name, :last_name, :birth_date, :notes)
  end
end
