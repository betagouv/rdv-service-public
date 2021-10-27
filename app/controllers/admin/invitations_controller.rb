# frozen_string_literal: true

class Admin::InvitationsController < AgentAuthController
  def index
    @invited_agents = policy_scope(Agent)
      .joins(:organisations).where(organisations: { id: current_organisation.id })
      .invitation_not_accepted
      .created_by_invite
      .order(invitation_sent_at: :desc)
      .page(params[:page])
    @invited_agents = @invited_agents.search_by_text(index_params[:search]) if index_params[:search].present?
  end

  def reinvite
    @agent = policy_scope(Agent).find(params[:id])
    authorize(@agent)
    @agent.invite!
    redirect_to admin_organisation_invitations_path(current_organisation), notice: "Une nouvelle invitation a été envoyée à l'agent #{@agent.email}."
  end

  private

  def index_params
    @index_params ||= begin
      index_params = params.permit(:search)
      index_params[:search] = clean_search_term(index_params[:search])
      index_params
    end
  end

  def clean_search_term(term)
    return nil if term.blank?

    I18n.transliterate(term)
  end
end
