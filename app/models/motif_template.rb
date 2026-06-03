class MotifTemplate
  MOTIFS_FRANCE_SERVICE = YAML.load_file(Rails.root.join("lib/assets/motifs_france_service.yaml").to_s).map(&:symbolize_keys).freeze

  def self.upsert_services
    service_names = MOTIFS_FRANCE_SERVICE.pluck(:service_name).uniq
    service_names.each do |service_name|
      existing_service = Service.find_by(name: service_name)
      Service.create(name: service_name, short_name: service_name) unless existing_service
    end
  end

  def self.upsert_france_service_motifs!(organisation)
    Motif.transaction do
      france_service_motifs_templates.each do |motif|
        motif.organisation = organisation
        motif.save!
      rescue ActiveRecord::RecordInvalid => e
        # Si le motif existe déjà, on n'en crée pas de nouveau
        raise unless e.record.errors.map(&:type) == [:duplicate_detected]
      end
    end
  end

  def self.france_service_motifs_templates
    YAML.load_file(Rails.root.join("lib/assets/motifs_france_service.yaml").to_s).map(&:symbolize_keys).map do |template_attrs|
      service_id = Service.find_by!(name: template_attrs[:service_name]).id

      motif_attrs = template_attrs
        .slice(:name, :location_type, :default_duration_in_min, :restriction_for_rdv, :instruction_for_rdv)
        .merge(service_id:, color: "#99CC99")

      Motif.new(motif_attrs)
    end
  end
end
