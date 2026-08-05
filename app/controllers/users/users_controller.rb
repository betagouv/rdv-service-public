class Users::UsersController < UserAuthController
  layout "application_base"

  def edit
    @user = current_user
    authorize(@user, policy_class: User::UserPolicy)
    @user_form = Users::EditForm.new(user: @user, domain: current_domain)
  end

  def update
    @user = current_user
    authorize(@user, policy_class: User::UserPolicy)
    @user_form = Users::EditForm.new(user: @user, domain: current_domain)
    if @user.update(user_params)
      flash[:success] = "Vos informations ont été mises à jour."
      redirect_to users_informations_path
    else
      render :edit
    end
  end

  private

  def user_params_permitted_keys
    keys = %i[
      first_name
      last_name
      birth_name
      phone_number
      birth_date
      address
      city_name
      post_code
      city_code
      caisse_affiliation
      affiliation_number
      family_situation
      number_of_children
      notify_by_email
      notify_by_sms
      address_details
    ]
    keys << :email if @user.email_editable?
    keys
  end

  def user_params
    params.require(:user).permit(*user_params_permitted_keys)
  end
end
