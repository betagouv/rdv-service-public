module Motif::Typology
  extend ActiveSupport::Concern

  SLUG_SEPARATOR = "---".freeze

  class_methods do
    def typology_slug(motif)
      [motif.name_slug, motif.location_type, motif.service_id, motif.collectif.inspect].join(SLUG_SEPARATOR)
    end

    def typology_hash_from_slug(slug)
      name_slug, location_type, service_id, collectif_str = slug.split(SLUG_SEPARATOR)
      {
        name_slug: name_slug,
        location_type: location_type,
        service_id: service_id.to_i,
        collectif: collectif_str == "true",
      }
    end
  end

  def typology_slug
    self.class.typology_slug(self)
  end
end
