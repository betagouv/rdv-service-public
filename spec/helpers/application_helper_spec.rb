RSpec.describe ApplicationHelper do
  describe "#dsfr_path" do
    # cf /docs/4-notes-techniques.md la procédure de mise à jour du DSFR

    it "correspond à la version du node package" do
      yarn_lock_content = File.read("yarn.lock")
      version_match = yarn_lock_content.match(%r{@gouvfr/dsfr@[^:]+:\n\s+version\s+"([^"]+)"})
      expect(version_match).to be_truthy

      node_package_version = version_match[1]
      expect(node_package_version).to match(/\d+\.\d+\.\d+/)

      expect(dsfr_path).to eq("/dsfr-v#{node_package_version}")
    end

    it "correspond au symlink présent dans public/" do
      symlinks = Dir.glob("public/dsfr-v*")
      expect(symlinks.size).to eq 1
      expect(File.symlink?(symlinks.first)).to be_truthy # rubocop:disable RSpec/PredicateMatcher

      symlink_version = symlinks.first.match(/\d+\.\d+\.\d+/)[0]

      expect(dsfr_path).to eq("/dsfr-v#{symlink_version}")
    end
  end
end
