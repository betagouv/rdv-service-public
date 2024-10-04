class Users::UsersController < UserAuthController
  def edit
    @user = current_user
    authorize(@user, policy_class: User::UserPolicy)
  end

  def update
    @user = current_user
    authorize(@user, policy_class: User::UserPolicy)
    if @user.update(user_params)
      flash[:notice] = "Vos informations ont été mises à jour."
      redirect_to users_informations_path
    else
      render :edit
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
end
