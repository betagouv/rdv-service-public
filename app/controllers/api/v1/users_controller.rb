class Api::V1::UsersController < Api::V1::AgentAuthBaseController
  before_action :set_organisation, only: %i[show update]
  before_action :set_user, only: %i[show update rdv_invitation_token]

  def index
    users = policy_scope(User)
    users = users.where(id: params[:ids]) if params[:ids].present?
    render_collection(users)
  end

  def show
    render_record @user, agent_context: pundit_user
  end

  def create
    params.require(:organisation_ids)

    user = User.new(user_params.merge(created_through: "agent_creation_api"))
    authorize(user)
    user.skip_confirmation_notification!
    user.save!
    render_record user
  end

  def update
    @user.skip_reconfirmation!
    @user.update!(user_params)
    render_record @user
  end

  def rdv_invitation_token
    @user.set_rdv_invitation_token!
    render json: { invitation_token: @user.rdv_invitation_token }
  end

  private

  def set_organisation
    @organisation = params[:organisation_id].present? ? Organisation.find(params[:organisation_id]) : nil
  end

  def set_user
    @user = @organisation.present? ? @organisation.users.find(params[:id]) : User.find(params[:id])
    authorize(@user)
  rescue ActiveRecord::RecordNotFound
    render_error :not_found, not_found: :user
  end

  def user_params
    attrs = %i[
      first_name birth_name last_name email address phone_number
      birth_date responsible_id caisse_affiliation affiliation_number
      family_situation number_of_children notify_by_sms notify_by_email
    ]

    attrs -= User::FranceconnectFrozenFieldsConcern::FROZEN_FIELDS if @user&.logged_once_with_franceconnect?

    params.permit(attrs, organisation_ids: [], referent_agent_ids: [])
  end
end
