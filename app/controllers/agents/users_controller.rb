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

    user_scope = UserSearchParser.new(params[:term]).scope.where.not(id: params[:exclude_ids])

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

  class UserSearchParser
    def initialize(prompt)
      @prompt = prompt.squish
    end

    def scope
      @terms = @prompt.split.map { Term.new(_1) }
      scope = User.all
      scope = User.search_by_text(text_search) if text_search
      scope = scope.where(birth_date: date_terms.last.date) if date_terms.any?
      scope
    end

    private

    def text_search
      text_terms = @terms.select(&:text?)
      return unless text_terms.any?

      text_terms.map(&:str).join(" ")
    end

    def date_terms
      @terms.select(&:date?)
    end

    class Term
      def initialize(str)
        @str = str
      end

      attr_reader :str

      def date
        return unless @str =~ %r{[0-3][0-9]/[0-1][0-9]/[0-9]{4}}

        Date.strptime(@str, "%d/%m/%Y")
      rescue Date::Error
        nil
      end

      def date?
        !date.nil?
      end

      def text?
        !date?
      end
    end
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
