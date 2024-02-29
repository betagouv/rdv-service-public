RSpec.describe "layouts/_flash", type: :view do
  it "sanitizes JS out of links" do
    notice = <<~HTML
      <a href="javascript:alert('hi');">Cliquez ici</a>
    HTML
    render(partial: "layouts/flash", locals: { flash: { notice: notice } })
    expect(rendered).to include("<a>Cliquez ici</a>")
  end

  # This partial uses the :prune scrubber to remove non-permitted tags, more info here:
  # https://github.com/flavorjones/loofah?tab=readme-ov-file#built-in-html-scrubbers
  it "only keeps <a>, <br>, <strong> and <em> tags" do
    notice = <<~HTML
      <script>console.log("hehe")</script>
      <a href="/legit/path"></a>
      <br/>
      <iframe>hello</iframe>
      <br>
      <strong>Very important</strong>
      <em>Less important</em>
    HTML

    expected_output = <<~HTML
      <a href="/legit/path"></a>
      <br>
      <br>
      <strong>Very important</strong>
      <em>Less important</em>
    HTML

    render(partial: "layouts/flash", locals: { flash: { notice: notice } })
    expect(rendered.squish).to include(expected_output.squish)
  end
end
