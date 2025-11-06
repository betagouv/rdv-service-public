RSpec.describe VerifiedServicePublicDomainNames do
  it "only has domains names starting with . or @ to avoid fake domains ending with the correct domain name from being validated" do
    described_class::DOMAINS.each do |domain|
      expect(domain.start_with?(".") || domain.start_with?("@")).to be_truthy
    end
  end
end
