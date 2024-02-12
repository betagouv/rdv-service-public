RSpec.describe WebInvitationSearchContext, type: :service do
  subject { described_class.new(user: user, query_params: query_params) }

  include_context "SearchContext"

  describe "#matching_motifs" do
    context "when there are two available motifs from the geo search" do
      context "when one of the motif does not belong to the preselected orgs" do
        let!(:other_org) { create(:organisation) }

        before { motif2.update! organisation: other_org }

        it "returns only the matching motif from the preselected orgs" do
          expect(subject.send(:matching_motifs)).to eq([motif])
        end
      end
    end

    context "for an invitation" do
      subject { described_class.new(user: user, query_params: query_params) }

      before do
        query_params[:motif_category_short_name] = "rsa_orientation"
      end

      context "when there are matching motifs for the geo search" do
        it "is the geo maching motif" do
          expect(subject.send(:matching_motifs)).to eq([motif])
        end
      end

      context "when there are no matching motifs for the geo search" do
        before do
          allow(Motif).to receive(:available_for_booking)
            .and_return(Motif.where(id: motif2.id))
          query_params[:motif_category_short_name] = "rsa_orientation_on_phone_platform"
        end

        it "is the organisation matching motif" do
          expect(subject.send(:matching_motifs)).to eq([motif2])
        end
      end

      context "when agents are specified" do
        before { query_params[:referent_ids] = [agent.id] }

        let!(:agent) { create(:agent, users: [user]) }
        let!(:motif) { create(:motif, follow_up: true, motif_category: rsa_orientation, organisation: organisation) }
        let!(:plage_ouverture) { create(:plage_ouverture, agent: agent, motifs: [motif]) }
        let!(:geo_search) { instance_double(Users::GeoSearch, available_motifs: Motif.where(id: [motif.id, motif2.id])) }

        it "is the motifs related to agent" do
          expect(subject.send(:matching_motifs)).to eq([motif])
        end
      end
    end
  end

  describe "#filter_motifs" do
    it "returns motif when user is invited (and motif's bookable_by is agents_and_prescripteurs_and_invited_users)" do
      # This test will be obsolete when the invitation behavior will be integrated in Rdv-s (https://github.com/betagouv/rdv-solidarites.fr/issues/3438)
      lieu = create(:lieu)
      query_params[:motif_category_short_name] = "rsa_orientation"
      query_params[:lieu_id] = lieu.id
      search_context = described_class.new(user: nil, query_params: query_params)
      motif = create(:motif, bookable_by: :agents_and_prescripteurs_and_invited_users, motif_category: rsa_orientation, organisation: organisation)
      create(:plage_ouverture, motifs: [motif], lieu: lieu)
      expect(search_context.filter_motifs(Motif.where(id: motif.id))).to eq([motif])
    end
  end
end
