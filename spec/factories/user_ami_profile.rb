FactoryBot.define do
  factory :user_ami_profile do
    user
    fc_hash { "4abd71ec1f581dce2ea2221cbeac7c973c6aea7bcb835acdfe7d6494f1528060" } # Le hash du premier usager de test dans l'environnement de sandbox
  end
end
