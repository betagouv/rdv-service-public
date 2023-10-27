describe WebSearchContext, type: :service do
  subject { described_class.new(user: user, query_params: query_params) }

  include_examples "SearchContext"

  describe "#filter_motifs" do
    it "doesnt returns motif when user is not invited (and motif's bookable_by is agents_and_prescripteurs_and_invited_users)" do
      lieu = create(:lieu)
      query_params[:motif_category_short_name] = "rsa_orientation"
      query_params[:lieu_id] = lieu.id
      search_context = described_class.new(user: nil, query_params: query_params)
      motif = create(:motif, bookable_by: :agents_and_prescripteurs_and_invited_users, motif_category: rsa_orientation, organisation: organisation)
      create(:plage_ouverture, motifs: [motif], lieu: lieu)
      expect(search_context.filter_motifs(Motif.where(id: motif.id))).to eq([])
    end
  end
end
