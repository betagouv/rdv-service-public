module RuboCop::Cop
  module Lapin
    class UsePreferredHttpClient < RuboCop::Cop::Base
      # If you define `MSG` constant in cop class,
      # RuboCop will use it as an offense message for this cop.
      MSG = "Utilisez Typhoeus plutot que Faraday comme client http pour bénéficier de la gestion d'erreur définie dans config/initializers/typhoeus.rb".freeze

      def on_send(node)
        return unless node.receiver
        return if node.receiver.const_name != "Faraday"
        return unless %w[new get post put patch delete].include?(node.method_name.to_s)

        add_offense(node)
      end
    end
  end
end
