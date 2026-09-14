module RuboCop
  module Cop
    module RdvServicePublic
      # Détecte les cas où un objet est modifié (`update`, `update!`,
      # `assign_attributes`) après avoir été passé à `authorize`, sans
      # nouvel appel à `authorize` après la modification.
      #
      # Le problème : la policy Pundit est évaluée sur l'état de l'objet
      # au moment de l'appel à `authorize`. Si des attributs pertinents
      # pour la policy sont modifiés juste après, la vérification faite
      # ne reflète plus l'état réellement sauvegardé.
      #
      # @example
      #   # bad
      #   authorize(@absence, policy_class: Agent::AbsencePolicy)
      #   @absence.update!(update_params)
      #
      #   # good : les attributs sont fixés avant `authorize`, qui checke
      #   # donc bien l'état final
      #   @absence.assign_attributes(update_params)
      #   authorize(@absence, policy_class: Agent::AbsencePolicy)
      #   @absence.save!
      #
      #   # good : si l'attribution ne peut pas être faite avant (ex: on a besoin
      #   # d'un authorize initial pour savoir quels champs sont permis), on
      #   # peut re-checker après la modification
      #   authorize(@territory, policy_class: SuperAdmin::TerritoryPolicy)
      #   @territory.assign_attributes(params.require(:territory).permit(:category))
      #   authorize(@territory, policy_class: SuperAdmin::TerritoryPolicy)
      #   @territory.save
      #
      # Limite connue : ce cop ne regarde que dans la même méthode. Le cas où
      # `authorize` est fait dans un `before_action` séparé et la mutation dans
      # l'action elle-même n'est pas détecté (il faudrait suivre les `before_action`,
      # ce qui produirait trop de faux positifs vu que c'est l'idiome standard du
      # projet). Une revue humaine reste nécessaire pour ce cas.
      class PunditAuthorizeStaleAfterMutation < Base
        MUTATING_METHODS = %i[update update! assign_attributes].freeze

        MSG = "`%<receiver>s` est modifié via `#%<method>s` après avoir été passé à `authorize`, " \
              "sans nouvel `authorize` après la modification. Si les attributs modifiés peuvent " \
              "changer le verdict de la policy, appelle `authorize` sur l'état final, juste avant `save`.".freeze

        def on_def(node)
          check_stale_authorizations(node)
        end
        alias on_defs on_def

        private

        def check_stale_authorizations(def_node)
          events = collect_events(def_node)
          return if events.empty?

          events.group_by { |event| event[:receiver] }.each_value do |receiver_events|
            authorize_positions = receiver_events.each_index.select { |i| receiver_events[i][:type] == :authorize }

            receiver_events.each_with_index do |event, index|
              next unless event[:type] == :mutation
              next unless authorize_positions.any? { |i| i < index } # authorized at some point before
              next if authorize_positions.any? { |i| i > index } # ...and re-authorized after: OK

              add_offense(
                event[:node].loc.selector,
                message: format(MSG, receiver: event[:receiver], method: event[:node].method_name)
              )
            end
          end
        end

        # Parcourt les appels dans l'ordre du texte source pour reconstituer
        # la séquence "authorize / mutation" telle qu'elle sera exécutée.
        def collect_events(def_node)
          def_node.each_descendant(:send, :csend)
            .sort_by { |node| node.source_range.begin_pos }
            .filter_map { |node| build_event(node) }
        end

        def build_event(node)
          if authorize_call?(node)
            { type: :authorize, receiver: node.first_argument.source, node: node }
          elsif mutation_call?(node)
            { type: :mutation, receiver: node.receiver.source, node: node }
          end
        end

        def authorize_call?(node)
          node.method?(:authorize) && node.receiver.nil? && node.first_argument
        end

        def mutation_call?(node)
          node.receiver && MUTATING_METHODS.include?(node.method_name) && node.arguments.any?
        end
      end
    end
  end
end
