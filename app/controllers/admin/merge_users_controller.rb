class Admin::MergeUsersController < AgentAuthController
  before_action :set_organisation

  def new
    user1 = policy_scope(User, policy_scope_class: Agent::UserPolicy::Scope).find(params[:user1_id]) if params[:user1_id].present?
    user2 = policy_scope(User, policy_scope_class: Agent::UserPolicy::Scope).find(params[:user2_id]) if params[:user2_id].present?
    @merge_users_form = MergeUsersForm.new(current_organisation, user1: user1, user2: user2)
    authorize(user1, :update?, policy_class: Agent::UserPolicy) if user1.present?
    authorize(user2, :update?, policy_class: Agent::UserPolicy) if user2.present?
    skip_authorization if user1.nil? && user2.nil?
  end

  def create
    user1 = policy_scope(User, policy_scope_class: Agent::UserPolicy::Scope).find(params[:merge_users_form][:user1_id])
    user2 = policy_scope(User, policy_scope_class: Agent::UserPolicy::Scope).find(params[:merge_users_form][:user2_id])
    authorize(user1, :update?, policy_class: Agent::UserPolicy)
    authorize(user2, :update?, policy_class: Agent::UserPolicy)
    @merge_users_form = MergeUsersForm.new(current_organisation, user1: user1, user2: user2, **merge_users_params)
    if @merge_users_form.save
      redirect_to admin_organisation_user_path(current_organisation, @merge_users_form.user_target), flash: { success: "Les usagers ont été fusionnés" }
    else
      render :new
    end
  end

  protected

  def merge_users_params
    params.require(:merge_users_form).permit(MergeUsersForm::ATTRIBUTES + Territory::OPTIONAL_FIELD_TOGGLES.values)
  end
end
