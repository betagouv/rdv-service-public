module RdvWizard
  # cf https://medium.com/@nicolasblanco/developing-a-wizard-or-multi-steps-forms-in-rails-d2f3b7c692ce

  STEPS = ["step1", "step2", "step3"].freeze

  class Base
    include ActiveModel::Model

    attr_accessor :rdv

    # delegates all getters and setters to rdv
    delegate :motif, :organisation, :duration_in_min, :starts_at, :agents, :to_query, to: :rdv

    def initialize(rdv_attributes)
      @rdv = ::Rdv.new(rdv_attributes)
    end
  end

  class Step1 < Base
    validates :motif, :organisation, presence: true
  end

  class Step2 < Step1
    validates :duration_in_min, :starts_at, :agents, presence: true
  end

  class Step3 < Step2; end
end
