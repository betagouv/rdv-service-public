RSpec.describe "Tout le monde peut lire les nouveautés" do
  it "liste les nouveautés et permet de consulter chacune d'entre elles" do
    create(:blog_post, title: "Ancienne nouveauté", published_at: 2.months.ago)
    create(:blog_post, title: "Nouveauté récente", description: "Une description de la nouveauté", categories: ["Amélioration"], published_at: 1.day.ago)

    visit "/nouveautes"

    expect(page).to have_css("h1", text: "Nouveautés")
    expect(page.text.index("Nouveauté récente")).to be < page.text.index("Ancienne nouveauté")

    click_on "Nouveauté récente"

    expect(page).to have_css("h1", text: "Nouveauté récente")
    expect(page).to have_content("Une description de la nouveauté")
    expect(page).to have_content("Amélioration")

    click_on "Toutes les nouveautés"

    expect(page).to have_current_path("/nouveautes")
  end

  it "indique qu'il n'y a aucune nouveauté" do
    visit "/nouveautes"

    expect(page).to have_content("Aucune nouveauté pour le moment")
  end
end
