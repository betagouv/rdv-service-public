class Users::UsersController < UserAuthController
  def show
    authorize(current_user)
  end

  def edit
    @user = current_user
    authorize(@user)
  end

  def update
    @user = current_user
    authorize(@user)
    if @user.update(user_params)
      flash[:notice] = "Vos informations ont été mises à jour."
      redirect_to users_informations_path
    else
      render :edit
    end
  end

  def edit_password
    authorize(current_user, :edit?)
  end

  def update_password
    authorize(current_user, :update?)
    if current_user.update_with_password(user_password_params)
      # On reconnecte l'usager ici parce que Devise le déconnecte automatiquement après un changement de mot de passe
      bypass_sign_in(current_user)
      flash[:notice] = "Votre mot de passe a été changé"
      redirect_to users_account_path
    else
      render :edit_password
    end
  end

  private

  def user_params
    params.require(:user).permit(
      :first_name,
      :last_name,
      :birth_name,
      :phone_number,
      :birth_date,
      :address,
      :city_name,
      :post_code,
      :city_code,
      :caisse_affiliation,
      :affiliation_number,
      :family_situation,
      :number_of_children,
      :notify_by_email,
      :notify_by_sms,
      :address_details,
      user_profiles_attributes: %i[logement id organisation_id]
    )
  end

  def user_password_params
    params.require(:user).permit(:password, :current_password, :password_confirmation)
  end
end
