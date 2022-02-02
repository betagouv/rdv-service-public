# frozen_string_literal: true

module HumanAttributeValue
  # Like :human_attribute_name, but for enum values.
  #
  extend ActiveSupport::Concern
  class_methods do
    # Fetches  the i18n key at
    # `activerecord.attributes.<klass>/<enum_names>.<value>`
    # @enum_name is pluralized.
    # @value is converted to the string value (e.g. from `0` to `"in_progress"`) \if necessary.
    # @options:
    #  - :context lets you specify another sets of locales for the same enum.
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
    def human_attribute_value(enum_name, value, options = {})
      return if value.blank?

      options = { default: value }.merge(options) # make sure to return the value unchanged if not found
      unless options.delete(:disable_cast)
        value = attribute_types[enum_name.to_s].cast(value)
      end

      context = options.delete(:context)
      enum_i18n_scope = [enum_name.to_s.pluralize, context].compact.join("/")
      human_attribute_name("#{enum_i18n_scope}.#{value}", options)
    end

    # Returns a hash of the enum values => localized text
    # @options:
    #  - raw_values: use the database integer values rather than the enum constants
    #
    # @example:
    # > Rdv.human_attribute_values(:status)
    # => { "État indéterminé" => "unknown", "En salle d’attente" => "waiting", "Rendez-vous honoré" => "seen" ... }
    #
    # @example:
    # > Rdv.human_attribute_values(:status, context: :action)
    # => { "unknown"=>"Pour corriger l’état du rendez-vous", "waiting"=>"L’usager est présent", "seen"=>"L’usager s’est présenté à son rendez-vous et a été reçu." ... }
    def human_attribute_values(enum_name, options = {})
      mapping = send(enum_name.to_s.pluralize)
      enum_values = if options.delete(:raw_values)
                      mapping.values
                    else
                      mapping.keys
                    end
      enum_values.index_by { |value| human_attribute_value(enum_name, value, options.dup) }
    end
  end

  # Instance method
  # @example:
  # > Rdv.last.human_attribute_value(:status)
  # => "État indéterminé"
  def human_attribute_value(enum_name, options = {})
    self.class.human_attribute_value(enum_name, send(enum_name), options)
  end
end
