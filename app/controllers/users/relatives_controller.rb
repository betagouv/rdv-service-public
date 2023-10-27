# frozen_string_literal: true

class Users::RelativesController < UserAuthController
  respond_to :html

  before_action :set_user, only: %i[edit update destroy]

  def new
    @user = current_user.relatives.new
    @requires_ants_predemande_number = params[:requires_ants_predemande_number].to_boolean
    authorize(@user)
    respond_modal_with @user
  end

  def create
    @user = User.new(user_params)
    @user.created_through = "user_relative_creation"
    @user.responsible_id = current_user.id
    @user.organisation_ids = current_user.organisation_ids
    authorize(@user)
    return_location = request.referer
    if @user.save
      flash[:notice] = "#{@user.full_name} a été ajouté comme proche."
      return_location = add_query_string_params_to_url(request.referer, created_user_id: @user.id)
    end
    respond_modal_with @user, location: return_location
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
    params.require(:user).permit(:first_name, :last_name, :birth_date, :ants_pre_demande_number)
  end
end
