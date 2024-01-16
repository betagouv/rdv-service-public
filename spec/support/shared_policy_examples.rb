RSpec.shared_examples "permit actions" do |model, *actions|
  actions.each do |action|
    permissions action do
      it { is_expected.to permit(pundit_context, send(model)) }
    end
  end
end

RSpec.shared_examples "not permit actions" do |model, *actions|
  actions.each do |action|
    permissions action do
      it { is_expected.not_to permit(pundit_context, send(model)) }
    end
  end
end
