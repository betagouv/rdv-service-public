module HumanAttributeValue
  # Like :human_attribute_name, but for attribute values.
  #
  extend ActiveSupport::Concern
  class_methods do
    # Returns a human-presentable version of the attribute value.
    # Uses the i18n key at `activerecord.attributes.<klass>/<attr_names>.<value>`
    # @attr_name is pluralized.
    # @value is converted to the string value (e.g. from `0` to `"in_progress"`) \if necessary.
    # @options:
    #  - :context lets you specify another sets of locales for the same attribute.
    #  - :disable_cast avoid converting @value; casting requires a DB connection, so this is sometimes needed
    #
    # @example:
    # > Rdv.human_attribute_value(:status, :excused)
    # => "Annulé (excusé)" # I18n.t('activerecord.attributes.rdv/statuses.excused')
    #
    # @example:
    # > Rdv.human_attribute_value(:status, 'excused')
    # => "Annulé (excusé)" # I18n.t('activerecord.attributes.rdv/statuses.excused')
    #
    # @example:
    # > Rdv.human_attribute_value(:status, :unknown, context: :action)
    # => "Réinitialiser" # I18n.t('activerecord.attributes.rdv/statuses/action.unknown')
    #
    # @example:
    # > Rdv.human_attribute_value(:status, :excused, count: 2)
    # => "Annulées (excusées)" # I18n.t('activerecord.attributes.rdv/statuses.excused.other')
    def human_attribute_value(attr_name, value, options = {})
      return if value.nil? || value == ""

      options = { default: value }.merge(options) # make sure to return the value unchanged if not found
      unless options.delete(:disable_cast)
        value = attribute_types[attr_name.to_s].cast(value)
      end

      context = options.delete(:context)
      attr_i18n_scope = [attr_name.to_s.pluralize, context].compact.join("/")
      attr = "#{attr_i18n_scope}.#{value}"

      # Rails does not support I18n keys ending with "." since https://github.com/rails/rails/pull/44300
      attr = attr.delete_suffix(".")

      human_attribute_name(attr, options)
    end

    # Returns a hash of the attribute values => localized text.
    # This makes sense primarly for enums, as it relies on the “pluralized name” method to exist on the class.
    # (e.g, for an “status” attribute, there exists a class method :statuses)
    # @options:
    #  - raw_values: use the database integer values rather than the enum constants
    #
    # @example:
    # > Rdv.human_attribute_values(:status)
    # => { "État indéterminé" => "unknown", "Rendez-vous honoré" => "seen" ... }
    #
    # @example:
    # > Rdv.human_attribute_values(:status, context: :action)
    # => { "unknown"=>"Pour corriger l’état du rendez-vous", "seen"=>"L’usager s’est présenté à son rendez-vous et a été reçu." ... }
    def human_attribute_values(attr_name, options = {})
      mapping = send(attr_name.to_s.pluralize)
      attr_values = if options.delete(:raw_values)
                      mapping.values
                    else
                      mapping.keys
                    end
      attr_values.index_by { |value| human_attribute_value(attr_name, value, options.dup) }
    end
  end

  # Instance method
  # @example:
  # > Rdv.last.human_attribute_value(:status)
  # => "État indéterminé"
  def human_attribute_value(attr_name, options = {})
    self.class.human_attribute_value(attr_name, send(attr_name), options)
  end
end
