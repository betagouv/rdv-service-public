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
    UserNote.create!(organisation: current_organisation, user: user, agent: current_agent, text: params[:user_note][:text])
    if request.headers["HTTP_REFERER"]
      redirect_to(request.headers["HTTP_REFERER"] += "#notes")
    else
      redirect_to organisation_user_path(current_organisation, user, anchor: "notes")
    end
  end
end
