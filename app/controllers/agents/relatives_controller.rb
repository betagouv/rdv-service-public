class Agents::RelativesController < AgentAuthController
  respond_to :html, :json

  before_action :set_user, only: [:show, :edit, :update, :destroy]

  helper_method :from_modal?

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
    respond_modal_with @user if from_modal?
  end

  def update
    authorize(@user)
    if @user.update(user_params)
      flash[:notice] = "Les informations de votre proche #{@user.full_name} ont été mises à jour."
      if from_modal?
        respond_modal_with @user, location: request.referer
      else
        redirect_to organisation_relative_path(current_organisation, @user)
      end
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

  def from_modal?
    params[:modal].present?
  end

  def set_user
    @user = policy_scope(User).find(params[:id])
  end

  def user_params
    params.require(:user).permit(:first_name, :last_name, :birth_date, :notes)
  end
end
