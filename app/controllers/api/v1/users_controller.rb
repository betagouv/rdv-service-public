# frozen_string_literal: true

class Api::V1::UsersController < Api::V1::BaseController
  before_action :retrieve_user, only: %i[show update invite]

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

  def invite
    @user.invite_for = params[:invite_for]
    @user.invite! do |u|
      u.skip_invitation = true
      u.invited_by = pundit_user.agent
      u.invited_through = "external"
    end
    # NOTE: The #invite endpoint uses a jbuilder view instead of a blueprint.
  end

  private

  def retrieve_user
    @user = \
      if params[:invitation_token].present?
        retrieve_user_by_invitation_token
      else
        retrieve_user_by_id
      end
    authorize(@user)
  end

  def retrieve_user_by_id
    current_organisation.present? ? current_organisation.users.find(params[:id]) : User.find(params[:id])
  end

  def retrieve_user_by_invitation_token
    # rubocop:disable Rails/DynamicFindBy
    # find_by_invitation_token is a method added by the devise_invitable gem
    user = User.find_by_invitation_token(params[:invitation_token], true)
    # rubocop:enable Rails/DynamicFindBy

    raise ActiveRecord::RecordNotFound unless user

    user
  end

  def user_params
    params.permit(:first_name, :birth_name, :last_name, :email, :address, :phone_number,
                  :birth_date, :responsible_id, :caisse_affiliation, :affiliation_number,
                  :family_situation, :number_of_children, :notify_by_sms, :notify_by_email,
                  organisation_ids: [])
  end
end
