module RuboCop
  module Cop
    module Rails
      class NoPositionalRouteArgs < Base
        extend AutoCorrector

        MSG = 'Route helpers ending with `_path` or `_url` must use keyword arguments only.'

        # Match method calls with arguments
        #
        # (send nil? :user_path ...)
        # (send nil? :edit_post_url ...)
        def on_send(node)
          method_name = node.method_name

          return unless route_helper?(method_name)
          return if node.arguments.empty?
          return if keyword_arguments_only?(node.arguments)

          add_offense(node.loc.selector)
        end

        private

        def route_helper?(method_name)
          method_name.to_s.end_with?('_path', '_url')
        end

        def keyword_arguments_only?(arguments)
          arguments.all?(&:hash_type?)
        end
      end
    end
  end
end
