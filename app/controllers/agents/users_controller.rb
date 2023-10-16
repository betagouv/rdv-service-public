# frozen_string_literal: true

class Agents::UsersController < AgentAuthController
  respond_to :json

  MAX_RESULTS = 4

  def search
    skip_authorization # On scope les usagers par organisation puis par territoire via de la logique métier plutôt qu'une policy Pundit
    user_scope = User.where.not(id: params[:exclude_ids]).search_by_text(params[:term])

    users_from_organisation = user_scope.joins(:user_profiles).where(user_profiles: { organisation_id: params[:organisation_id] }).limit(MAX_RESULTS)

    results_count = users_from_organisation.count

    users_from_territory = if results_count < MAX_RESULTS
                             user_scope.joins(:territories).where(territories: current_agent.territories).limit(MAX_RESULTS - results_count).where.not(id: users_from_organisation.ids)
                           else
                             []
                           end
    if users_from_organisation.none? && users_from_territory.none?
      render json: { results: [] }
    else

      render json: {
        results: [
          {
            text: nil,
            children: users_from_organisation.map do |user|
              {
                id: user.id,
                text: UsersHelper.reverse_full_name_and_notification_coordinates(user),
              }
            end,
          },
          users_from_territory.first && {
            text: "Usagers des autres organisations",
            children: users_from_territory.map do |user|
              {
                id: user.id,
                text: UsersHelper.reverse_full_name_and_notification_coordinates(user),
              }
            end,

          },
        ].compact,

      }
    end
  end
end
