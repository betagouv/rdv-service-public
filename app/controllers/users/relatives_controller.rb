class Users::RelativesController < UserAuthController
  layout "application_narrow"

  respond_to :html

  def new
    user = current_user.relatives.new
    authorize(user, policy_class: User::UserPolicy)
    @form = RelativeUserForm.new(user:, **form_params)
    respond_modal_with @form
  end

  def create
    user = User.new(
      created_through: "user_relative_creation",
      responsible_id: current_user.id,
      organisation_ids: current_user.organisation_ids
    )
    authorize(user, policy_class: User::UserPolicy)
    return_location = request.referer
    @form = RelativeUserForm.new(user:)
    if @form.submit(**form_params)
      flash[:success] = "#{@form.user.full_name} a été ajouté comme proche."
      return_location = add_query_string_params_to_url(request.referer, created_user_id: @form.user.id)
    end
    respond_modal_with @form, location: return_location
  end

  def edit
    user = User.find(params.require(:id))
    authorize(user, policy_class: User::UserPolicy)
    @form = RelativeUserForm.new(user:, **form_params)
  end

  def update
    user = User.find(params.require(:id))
    authorize(user, policy_class: User::UserPolicy)
    @form = RelativeUserForm.new(user:)
    if @form.submit(**form_params)
      flash[:success] = "Les informations de votre proche #{@form.user.full_name} ont été mises à jour."
      redirect_to users_informations_path
    else
      render :edit
    end
  end

  def destroy
    @user = User.find(params[:id])
    authorize(@user, policy_class: User::UserPolicy)
    flash[:notice] = "Votre proche a été supprimé." if @user.soft_delete
    redirect_to users_informations_path
  end

  private

  def form_params
    {
      ants_pre_demande_number_required: params[:ants_pre_demande_number_required]&.to_b,
      first_name: params.dig(:user, :first_name),
      last_name: params.dig(:user, :last_name),
      birth_date: params.dig(:user, :birth_date),
      ants_pre_demande_number: params.dig(:user, :ants_pre_demande_number),
    }.compact
  end
end
