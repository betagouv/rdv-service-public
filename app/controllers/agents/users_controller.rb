class Agents::UsersController < AgentAuthController
  respond_to :json

  MAX_RESULTS = 4

  def search
    skip_authorization # On scope les usagers par organisation puis par territoire via de la logique métier plutôt qu'une policy Pundit
    # Dans cette recherche, on autorise un périmètre plus grand que la policy de base, puisqu'on est en train d'ajouter un usager à l'organisation en créant un rdv
    # ce skip_authorization ne skippe pas le AgentAuthController#authorize_organisation

    territory_scope = Agent::UserPolicy::TerritoryScope.new(pundit_user, User.all).resolve
    current_org_scope = Agent::UserPolicy::Scope.new(pundit_user, User.all).resolve

    user_scope = User.where.not(id: params[:exclude_ids]).search_by_text(params[:term])

    users_from_organisation = user_scope.merge(current_org_scope).to_a

    results_count = users_from_organisation.size

    users_from_territory = if results_count >= MAX_RESULTS
                             []
                           else
                             user_scope.merge(territory_scope)
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
end
