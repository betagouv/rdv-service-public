# Ce service permet de savoir si un territoire a vocation à rester sur l'instance de l'ANCT ou à être
# déplacé sur l'instance de la DINUM.
#
# Pour le moment il ne fait pas d'écriture, mais la méthode .find_all permet d'obtenir un récapitulatif du partitionnement.
module InstancePartition
  class ChooseForTerritory
    def self.find_all
      results = Hash.new(0)

      Territory.find_each do |territory|
        results[new(territory).instance] += 1
      end

      results
    end

    def initialize(territory)
      @territory = territory
    end

    def instance # rubocop:disable Metrics/PerceivedComplexity,Metrics/CyclomaticComplexity
      anct = clearly_anct?
      dinum = clearly_dinum?

      return :anct if anct && !dinum

      return :dinum if dinum && !anct

      return :sdis if first_admin_email_domain&.start_with?("sdis")

      return :mdph if first_admin_email_domain&.start_with?("mdph")

      return :ehpad if first_admin_email_domain&.in?(%w[ehpadlesoiseaux.fr mr-bellevue.com])

      return :inactive if inactive?

      return :probably_anct if anct_category? && !dinum_category?

      return :probably_dinum if dinum_category? && !anct_category?

      # puts "#{@territory.category} #{@territory.rdvs.count} http://www.#{first_admin_email_domain} https://rdv.anct.gouv.fr/super_admins/territories/#{@territory.id}"
      :unkown
    end

    private

    # Indique qu'on est confiant qu'il s'agit d'un espace à garder sur l'instance ANCT
    def clearly_anct? # rubocop:disable Metrics/PerceivedComplexity,Metrics/CyclomaticComplexity
      return false unless first_admin&.email

      return true if @territory.mairies? # Le territorie ouvert historiquement pour les mairies

      return true if @territory.organisations.any?(&:ants_connectable)

      return true if @territory.operator

      return true if first_admin.applications.where(oauth_applications: { name: ["La Coop de la médiation numérique", "Mon Suivi Social", "RDV Aide Numérique"] }).any?

      return true if france_service?

      return true if first_admin.pro_connect_idp_id.in?(ProconnectIdentityProviders::COLLECTIVITES)

      return true if first_admin_email_domain.in?(DomainNames::COLLECTIVITE_DOMAIN_NAMES)

      return true if %w[ville- agglo- cc- ccas- mairie pays saint udaf].any? do |prefix|
        first_admin_email_domain.start_with?(prefix)
      end

      false
    end

    def anct_category?
      @territory.category.in?(%w[Association Commune Intercommunalité Département])
    end

    # Indique qu'on est confiant qu'il s'agit d'un espace à déplacer sur l'instance DINUM
    def clearly_dinum?
      return false unless first_admin&.email

      return true if first_admin.pro_connect_idp_id.in?(ProconnectIdentityProviders::ETAT)

      return true if VerifiedServicePublicDomainNames.verified?(first_admin.email)

      return true if first_admin_email_domain.in?(DomainNames::ETAT_DOMAIN_NAMES)

      return true if %w[ch- chu- univ-].any? do |prefix| # Centre Hospitalier ou Centre Hospitalier Universitaire ou Université
        first_admin_email_domain.start_with?(prefix)
      end

      false
    end

    def dinum_category?
      @territory.category.in?(%w[État])
    end

    def inactive?
      more_than_one_year_old_and_no_rdvs || more_than_six_month_old_and_admin_not_returned
    end

    def more_than_six_month_old_and_admin_not_returned
      return false if first_admin&.last_sign_in_at.nil?

      @territory.created_at < 6.months.ago && @territory.created_at > first_admin.last_sign_in_at && @territory.agent_territorial_access_rights.count == 1
    end

    def more_than_one_year_old_and_no_rdvs
      @territory.created_at < 12.months.ago && @territory.rdvs.none?
    end

    def france_service?
      first_admin_email_domain.in?(["france-service.gouv.fr", "france-services.gouv.fr", "franceservices.gouv.fr"])
    end

    def first_admin_email_domain
      first_admin&.email&.split("@")&.last
    end

    def first_admin
      @first_admin ||= find_first_admin_by_creation_date || default_single_admin
    end

    # On cherche à savoir qui a ouvert l'espace
    # Parfois la création de l'espace passe par un TerritoryCreationRequest, parfois on n'a plus la
    # version PaperTrail qui correspond au create de l'espace
    #
    # Il est possible que l'admin courant ne soit pas le même que celui qui a créé l'espace.
    #
    # La manière la plus fiable semble donc être de trouver l'admin dont le rôle a été créé en même temps
    # que l'espace (avec parfois quelques millisecondes de différence)
    def find_first_admin_by_creation_date
      @territory.admin_agents.find do |agent|
        AgentTerritorialAccessRight.where(agent_id: agent.id, territory_id: @territory.id)
          .where("created_at > ? AND created_at < ?", @territory.created_at - 1.second, @territory.created_at + 1.second).any?
      end
    end

    def default_single_admin
      if @territory.admin_agents.count == 1
        @territory.admin_agents.first
      end
    end
  end
end
