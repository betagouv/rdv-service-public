class Api::V1::UsersController < Api::V1::AgentAuthBaseController
  before_action :set_organisation, only: %i[show update]
  before_action :set_user, only: %i[show update rdv_invitation_token]

  def index
    users = policy_scope(User, policy_scope_class: Agent::UserPolicy::Scope)
    users = users.where(id: params[:ids]) if params[:ids].present?
    render_collection(users)
  end

  def show
    render_record @user, agent_context: pundit_user
  end

  def create
    params.require(:organisation_ids)

    @user = User.new
    @user.assign_attributes(user_params.merge(created_through: "agent_creation_api"))
    authorize(@user, policy_class: Agent::UserPolicy)
    @user.save!
    render_record @user
  end

  def update
    if email_change_not_allowed?
      render_error :unprocessable_entity, {
        errors: {},
        error_messages: [I18n.t("users.can_not_update_email_of_confirmed_user")],
      }
      return
    end

    @user.update!(user_params)
    render_record @user
  end

  def rdv_invitation_token
    @user.set_rdv_invitation_token!
    render json: { invitation_token: @user.rdv_invitation_token }
  end

  private

  def email_change_not_allowed?
    @user.confirmed_at? && user_params.key?(:email) && @user.email != user_params[:email]
  end

  def set_organisation
    @organisation = params[:organisation_id].present? ? Organisation.find(params[:organisation_id]) : nil
  end

  def set_user
    @user = @organisation.present? ? @organisation.users.find(params[:id]) : User.find(params[:id])
    authorize(@user, policy_class: Agent::UserPolicy)
  rescue ActiveRecord::RecordNotFound
    render_error :not_found, not_found: :user
  end

  def user_params
    attrs = %i[
      first_name birth_name last_name email address phone_number
      birth_date responsible_id caisse_affiliation affiliation_number
      family_situation number_of_children notify_by_sms notify_by_email notification_email
    ]

    attrs -= User::FranceconnectFrozenFieldsConcern::FROZEN_FIELDS if @user&.logged_once_with_franceconnect?

    permitted_params = params.permit(*attrs, organisation_ids: [])

    if params[:external_reference].present?
      attributes_from_params = params.require(:external_reference).permit(:external_id, :external_url)

      territory_id = Organisation.find_by(id: params[:organisation_ids])&.territory_id
      permitted_params.merge!(
        external_references_attributes: [attributes_from_params.merge(
          oauth_application: doorkeeper_token&.application,
          territory_id: territory_id
        )]
      )
    end

    return permitted_params unless params.key?(:referent_agent_ids)

    referents_i_can_modify = Agent::AgentPolicy::Scope.new(pundit_user, @user.referent_agents).resolve
    referents_i_cant_modify = @user.referent_agents - referents_i_can_modify

    permitted_params.merge(referent_agent_ids: authorized_referent_ids + referents_i_cant_modify.map(&:id))
  end

  def authorized_referent_ids
    policy_scope(
      Agent.where(id: params[:referent_agent_ids]),
      policy_scope_class: Agent::AgentPolicy::Scope
    ).ids
  end
end
