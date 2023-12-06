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

    users_from_organisation = user_scope.joins(:user_profiles).where(user_profiles: { organisation_id: params[:organisation_id] }).limit(MAX_RESULTS).to_a

    results_count = users_from_organisation.size

    users_from_territory = if agent_in_cnfs_or_mairies_territories? || results_count >= MAX_RESULTS
                             []
                           else
                             user_scope.joins(:territories).where(territories: { id: current_agent.agent_territorial_access_rights.select(:territory_id) })
                               .where.not(id: users_from_organisation.map(&:id))
                               .limit(MAX_RESULTS - results_count).to_a
                           end

    results = []

    if users_from_organisation.any?
      results << formatted_users_from_organisation(users_from_organisation)
    end

    if users_from_territory.any?
      results << formatted_users_from_territory(users_from_territory)
    end

    render json: { results: results }
  end

  private

  def formatted_users_from_organisation(users)
    {
      text: nil,
      children: users.map do |user|
        {
          id: user.id,
          text: UsersHelper.reverse_full_name_and_notification_coordinates(user),
        }
      end,
    }
  end

  def formatted_users_from_territory(users)
    {
      text: "Usagers des autres organisations",
      children: users.map do |user|
        {
          id: user.id,
          text: UsersHelper.partially_hidden_reverse_full_name_and_notification_coordinates(user),
        }
      end,
    }
  end

  def agent_in_cnfs_or_mairies_territories?
    cnfs_and_mairies_territory_ids = [Territory.mairies&.id, Territory.find_by(departement_number: "CN")&.id].compact
    (cnfs_and_mairies_territory_ids & current_agent.organisations.pluck(:territory_id)).any? # & does an array overlap here
  end

  def serialize(users); end
end
