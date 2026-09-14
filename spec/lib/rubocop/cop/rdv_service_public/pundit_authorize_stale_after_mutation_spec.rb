require "rubocop"
require "rubocop/rspec/support"
require Rails.root.join("lib/rubocop/cop/rdv_service_public/pundit_authorize_stale_after_mutation")

RSpec.describe RuboCop::Cop::RdvServicePublic::PunditAuthorizeStaleAfterMutation do
  include RuboCop::RSpec::ExpectOffense

  subject(:cop) { described_class.new }

  it "flags a mutation that happens after authorize, with no re-authorize after" do
    expect_offense(<<~RUBY)
      def update
        authorize(@absence, policy_class: Agent::AbsencePolicy)
        @absence.update!(update_params)
                 ^^^^^^^ RdvServicePublic/PunditAuthorizeStaleAfterMutation: `@absence` est modifié via `#update!` après avoir été passé à `authorize`, sans nouvel `authorize` après la modification. Si les attributs modifiés peuvent changer le verdict de la policy, appelle `authorize` sur l'état final, juste avant `save`.
      end
    RUBY
  end

  it "does not flag when the record is re-authorized after the mutation" do
    expect_no_offenses(<<~RUBY)
      def update
        authorize(@territory, policy_class: SuperAdmin::TerritoryPolicy)
        @territory.assign_attributes(params.require(:territory).permit(:category))
        authorize(@territory, policy_class: SuperAdmin::TerritoryPolicy)
        @territory.save
      end
    RUBY
  end

  it "does not flag when attributes are assigned before authorize" do
    expect_no_offenses(<<~RUBY)
      def update
        @user.assign_attributes(params_for_update)
        authorize(@user, policy_class: Agent::UserPolicy)
        @user.save!
      end
    RUBY
  end

  it "does not flag a mutation on an object that was never authorized" do
    expect_no_offenses(<<~RUBY)
      def update
        authorize(@organisation, policy_class: Agent::OrganisationPolicy)
        @other_record.update!(foo: 1)
      end
    RUBY
  end

  it "does not flag a bare save with no arguments after authorize" do
    expect_no_offenses(<<~RUBY)
      def create
        motif = Motif.new(motif_params)
        authorize(motif, policy_class: Agent::MotifPolicy)
        motif.save!
      end
    RUBY
  end
end
