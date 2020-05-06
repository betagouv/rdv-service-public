module UserRdvWizard
  # cf https://medium.com/@nicolasblanco/developing-a-wizard-or-multi-steps-forms-in-rails-d2f3b7c692ce

  STEPS = ["step1", "step2", "step3"].freeze

  class Base
    include ActiveModel::Model

    attr_accessor :rdv, :creneau
    
    def initialize(current_user, attributes)
      @motif_name = attributes[:motif_name]
      @departement = attributes[:departement]
      @where = attributes[:where]
      @lieu = Lieu.find(attributes[:lieu_id])
      @motif = Motif.find_by(organisation_id: @lieu.organisation_id, name: @motif_name)
      @rdv_defaults = {
        user_ids: [attributes[:created_user_id].presence || current_user.id],
        starts_at: attributes[:starts_at],
        motif_id: @motif.id
      }
      @rdv = Rdv.new(@rdv_defaults.merge(motif: @motif))
      @creneau = Creneau.new(starts_at: @rdv.starts_at, motif: @motif, lieu_id: @lieu.id)
    end

    def to_query
      {
        where: @where,
        service: @motif.service.id,
        motif_id: @motif_id,
        departement: @departement,
        motif_name: @motif_name,
        lieu_id: @lieu.id,
        rdv: @rdv_defaults,
      }
    end
  end

  class Step1 < Base; end

  class Step2 < Step1; end

  class Step3 < Step2; end
end
