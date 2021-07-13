# frozen_string_literal: true

class Api::V1::UsersController < Api::V1::BaseController
  def index
    users = policy_scope(User)
    users = users.where(id: params[:ids]) if params[:ids].present?
    render_collection(users)
  end

  def show
    user = retrieve_user
    render_record user, agent_context: pundit_user
  end

  def create
    params.require(:organisation_ids)

    user = User.new(create_params.merge(created_through: "agent_creation_api"))
    authorize(user)
    user.skip_confirmation_notification!
    user.save!
    render_record user
  end

  def invite
    @user = retrieve_user
    @user.invite_for = params[:invite_for]
    @user.invite! do |u|
      u.skip_invitation = true
      u.invited_by = pundit_user.agent
    end
    # NOTE: The #invite endpoint uses a jbuilder view instead of a blueprint.
  end

  private

  def retrieve_user
    user = User.find(params[:id])
    authorize(user)
    user
  end

  def create_params
    params.permit(:first_name, :birth_name, :last_name, :email, :address, :phone_number,
                  :birth_date, :responsible_id, :caisse_affiliation, :affiliation_number,
                  :family_situation, :number_of_children, :notify_by_sms, :notify_by_email,
                  :after_accept_path, organisation_ids: [])
  end
end
