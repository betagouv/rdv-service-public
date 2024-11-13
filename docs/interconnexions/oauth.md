# RDV-SP comme provider OAuth

Cette application peut s'interconnecter avec des clients externes via le protocol Oauth 2.0. Ce mécanisme permet à une application tierce de proposer à ses utilisateurs d'autoriser l'application tierce à faire des appels à l'API RDV-SP en son nom. Par exemple, un agent qui a un compte sur demarches-simplifiees.fr peut autoriser la plateforme à créer des RDVs en son nom sur RDV-SP.

Ci-dessous le processus d'autorisation par lequel un agent de demarches-simplifiees.fr lie son compte à RDV-SP :

```mermaid
sequenceDiagram
    actor Agent
    participant DS
    participant RDVSP

    Agent->>+DS: Clic sur le bouton <br> "Se connecter avec RDV Service Public"
    DS-->>-Agent: Redirige vers <br> rdv.anct.gouv.fr/oauth/authorize?state=12345<br>&redirect_uri=demarches-simplifiees.fr/callback
    
    Agent->>+RDVSP: Suit la redirection
    RDVSP-->>-Agent: Affiche la page d'autorisation
    Agent->>+RDVSP: Clic sur "J'autorise DS à accéder à mes données RDV-SP"
    RDVSP-->>-Agent: Redirige vers demarches-simplifiees.fr<br>/omniauth/rdvservicepublic/callback?state=12345&code=abcde
    Agent->>DS: Suit la redirection

    activate DS
    DS->>+RDVSP: Échange le authorization code contre un access token : <br> POST rdv.anct.gouv.fr/oauth/token <br> code=abcde&grant_type=authorization_code
    RDVSP-->>-DS: Access token (aka Bearer token)
    DS->>+RDVSP: GET rdv.anct.gouv.fr/api/v1/agents/me.json
    RDVSP-->>-DS: { "id": 42, "email": "francis@gouv.fr", <br>"first_name":"Francis", "last_name": "Factice" }
    Note right of DS: DS Enregistre en base l'ID de l'agent RDV-SP
    DS-->>Agent: Affiche "Votre compte DS est connecté à RDV-SP"
    deactivate DS
```
