class Agents::UserNotesController < AgentAuthController
  def index
    @user = policy_scope(User).find(params[:user_id])
    authorize(@user)
    @notes = @user.notes_for(current_organisation)
    @back_path = request.headers["REFERER"]
  end

  def create
    user = User.find(params[:user_id])
    authorize(user)
    note = UserNote.new(organisation: current_organisation, user: user, agent: current_agent, text: params[:user_note][:text])
    flash[:error] = note.errors.full_message unless note.save
    redirect_back(fallback_location: organisation_user_path(current_organisation, user, anchor: "notes"))
  end

  def destroy
    user = User.find(params[:user_id])
    authorize(user)
    note = UserNote.find(params[:id])
    flash[:error] = note.errors.full_message unless note.destroy
    redirect_back(fallback_location: organisation_user_path(current_organisation, user, anchor: "notes"))
  end
end
