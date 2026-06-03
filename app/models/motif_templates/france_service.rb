module MotifTemplates
  module FranceService
    TEMPLATE_HASHES = YAML.load_file(Rails.root.join("lib/assets/motifs_france_service.yaml").to_s).map(&:symbolize_keys).freeze

    def self.upsert_services!
      service_names = TEMPLATE_HASHES.pluck(:service_name).uniq
      existing_service_names = Service.where(name: service_names)
      services_to_create = service_names - existing_service_names

      services_to_create.each do |service_name|
        Service.create(name: service_name, short_name: service_name)
      end
    end

    def self.upsert_motifs!(organisation)
      motifs_templates.each do |motif|
        motif.organisation = organisation
        motif.save!
      rescue ActiveRecord::RecordInvalid => e
        # Si le motif existe déjà, on n'en crée pas de nouveau
        raise unless e.record.errors.map(&:type) == [:duplicate_detected]
      end
    end

    def self.motifs_templates
      TEMPLATE_HASHES.map do |template_attrs|
        service_id = Service.find_by!(name: template_attrs[:service_name]).id

        motif_attrs = template_attrs
          .slice(:name, :location_type, :default_duration_in_min, :restriction_for_rdv, :instruction_for_rdv)
          .merge(service_id:, color: "#99CC99")

        Motif.new(motif_attrs)
      end
    end
  end
end
