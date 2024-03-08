RSpec.describe "Anybody can see the API docs" do
  it "works" do
    visit "/api-docs/index.html"
    expect(page.body).to include(%(<div id="swagger-ui">))
  end
end
