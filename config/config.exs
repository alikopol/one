# General application configuration
use Mix.Config

config :one,
  patient_user_app_id: "patient_user_app_id",
  provider_user_app_id: "12345",
  provider_client_id: "b9628a71629949c4a73a0caf3a345cb4",
  provider_client_secret: "L1kagBhV3soySu3ssLNbJYa0pdNhM9Hq",
  patient_client_id: "b9628a71629949c4a73a0caf3a345cb4",
  patient_client_secret: "L1kagBhV3soySu3ssLNbJYa0pdNhM9Hq",
  user_url: "https://api.1up.health/user-management/v1/user",
  auth_url: "https://api.1up.health/user-management/v1/user/auth-code",
  token_url: "https://api.1up.health/fhir/oauth2/token",
  patient_url: "https://api.1up.health/fhir/dstu2/Patient",
  clinical_url: "https://api.1up.health/connect/system/clinical",
  query_url: "https://system-search.1up.health/api/search",
  analytics_url: "https://analytics.1up.health/bulk-data/dstu2",
  grant_type_auth: "authorization_code",
  grant_type_refresh: "refresh_token",
  query_value: "saltzer",
  resource_list: ["Patient"]
