module UserRdvWizard
  # cf https://medium.com/@nicolasblanco/developing-a-wizard-or-multi-steps-forms-in-rails-d2f3b7c692ce

  class Base
    include ActiveModel::Model

    attr_accessor :rdv, :user

    delegate :motif, :starts_at, :users, :service, to: :rdv

    def initialize(user, attributes)
      @user = user
      @attributes = attributes.to_h.symbolize_keys
      if attributes[:rdv_collectif_id].present?
        @rdv = Rdv.collectif.bookable_by_everyone_or_agents_and_prescripteurs_or_invited_users.find(attributes[:rdv_collectif_id])
      else
        @rdv = Rdv.new({
          user_ids: [user&.id],
        }.merge(@attributes.slice(:starts_at, :user_ids, :motif_id)))
        @rdv.duration_in_min = @attributes[:duration]&.to_i || @rdv.motif&.default_duration_in_min
        @rdv.organisation_id = @rdv.motif.organisation_id
      end
    end

    def params_to_selections
      if @rdv.present?
        return @attributes.merge(service: @rdv.motif.service_id, motif_name_with_location_type: @rdv.motif.name_with_location_type)
      end

      @attributes
    end

    def creneau
      @creneau ||= CreneauxSearch::ForUser.creneau_for(
        user: @user,
        motif: @rdv.motif,
        lieu: lieu,
        starts_at: @rdv.starts_at,
        geo_search: geo_search,
        duration_in_min: @attributes[:duration]&.presence&.to_i
      )
    end

    def geo_search
      @geo_search ||= Users::GeoSearch.new(**@attributes.slice(:departement, :city_code, :street_ban_id))
    end

    def to_query
      {
        motif_id: rdv.motif.id, starts_at: rdv.starts_at.to_s, user_ids: rdv.users&.map(&:id), rdv_collectif_id: rdv.id,
      }.merge(
        @attributes.slice(
          *WebSearchContext::ADDRESS_SELECTION_PARAMS,
          :where, :lieu_id, :organisation_ids, :public_link_organisation_id, :user_selected_organisation_id,
          :referent_ids, :external_organisation_ids, :duration
        )
      )
    end

    def save
      true
    end

    def lieu_id = @attributes[:lieu_id]

    private

    def lieu
      @lieu ||= lieu_id.present? ? Lieu.find(lieu_id) : nil
    end
  end

  class Step1 < Base
    delegate :errors, to: :user

    validate :phone_number_present_for_motif_by_phone

    def phone_number_present_for_motif_by_phone
      errors.add(:phone_number, :missing_for_phone_motif) if rdv.motif.phone? && user.phone_number.blank?
    end

    def initialize(user, attributes)
      super
      @user&.assign_attributes(@attributes.fetch(:user, {}))
    end

    def save
      # we make sure the email can be updated only if it is blank
      @user.skip_reconfirmation! if @user.email_was.blank?

      # dans la vue on appelle form_for(user) plutôt que form_for(user_rdv_wizard),
      # il faut donc ajouter des validations (et des erreurs) sur l'objet user
      if rdv.requires_ants_predemande_number?
        @user.singleton_class.include(User::AntsPreDemandeNumberStatusValidationConcern)
        @user.ants_meeting_point_id = lieu_id # used in AntsPreDemandeNumberStatusValidation
      end

      valid? && @user.save
    end
  end

  class Step2 < Base
    def initialize(user, attributes)
      super
      # Hacky override of user_ids on step2
      @rdv.user_ids = [attributes[:created_user_id]] if attributes[:created_user_id].present?
    end
  end

  class Step3 < Base; end
end
