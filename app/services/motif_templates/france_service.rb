module MotifTemplates
  class FranceService
    include ActiveModel::Validations

    TEMPLATE_HASHES = YAML.load_file(Rails.root.join("lib/assets/motifs_france_service.yaml").to_s).map(&:symbolize_keys).freeze

    def initialize(organisation)
      @organisation = organisation
    end

    def upsert
      ActiveRecord::Base.transaction do
        upsert_services
        add_services_to_territory
        upsert_motifs
      end

      errors.empty?
    end

    def self.motifs_templates
      TEMPLATE_HASHES.map do |template_attrs|
        service = Service.find_or_initialize_by(name: template_attrs[:service_name])

        motif_attrs = template_attrs
          .slice(:name, :location_type, :default_duration_in_min, :restriction_for_rdv, :instruction_for_rdv)
          .merge(service:)

        Motif.new(motif_attrs)
      end
    end

    private

    def upsert_services
      service_names = TEMPLATE_HASHES.pluck(:service_name).uniq
      existing_service_names = Service.where(name: service_names)
      services_to_create = service_names - existing_service_names

      services_to_create.each do |service_name|
        Service.create(name: service_name, short_name: service_name)
      end
    end

    def add_services_to_territory
      services = Service.where(name: TEMPLATE_HASHES.pluck(:service_name).uniq)

      services.each do |service|
        TerritoryService.find_or_initialize_by(
          territory_id: @organisation.territory_id,
          service_id: service.id
        ).save
      end
    end

    def upsert_motifs
      self.class.motifs_templates.each do |motif|
        motif.organisation = @organisation
        motif.save
        if motif.errors.any?
          errors.add(:base, "Le motif #{motif.name} n'a pas été ajouté parce que #{motif.errors.full_messages.to_sentence}.")
        end
      end
    end
  end
end
