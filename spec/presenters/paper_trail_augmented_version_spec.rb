describe PaperTrailAugmentedVersion do
  describe '#changes' do
    context 'no previous version' do
      it 'should work with only object_changes' do
        version = instance_double(PaperTrail::Version)
        prepare_version_double(version, object_changes: { 'title' => ['foo', 'bar'] })
        expect(PaperTrailAugmentedVersion.new(version, nil).changes).to eq(
          { 'title' => ['foo', 'bar'] }
        )
      end

      it 'should work with object_changes and virtual_attributes' do
        version = instance_double(PaperTrail::Version)
        prepare_version_double(
          version,
          object_changes: { 'title' => ['foo', 'bar'] },
          virtual_attributes: { 'user_ids' => [1, 2] }
        )
        expect(PaperTrailAugmentedVersion.new(version, nil).changes).to eq(
          {
            'title' => ['foo', 'bar'],
            'user_ids' => [nil, [1, 2]],
          }
        )
      end
    end

    context 'with some previous version' do
      let(:version) { instance_double(PaperTrail::Version) }
      let(:previous_version) { instance_double(PaperTrail::Version) }
      before do
        prepare_version_double(
          version,
          object_changes: { 'title' => ['foo', 'bar'] },
          virtual_attributes: { 'user_ids' => [1, 2], 'agent_ids' => [3] }
        )
        prepare_version_double(
          previous_version,
          object_changes: { 'title' => ['baz', 'foo'] },
          virtual_attributes: { 'user_ids' => [1], 'agent_ids' => [3] }
        )
      end

      it 'should compute virtual attributes changes from both versions' do
        expect(
          PaperTrailAugmentedVersion.new(version, previous_version).changes
        ).to eq(
          {
            'title' => ['foo', 'bar'],
            'user_ids' => [[1], [1, 2]],
            # agent_ids has not changed so it does not appear here
          }
        )
      end

      it 'filters optional whitelisted attributes' do
        expect(
          PaperTrailAugmentedVersion.new(
            version,
            previous_version,
            attributes_whitelist: ['user_ids']
          ).changes
        ).to eq({ 'user_ids' => [[1], [1, 2]] })
      end
    end
  end

  describe '.for_resource' do
    it 'should call initializer with the right versions pairs' do
      resource = instance_double(Rdv)
      versions = [instance_double(PaperTrail::Version)] * 4
      augmented_versions = [instance_double(PaperTrailAugmentedVersion)] * 4

      expect(resource).to receive(:versions).and_return(versions)
      expect(PaperTrailAugmentedVersion).to receive(:new)
        .with(versions[0], nil)
        .and_return(augmented_versions[0])
      expect(PaperTrailAugmentedVersion).to receive(:new)
        .with(versions[1], versions[0])
        .and_return(augmented_versions[1])
      expect(PaperTrailAugmentedVersion).to receive(:new)
        .with(versions[2], versions[1])
        .and_return(augmented_versions[2])
      expect(PaperTrailAugmentedVersion).to receive(:new)
        .with(versions[3], versions[2])
        .and_return(augmented_versions[3])

      expect(PaperTrailAugmentedVersion.for_resource(resource)).to eq(
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
