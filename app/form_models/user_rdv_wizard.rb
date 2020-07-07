module UserRdvWizard
  # cf https://medium.com/@nicolasblanco/developing-a-wizard-or-multi-steps-forms-in-rails-d2f3b7c692ce

  STEPS = ["step1", "step2", "step3"].freeze

  class Base
    include ActiveModel::Model

    attr_accessor :rdv, :creneau

    def initialize(user, attributes)
      @user = user
      @attributes = attributes.to_h.symbolize_keys
      rdv_defaults = { user_ids: [user.id] }
      @rdv = Rdv.new(
        rdv_defaults
          .merge(motif: @motif)
          .merge(@attributes.slice(:starts_at, :user_ids, :motif_id))
      )
      @creneau = Creneau.new(
        lieu_id: @attributes[:lieu_id],
        starts_at: @rdv.starts_at,
        motif: @rdv.motif
      )
    end

    def lieu_full_name
      @creneau.lieu.full_name
    end

    def to_query
      rdv.to_query.merge(@attributes.slice(:where, :departement, :lieu_id, :latitude, :longitude, :city_code))
    end

    def to_search_query
      @attributes
        .slice(:departement, :latitude, :longitude, :motif_name, :where, :city_code)
        .merge(service: @rdv.motif.service_id, motif_name: @rdv.motif.name)
    end

    def save
      true
    end
  end

  class Step1 < Base
    def initialize(user, attributes)
      super
      @user_attributes = @attributes[:user]
    end

    def save
      @user.update(@user_attributes)
    end
  end

  class Step2 < Base
    def initialize(user, attributes)
      super(user, attributes)
      # Hacky override of user_ids on step2
      @rdv.user_ids = [attributes[:created_user_id]] if attributes[:created_user_id].present?
    end
  end

  class Step3 < Base; end
end
