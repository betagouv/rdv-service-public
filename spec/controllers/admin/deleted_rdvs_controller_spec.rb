RSpec.describe Admin::DeletedRdvsController, type: :controller do
  render_views

  let!(:organisation) { create(:organisation) }
  let!(:admin) { create(:agent, admin_role_in_organisations: [organisation]) }
  let!(:other_agent) { create(:agent, basic_role_in_organisations: [organisation], service: admin.services.first) }
  let!(:user) { create(:user, first_name: "Jeanne", last_name: "Martin") }

  def delete_rdv(**attrs)
    rdv = create(:rdv, organisation: organisation, users: [user], **attrs)
    rdv.destroy!
  end

  describe "GET #index" do
    it "liste les RDV supprimés de l'organisation, même quand les références ont disparu" do
      delete_rdv(agents: [admin])
      other_orga = create(:organisation)
      create(:rdv, organisation: other_orga).destroy!
      Lieu.delete_all

      sign_in admin
      get :index, params: { organisation_id: organisation.id }

      expect(response).to be_successful
      expect(assigns(:deleted_rdvs).size).to eq(1)
      expect(response.body).to match(/martin/i)
    end

    it "affiche l'id et des liens vers motif, lieu, usagers et agents quand ils existent" do
      rdv = create(:rdv, organisation:, users: [user], agents: [admin])
      rdv.destroy!

      sign_in admin
      get :index, params: { organisation_id: organisation.id }

      expect(response.body).to include("deleted_rdv_#{rdv.id}")
      expect(response.body).to include(admin_organisation_motif_path(organisation, rdv.motif))
      expect(response.body).to include(edit_admin_organisation_lieu_path(organisation, rdv.lieu))
      expect(response.body).to include(admin_organisation_user_path(organisation, user))
      expect(response.body).to include(edit_admin_organisation_agent_path(organisation, admin))
      expect(response.body).to include(admin_organisation_rdvs_path(organisation)) # bouton de retour
    end

    it "affiche du texte sans lien quand les références n'existent plus" do
      rdv = create(:rdv, organisation:, users: [user], agents: [admin])
      rdv.destroy!
      motif = rdv.motif
      Lieu.where(id: rdv.lieu_id).delete_all
      user.update_columns(deleted_at: Time.zone.now) # rubocop:disable Rails/SkipsModelValidations
      Motif.where(id: motif.id).delete_all # le RDV est supprimé : plus de contrainte

      sign_in admin
      get :index, params: { organisation_id: organisation.id }

      expect(response.body).to include(motif.name)
      expect(response.body).not_to include(admin_organisation_motif_path(organisation, motif))
      expect(response.body).to include("##{rdv.lieu_id} (supprimé)")
      expect(response.body).to include("##{user.id} (supprimé)")
    end

    it "est réservé aux admins de l'organisation" do
      delete_rdv(agents: [other_agent])

      sign_in other_agent
      get :index, params: { organisation_id: organisation.id }

      expect(response).not_to be_successful
      expect(response.body).not_to include("deleted_rdv_")
    end

    it "n'affiche pas les RDV supprimés d'une organisation dont l'agent n'est pas admin" do
      other_orga = create(:organisation)
      create(:rdv, organisation: other_orga).destroy!
      create(:agent_role, agent: admin, organisation: other_orga, access_level: AgentRole::ACCESS_LEVEL_BASIC)

      sign_in admin
      get :index, params: { organisation_id: other_orga.id }

      expect(response).not_to be_successful
    end

    describe "requêtes SQL" do
      def count_queries
        queries = []
        subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
          queries << payload[:sql] unless payload[:name] == "SCHEMA"
        end
        yield
        queries.size
      ensure
        ActiveSupport::Notifications.unsubscribe(subscriber)
      end

      def delete_rdvs(count, agent)
        count.times do
          rdv = create(:rdv, organisation:, users: [create(:user, organisations: [organisation])], agents: [agent, create(:agent, basic_role_in_organisations: [organisation])], created_by: agent)
          rdv.deleted_by_agent = agent
          rdv.destroy!
        end
      end

      it "ne dépend pas du nombre de RDV affichés" do
        sign_in admin

        delete_rdvs(2, admin)
        get :index, params: { organisation_id: organisation.id } # appel à blanc : exclut les coûts uniques (session, caches)
        queries_for_2_rdvs = count_queries { get :index, params: { organisation_id: organisation.id } }

        delete_rdvs(8, admin)
        queries_for_10_rdvs = count_queries { get :index, params: { organisation_id: organisation.id } }

        expect(assigns(:deleted_rdvs).size).to eq(10)
        expect(queries_for_10_rdvs).to eq(queries_for_2_rdvs)
      end
    end

    it "pagine" do
      create_list(:rdv, 21, organisation:, agents: [admin]).each(&:destroy!)

      sign_in admin
      get :index, params: { organisation_id: organisation.id, page: 2 }
      expect(assigns(:deleted_rdvs).size).to eq(1)
    end
  end
end
