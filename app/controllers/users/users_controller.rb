# frozen_string_literal: true

class Users::UsersController < UserAuthController
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
      :logement,
      :notes
    )
  end
end
