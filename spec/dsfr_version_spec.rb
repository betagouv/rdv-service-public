RSpec.describe "DSFR versions coherence" do # rubocop:disable RSpec/DescribeClass
  # Teste la cohérence entre les numéros de versions :
  # - du package `dsfr` installé via yarn
  # - du lien symbolique depuis public
  # - et des chemins dans les helpers via la config rails
  specify do
    yarn_lock_content = File.read("yarn.lock")
    version_match = yarn_lock_content.match(%r{@gouvfr/dsfr@[^:]+:\n\s+version\s+"([^"]+)"})
    expect(version_match).to be_truthy

    node_package_version = version_match[1]
    expect(node_package_version).to match(/\d+\.\d+\.\d+/)

    symlinks = Dir.glob("public/dsfr-v*")
    expect(symlinks).to eq(["public/dsfr-v#{node_package_version}"])
    expect(File.symlink?(symlinks.first)).to be_truthy # rubocop:disable RSpec/PredicateMatcher

    expect(Rails.configuration.x.dsfr.version).to eq(node_package_version)
  end
end
