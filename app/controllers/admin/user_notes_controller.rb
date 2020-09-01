class Admin::UserNotesController < AgentAuthController
  def index
    @user = policy_scope(User).find(params[:user_id])
    @notes = policy_scope(UserNote)
      .where(organisation: current_organisation, user: @user)
      .order("created_at desc")
    @from_rdv = params[:rdv_id].present? && policy_scope(Rdv).find(params[:rdv_id])
  end

  def create
    user = User.find(params[:user_id])
    note = UserNote.new(organisation: current_organisation, user: user, agent: current_agent, text: params[:user_note][:text])
    authorize(note)
    flash[:error] = note.errors.full_messages.join(", ") unless note.save
    redirect_back(fallback_location: organisation_user_path(current_organisation, user, anchor: "notes"))
  end

  def destroy
    user = User.find(params[:user_id])
    note = UserNote.find(params[:id])
    authorize(note)
    flash[:error] = note.errors.full_messages.join(", ") unless note.destroy
    redirect_back(fallback_location: organisation_user_path(current_organisation, user, anchor: "notes"))
  end
end
