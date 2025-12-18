module Rdv::VisioConcern
  extend ActiveSupport::Concern

  VALID_DOMAINS = %w[
    webinaire.numerique.gouv.fr
    webconf.numerique.gouv.fr
    teams.microsoft.com
    meet.google.com
    zoom.us
    meet.jit.si
  ].freeze

  included do
    validates :visio_url_custom, presence: true, if: -> { visio_url_type == "custom" }
    validate :validate_visio_url_custom, if: -> { visio_url_custom.present? }
  end

  def visio_url
    if !motif.visio?
      nil
    elsif visio_url_custom.present?
      visio_url_custom
    else
      # webconf = Jitsi et Jitsi n'autorise pas les - et _ dans les liens de visio
      "https://webconf.numerique.gouv.fr/RdvServicePublic#{uuid}".gsub(/[-_]/, "")
    end
  end

  def validate_visio_url_custom
    res = URI::DEFAULT_PARSER.make_regexp(%w[http https]).match(visio_url_custom)
    if !res
      errors.add :visio_url_custom, "n'est pas une URL valide"
    elsif VALID_DOMAINS.exclude?(res[4])
      errors.add :visio_url_custom, "doit provenir d’un des domaines suivants : #{VALID_DOMAINS.to_sentence}"
    end
  end

  # visio_url_type est un attribut PORO non persisté qui permet d’afficher les radio buttons
  # on pourra le déplacer vers les objets RdvForm lorsque ceux-ci seront correctement utilisés 😅
  def visio_url_type
    if defined?(@visio_url_type)
      @visio_url_type
    elsif visio_url_custom.present?
      "custom"
    else
      "default"
    end
  end

  # ce setter permet de vider l’URL custom lors de l’édition d’un RDV existant
  def visio_url_type=(new_val)
    @visio_url_type = new_val
    self.visio_url_custom = nil if new_val == "default"
  end
end
