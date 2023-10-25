# frozen_string_literal: true

class Agents::UsersController < AgentAuthController
  respond_to :json

  MAX_RESULTS = 4

  def search
    skip_authorization # On scope les usagers par organisation puis par territoire via de la logique métier plutôt qu'une policy Pundit
    # Dans cette recherche, on autorise un périmètre plus grand que la policy de base, puisqu'on est en train d'ajouter un usager à l'organisation en créant un rdv

    # On vérifie quand même que l'organisation demandée fait partie des organisations de l'agent
    if current_agent.organisations.find_by(id: params[:organisation_id]).nil?
      return head :forbidden
    end

    user_scope = User.where.not(id: params[:exclude_ids]).search_by_text(params[:term])

    users_from_organisation = user_scope.joins(:user_profiles).where(user_profiles: { organisation_id: params[:organisation_id] }).limit(MAX_RESULTS)

    results_count = users_from_organisation.count

    users_from_territory = if results_count < MAX_RESULTS
                             user_scope.joins(:territories).where(territories: { id: current_agent.agent_territorial_access_rights.select(:territory_id) })
                               .where.not(id: users_from_organisation.select(:id))
                               .limit(MAX_RESULTS - results_count)
                           else
                             []
                           end

    results = []

    if users_from_organisation.any?
      results << {
        text: nil,
        children: serialize(users_from_organisation),
      }
    end

    if users_from_territory.any?
      results << {
        text: "Usagers des autres organisations",
        children: serialize(users_from_territory),
      }
    end

    render json: { results: results }
  end

  private

  def serialize(users)
    users.map do |user|
      {
        id: user.id,
        text: UsersHelper.reverse_full_name_and_notification_coordinates(user),
      }
    end
  end
end
