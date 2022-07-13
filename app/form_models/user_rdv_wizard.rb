# frozen_string_literal: true

module UserRdvWizard
  # cf https://medium.com/@nicolasblanco/developing-a-wizard-or-multi-steps-forms-in-rails-d2f3b7c692ce

  STEPS = %w[step1 step2 step3].freeze

  class Base
    include ActiveModel::Model

    attr_accessor :rdv

    delegate :motif, :starts_at, :users, :service, to: :rdv
    delegate :errors, to: :rdv

    def initialize(user, attributes)
      @user = user
      @attributes = attributes.to_h.symbolize_keys
      rdv_defaults = { user_ids: [user&.id] }
      @rdv = Rdv.new(
        rdv_defaults
          .merge(@attributes.slice(:starts_at, :user_ids, :motif_id))
      )
      @rdv.duration_in_min ||= @rdv.motif.default_duration_in_min if @rdv.motif.present?
    end

    def creneau
      @creneau ||= Users::CreneauSearch.creneau_for(
        user: @user,
        motif: @rdv.motif,
        lieu: Lieu.find(@attributes[:lieu_id]),
        starts_at: @rdv.starts_at,
        geo_search: geo_search
      )
    end

    def geo_search
      @geo_search ||= Users::GeoSearch.new(**@attributes.slice(:departement, :city_code, :street_ban_id))
    end

    def lieu_full_name
      creneau.lieu.full_name
    end

    def to_query
      { motif_id: rdv.motif.id, starts_at: rdv.starts_at.to_s, user_ids: rdv.users&.map(&:id) }
        .merge(@attributes.slice(:where, :departement, :lieu_id, :latitude, :longitude, :city_code, :street_ban_id, :invitation_token, :address, :organisation_ids, :motif_search_terms))
    end

    def search_motif_context_query
      # Utilisé pour construire l'url de retour au choix des motifs
      @attributes.slice(:departement, :city_code, :longitude, :latitude, :street_ban_id, :address)
    end

    def search_lieu_context_query
      # Utilisé pour construire l'url de retour au choix des lieux
      @attributes.slice(:departement, :city_code, :longitude, :latitude, :street_ban_id, :address, :motif_name_with_location_type)
    end

    def search_slot_context_query
      # Utilisé pour construire l'url de retour au choix des créneaux
      @attributes.slice(:departement, :city_code, :longitude, :latitude, :street_ban_id, :address, :motif_name_with_location_type, :lieu_id)
    end

    def to_search_query
      @attributes
        .slice(:departement, :latitude, :longitude, :motif_name_with_location_type, :where, :city_code, :street_ban_id)
        .merge(service: @rdv.motif.service_id, motif_name_with_location_type: @rdv.motif.name_with_location_type)
    end

    def save
      true
    end
  end

  class Step1 < Base
    validate :phone_number_present_for_motif_by_phone

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
      super(user, attributes)
      # Hacky override of user_ids on step2
      @rdv.user_ids = [attributes[:created_user_id]] if attributes[:created_user_id].present?
    end
  end

  class Step3 < Base; end
end
