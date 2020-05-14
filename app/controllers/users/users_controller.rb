class Users::UsersController < UserAuthController
  def edit
    @user = current_user
    authorize(@user)
  end

  def update
    @user = current_user
    authorize(@user)
    user_saved = @user.update(user_params)
    if params[:from_wizard].presence && user_saved
      redirect_to new_users_rdv_wizard_step_path(step: 2, **wizard_params)
    elsif params[:from_wizard].presence
      @rdv_wizard = UserRdvWizard::Step1.new(current_user, wizard_params)
      render 'users/rdv_wizard_steps/step1'
    elsif user_saved
      flash[:notice] = "Vos informations ont été mises à jour."
      redirect_to users_informations_path
    else
      render :edit
    end
  end

  private

  def wizard_params
    params.require(:from_wizard).permit(:departement, :latitude, :lieu_id, :longitude, :latitude, :motif_id, :starts_at, :where, user_ids: [])
  end

  def user_params
    params.require(:user).permit(:first_name, :last_name, :birth_name, :phone_number, :birth_date, :address, :caisse_affiliation, :affiliation_number, :family_situation, :number_of_children, :logement)
  end
end
