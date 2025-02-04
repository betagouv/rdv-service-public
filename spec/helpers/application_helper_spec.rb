RSpec.describe ApplicationHelper do
  describe "#dsfr_path" do
    # cf /docs/4-notes-techniques.md la procédure de mise à jour du DSFR

    it "correspond à la version du node package" do
      bun_lock_content = File.read("bun.lock")
      bun_lock_content.gsub!(/,\s*([\]}])/, '\1') # remove trailing commas
      bun_lock = JSON.parse(bun_lock_content)
      node_package_version = bun_lock["packages"]["@gouvfr/dsfr"][0].split("@")[-1]
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
