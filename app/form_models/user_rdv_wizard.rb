module UserRdvWizard
  # cf https://medium.com/@nicolasblanco/developing-a-wizard-or-multi-steps-forms-in-rails-d2f3b7c692ce

  STEPS = %w[step1 step2 step3].freeze

  class Base
    include ActiveModel::Model

    attr_accessor :rdv, :user

    delegate :motif, :starts_at, :users, :service, to: :rdv
    delegate :errors, to: :rdv

    def initialize(user, attributes)
      @user = user
      @attributes = attributes.to_h.symbolize_keys
      rdv_defaults = { user_ids: [user&.id] }
      if attributes[:rdv_collectif_id].present?
        @rdv = Rdv.collectif.bookable_by_everyone_or_agents_and_prescripteurs_or_invited_users.find(attributes[:rdv_collectif_id])
      else
        @rdv = Rdv.new(
          rdv_defaults
            .merge(@attributes.slice(:starts_at, :user_ids, :motif_id))
        )
        @rdv.duration_in_min = @attributes[:duration]&.to_i || @rdv.motif&.default_duration_in_min
      end
    end

    def invitation?
      @user&.signed_in_with_invitation_token?
    end

    def params_to_selections
      if @rdv.present?
        return @attributes.merge(service: @rdv.motif.service_id, motif_name_with_location_type: @rdv.motif.name_with_location_type)
      end

      @attributes
    end

    def creneau
      motif = @rdv.motif
      motif.default_duration_in_min = @attributes[:duration].to_i if @attributes[:duration]

      @creneau ||= CreneauxSearch::ForUser.creneau_for(
        user: @user,
        motif: motif,
        lieu: lieu,
        starts_at: @rdv.starts_at,
        geo_search: geo_search
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
          :where, :departement, :lieu_id, :latitude, :longitude, :city_code, :street_ban_id,
          :address, :organisation_ids, :public_link_organisation_id, :user_selected_organisation_id,
          :referent_ids, :external_organisation_ids, :duration
        )
      )
    end

    def to_search_query
      @attributes
        .slice(:departement, :latitude, :longitude, :motif_name_with_location_type, :where, :city_code, :street_ban_id)
        .merge(service: @rdv.motif.service_id, motif_name_with_location_type: @rdv.motif.name_with_location_type)
    end

    def save
      true
    end

    private

    def lieu
      @lieu ||= @attributes[:lieu_id].present? ? Lieu.find(@attributes[:lieu_id]) : nil
    end
  end

  class Step1 < Base
    validate :phone_number_present_for_motif_by_phone
    validate do
      if rdv.requires_ants_predemande_number?
        ValidateAntsPreDemandeNumber.perform(
          user: @user,
          ants_pre_demande_number: @user_attributes[:ants_pre_demande_number],
          ignore_benign_errors: @user_attributes[:ignore_benign_errors]
        )
        errors.merge!(@user)
      end
    end

    def phone_number_present_for_motif_by_phone
      errors.add(:phone_number, :missing_for_phone_motif) if rdv.motif.phone? && @user_attributes[:phone_number].blank?
    end

    def initialize(user, attributes)
      super
      @user_attributes = @attributes[:user]&.with_indifferent_access
    end

    def save
      # we make sure the email can be updated only if it is blank
      @user.skip_reconfirmation! if @user.email_was.blank?
      valid? && @user.update(@user_attributes)
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
