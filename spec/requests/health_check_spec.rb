#
# Cet endpoint a été ajouté lors de la migration de Scalingo vers OVH.
# En effet, la nouvelle stack a besoin d'un endpoint de health check pour
# savoir si l'appli tourne, et la redémarrer si nécessaire.
#
# La particularité de cette route est qu'elle doit être accessible en
# production en HTTP plutôt qu'en HTTP, car l'agent qui fait le health
# check est interne au réseau Kubernetes (le HTTPS en géré à l'extérieur).
# Nous avons donc défini une config.ssl_options qui exclut cette route.
#
RSpec.describe "/health_check" do
  it "returns HTTP 200" do
    get "/health_check"
    expect(response).to have_http_status(:ok)
  end
end
