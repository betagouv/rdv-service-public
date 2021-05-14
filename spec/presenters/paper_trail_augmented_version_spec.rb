# frozen_string_literal: true

describe PaperTrailAugmentedVersion do
  describe "#changes" do
    context "no previous version" do
      it "works with only object_changes" do
        version = instance_double(PaperTrail::Version)
        prepare_version_double(version, object_changes: { "title" => %w[foo bar] })
        expect(described_class.new(version, nil).changes).to eq(
          { "title" => %w[foo bar] }
        )
      end

      it "works with object_changes and virtual_attributes" do
        version = instance_double(PaperTrail::Version)
        prepare_version_double(
          version,
          object_changes: { "title" => %w[foo bar] },
          virtual_attributes: { "user_ids" => [1, 2] }
        )
        expect(described_class.new(version, nil).changes).to eq(
          {
            "title" => %w[foo bar],
            "user_ids" => [nil, [1, 2]]
          }
        )
      end
    end

    context "with some previous version" do
      let(:version) { instance_double(PaperTrail::Version) }
      let(:previous_version) { instance_double(PaperTrail::Version) }

      before do
        prepare_version_double(
          version,
          object_changes: { "title" => %w[foo bar] },
          virtual_attributes: { "user_ids" => [1, 2], "agent_ids" => [3] }
        )
        prepare_version_double(
          previous_version,
          object_changes: { "title" => %w[baz foo] },
          virtual_attributes: { "user_ids" => [1], "agent_ids" => [3] }
        )
      end

      it "computes virtual attributes changes from both versions" do
        expect(
          described_class.new(version, previous_version).changes
        ).to eq(
          {
            "title" => %w[foo bar],
            "user_ids" => [[1], [1, 2]]
            # agent_ids has not changed so it does not appear here
          }
        )
      end

      it "filters optional whitelisted attributes" do
        expect(
          described_class.new(
            version,
            previous_version,
            attributes_whitelist: ["user_ids"]
          ).changes
        ).to eq({ "user_ids" => [[1], [1, 2]] })
      end
    end
  end

  describe ".for_resource" do
    it "calls initializer with the right versions pairs" do
      resource = instance_double(Rdv)
      versions = [instance_double(PaperTrail::Version)] * 4
      augmented_versions = [instance_double(described_class)] * 4

      expect(resource).to receive(:versions).and_return(versions)
      expect(described_class).to receive(:new)
        .with(versions[0], nil)
        .and_return(augmented_versions[0])
      expect(described_class).to receive(:new)
        .with(versions[1], versions[0])
        .and_return(augmented_versions[1])
      expect(described_class).to receive(:new)
        .with(versions[2], versions[1])
        .and_return(augmented_versions[2])
      expect(described_class).to receive(:new)
        .with(versions[3], versions[2])
        .and_return(augmented_versions[3])

      expect(described_class.for_resource(resource)).to eq(
        augmented_versions
      )
    end
  end

  def prepare_version_double(some_version, object_changes: {}, virtual_attributes: {})
    changeset = double
    allow(some_version).to receive(:changeset).and_return(changeset)
    allow(changeset).to receive(:except).and_return(object_changes)
    expect(some_version).to receive(:virtual_attributes).and_return(virtual_attributes)
  end
end
