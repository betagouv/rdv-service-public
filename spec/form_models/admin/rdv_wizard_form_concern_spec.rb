# frozen_string_literal: true

class DummyWizardForm
  include ActiveModel::Model
  include Admin::RdvWizardFormConcern
end

describe Admin::RdvWizardFormConcern, type: :form do
  subject(:form) { DummyWizardForm.new(agent, organisation, {}) }

  let(:agent) { build(:agent) }
  let(:organisation) { build(:organisation) }

  Rdv.attribute_names.each do |attr_name|
    it "delegates the gettersfor the rdv attribute #{attr_name}" do
      value = double
      expect(form.rdv).to receive(attr_name).and_return(value)

      expect(form.public_send(attr_name)).to eq value
    end
  end
end
