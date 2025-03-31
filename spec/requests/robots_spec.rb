RSpec.describe "/robots.txt" do
  let(:public_robots) do
    <<~ROBOTS
      # See http://www.robotstxt.org/robotstxt.html for documentation on how to use the robots.txt file
      User-agent: *
      Disallow: /
      Allow: /$
      Allow: /mds
      Allow: /accessibility
      Allow: /mentions_legales
      Allow: /cgu
      Allow: /politique_de_confidentialite
      Allow: /domaines
      Allow: /aide
    ROBOTS
  end

  let(:private_robots) do
    <<~ROBOTS
      # See http://www.robotstxt.org/robotstxt.html for documentation on how to use the robots.txt file
      User-agent: *
      Disallow: /
    ROBOTS
  end

  it "sert un robots.txt privé pour le domaine rdv.numerique.gouv.fr" do
    get "http://www.rdv-solidarites-test.localhost/robots.txt"
    expect(response.body).to eq(public_robots)
    get "http://www.rdv-aide-numerique-test.localhost/robots.txt"
    expect(response.body).to eq(public_robots)
    get "http://www.rdv-mairie-test.localhost/robots.txt"
    expect(response.body).to eq(public_robots)

    get "http://www.rdv-numerique-gouv-fr-test.localhost/robots.txt"
    expect(response.body).to eq(private_robots)
  end
end
