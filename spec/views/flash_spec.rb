RSpec.describe "layouts/_flash", type: :view do
  it "sanitizes JS out of links" do
    render(partial: "layouts/flash", locals: { flash: { notice: %(<a href="javascript:alert('hi');">Cliquez ici</a>) } })
    expect(rendered).to include("<a>Cliquez ici</a>")
  end
end
