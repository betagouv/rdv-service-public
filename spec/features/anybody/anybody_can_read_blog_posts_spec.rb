RSpec.describe "Tout le monde peut lire les nouveautés" do
  it "liste les nouveautés et permet de consulter chacune d'entre elles" do
    create(:blog_post, title: "Ancienne nouveauté", published_at: 2.months.ago)
    create(
      :blog_post,
      title: "Nouveauté récente",
      content_truncated_text: "Le résumé de la nouveauté",
      content_html: <<~HTML,
        <p>Le <strong>contenu complet</strong> de la nouveauté, avec un <a href="https://example.com/aide">lien</a>.</p>
        <img src="https://example.com/capture.png" alt="Capture d'écran">
        <script>alert("xss")</script>
      HTML
      categories: ["Amélioration"],
      published_at: 1.day.ago
    )

    visit "/nouveautes"

    expect(page).to have_css("h1", text: "Nouveautés")
    expect(page).to have_content("Le résumé de la nouveauté")
    expect(page.text.index("Nouveauté récente")).to be < page.text.index("Ancienne nouveauté")

    click_on "Nouveauté récente"

    expect(page).to have_css("h1", text: "Nouveauté récente")
    expect(page).to have_css("strong", text: "contenu complet")
    expect(page).to have_link("lien", href: "https://example.com/aide")
    expect(page).to have_css("img[src='https://example.com/capture.png'][alt=\"Capture d'écran\"]")
    expect(page).to have_no_css(".rdv-blog-post-content script")
    expect(page.response_headers["Content-Security-Policy"]).to include("img-src 'self' data: blob: tile.openstreetmap.org openmaptiles.data.gouv.fr lasuite.numerique.gouv.fr https://docs.numerique.gouv.fr/media/")
    expect(page).to have_content("Amélioration")

    click_on "Toutes les nouveautés"

    expect(page).to have_current_path("/nouveautes")
  end

  it "indique qu'il n'y a aucune nouveauté" do
    visit "/nouveautes"

    expect(page).to have_content("Aucune nouveauté pour le moment")
  end
end
