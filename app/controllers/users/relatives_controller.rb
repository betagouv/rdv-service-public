class Users::RelativesController < UserAuthController
  layout "application_narrow"

  respond_to :html

  before_action :set_user, only: %i[edit update destroy]

  def new
    @user = current_user.relatives.new
    authorize(@user, policy_class: User::UserPolicy)
    respond_modal_with @user
  end

  def create
    @user = User.new(user_params)
    @user.created_through = "user_relative_creation"
    @user.responsible_id = current_user.id
    @user.organisation_ids = current_user.organisation_ids
    authorize(@user, policy_class: User::UserPolicy)
    return_location = request.referer
    if @user.save
      flash[:success] = "#{@user.full_name} a été ajouté comme proche."
      return_location = add_query_string_params_to_url(request.referer, created_user_id: @user.id)
    end
    respond_modal_with @user, location: return_location
  end

  def edit
    authorize(@user, policy_class: User::UserPolicy)
  end

  def update
    authorize(@user, policy_class: User::UserPolicy)
    if @user.update(user_params)
      flash[:success] = "Les informations de votre proche #{@user.full_name} ont été mises à jour."
      redirect_to users_informations_path
    else
      render :edit
    end
  end

  def destroy
    authorize(@user, policy_class: User::UserPolicy)
    flash[:notice] = "Votre proche a été supprimé." if @user.soft_delete
    redirect_to users_informations_path
  end

  private

  def set_user
    @user = policy_scope(User, policy_scope_class: User::UserPolicy::Scope).find(params.require(:id))
  end

  def user_params
    params.require(:user).permit(:first_name, :last_name, :birth_date, :ants_pre_demande_number)
  end
end
