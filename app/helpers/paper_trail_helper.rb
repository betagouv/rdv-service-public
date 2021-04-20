module PaperTrailHelper
  def paper_trail_change_value(resource, property_name, value)
    klass_name = "PaperTrailHelper::Value::#{resource.class.name}::#{property_name.camelize}"
    klass = Object.const_defined?(klass_name) ? klass_name.constantize : Value::Base
    klass.new(resource, property_name, value).to_s
  end

  module Value
    class Base
      def initialize(resource, property_name, value)
        @resource = resource
        @property_name = property_name
        @value = value
      end

      def to_s
        return "N/A" if @value.nil?

        return I18n.l(@value, format: :dense) if @value.is_a? Time

        @value.to_s
      end
    end

    module Rdv
      class Status < Base
        def to_s
          ::Rdv.human_enum_name(@property_name, @value)
        end
      end

      class UserIds < Base
        def to_s
          ::User.where(id: @value).order_by_last_name.map(&:full_name).join(", ")
        end
      end

      class AgentIds < Base
        def to_s
          ::Agent.where(id: @value).order_by_last_name.map(&:full_name).join(", ")
        end
      end

      class LieuId < Base
        def to_s
          ::Lieu.find_by(id: @value)&.full_name || super
        end
      end
    end
  end
end
