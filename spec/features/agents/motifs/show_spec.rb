RSpec.describe "Page d’un motif" do
  let(:organisation) { create(:organisation) }
  let!(:service) { create(:service, name: "PMI", territories: [organisation.territory]) }
  let!(:motif) { create(:motif, name: "Suivi bonjour", service:, organisation:) }
  let(:agent) { create(:agent, service:, admin_role_in_organisations: [organisation]) }

  before { login_as(agent, scope: :agent) }

  # Le contenu de la liste est masqué (attribut `hidden`) tant que le bouton n'est pas déroulé.
  # Sans JS (Rack::Test) il ne peut pas l'être : on cible donc les liens avec `visible: :all`.
  def dropdown_links
    all(".dropdown-button__link", visible: :all).map { _1.text(:all) }
  end

  it "affiche le motif et ses actions principales" do
    visit admin_organisation_motif_path(organisation, motif)

    expect(page).to have_css("h1", text: "Suivi bonjour (PMI)")
    expect(page).to have_link("Modifier")
    expect(page).to have_no_css(".dropdown-button__list", visible: :visible)
  end

  context "motif actif" do
    it "propose d’archiver dans « Plus d’actions », avec une confirmation" do
      visit admin_organisation_motif_path(organisation, motif)

      trigger = find_button("Plus d’actions")
      expect(trigger[:"aria-expanded"]).to eq("false")
      expect(trigger[:"aria-controls"]).to eq(find(".dropdown-button__list", visible: :all)[:id])
      expect(dropdown_links).to eq(%w[Dupliquer Archiver Supprimer])
      expect(find(".dropdown-button__link", text: "Archiver", visible: :all)).to match_css("[data-method=post][data-confirm]")
    end
  end

  context "motif archivé" do
    before { motif.archive }

    it "propose de réactiver et de supprimer" do
      visit admin_organisation_motif_path(organisation, motif)

      expect(page).to have_css("h1", text: "Suivi bonjour (PMI) (archivé)")
      expect(dropdown_links).to eq(%w[Dupliquer Réactiver Supprimer])
      expect(find(".dropdown-button__link", text: "Supprimer", visible: :all)).to match_css("[data-method=delete][data-confirm]")
    end
  end

  context "agent sans droit d’administration" do
    let(:agent) { create(:agent, service:, basic_role_in_organisations: [organisation]) }

    it "n’affiche pas le bouton « Plus d’actions »" do
      visit admin_organisation_motif_path(organisation, motif)

      expect(page).to have_css("h1", text: "Suivi bonjour (PMI)")
      expect(page).to have_no_button("Plus d’actions")
    end
  end

  def focused_text
    page.evaluate_script("document.activeElement.textContent").strip
  end

  # Seule spec en JS : elle vérifie en une fois le composant `common/dropdown_button`
  # (rendu, ouverture/fermeture, clavier, focus) et une action réelle du menu.
  describe "bouton déroulant « Plus d’actions »", :js do
    it "fonctionne à la souris et au clavier" do
      visit admin_organisation_motif_path(organisation, motif)
      trigger = find_button("Plus d’actions")
      list_css = ".dropdown-button__list"

      # Affichage : fermé, et ni tronqué ni écrasé dans le groupe de boutons
      expect(trigger[:"aria-expanded"]).to eq("false")
      expect(page).to have_no_css(list_css, visible: :visible)
      expect(trigger.native.evaluate("e => e.scrollWidth <= e.clientWidth && e.getBoundingClientRect().width > 100")).to be(true)

      # Souris : ouvre, referme, ferme au clic à l’extérieur
      trigger.click
      expect(trigger[:"aria-expanded"]).to eq("true")
      expect(page).to have_css("##{trigger[:"aria-controls"]}", visible: :visible)
      trigger.click
      expect(page).to have_no_css(list_css, visible: :visible)
      trigger.click
      find("h1").click
      expect(page).to have_no_css(list_css, visible: :visible)
      expect(trigger[:"aria-expanded"]).to eq("false")

      # Clavier : flèche bas ouvre et focalise la 1re action, Échap ferme et rend le focus au bouton
      trigger.send_keys(:down)
      expect(trigger[:"aria-expanded"]).to eq("true")
      expect(focused_text).to eq("Dupliquer")
      page.send_keys(:down)
      expect(focused_text).to eq("Archiver")
      page.send_keys(:end)
      expect(focused_text).to eq("Supprimer")
      page.send_keys(:down) # boucle sur la première action
      expect(focused_text).to eq("Dupliquer")
      page.send_keys(:up)
      expect(focused_text).to eq("Supprimer")
      page.send_keys(:home)
      expect(focused_text).to eq("Dupliquer")
      page.send_keys(:escape)
      expect(page).to have_no_css(list_css, visible: :visible)
      expect(page.evaluate_script("document.activeElement.textContent")).to include("Plus d’actions")

      # Clavier : Tab hors du composant ferme la liste
      trigger.click
      page.send_keys(:tab, :tab, :tab, :tab) # le bouton, les 3 actions, puis sortie du composant
      expect(page).to have_no_css(list_css, visible: :visible)

      # Action du menu : archivage avec confirmation
      trigger.click
      accept_confirm { find(".dropdown-button__link", text: "Archiver").click }
      expect(page).to have_css("h1", text: "Suivi bonjour (PMI) (archivé)")
      expect(motif.reload).to be_archived
    end
  end
end
