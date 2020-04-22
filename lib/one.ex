defmodule One do
  alias HTTP

  @moduledoc """
  1up Health API documentation
  """
  @user_url Application.get_env(:one, :user_url)
  @auth_url Application.get_env(:one, :auth_url)
  @token_url Application.get_env(:one, :token_url)
  @patient_url Application.get_env(:one, :patient_url)
  @clinical_url Application.get_env(:one, :clinical_url)
  @query_url Application.get_env(:one, :query_url)
  @analytics_url Application.get_env(:one, :analytics_url)

  @doc """
    An application can create users via the following call.
    You will need to replace client_id and client_secret with the values you obtained when you registered and created
    your 1upHealth application (visit https://1up.health/dev/quick-start).

    Each response will contain the new user's oneup_user_id, access_token, refresh_token, and app_user_id.
    The app_user_id helps you keep track of users between the 1up API and your own user management system.
    This must be a unique value for your application.
  """
  def create_new_user(
        app_user_id,
        client_id,
        client_secret
      ) do
    #
    params = %{
      app_user_id: app_user_id,
      client_id: client_id,
      client_secret: client_secret
    }

    client = HTTP.post_client(@user_url)

    with {:ok, response} <- HTTP.post(client, params),
         true <- Map.get(Jason.decode!(response.body), "success") do
      %{app_user_id: app_user_id, code: Map.get(Jason.decode!(response.body), "code")}
    else
      error ->
        "user could not be created (unexpected response: #{inspect(error)})"
    end
  end

  @doc """
    If you need a new auth code for a user you already created on 1upHealth, you can make a request via the following
    method with client_id and client_secret values replaced with your registered application's values.

    The code variable is the OAuth2 access code. You must exchange that to get the OAuth2 access token by following the
    the OAuth2 token grant steps. The access_token and refresh_token will be used to gain access to user data. Keep
    those secure via HIPAA compliant means of transmission and storage, along with all other patient data.
    The auth token expires after 7200 seconds (2 hours).
  """
  def generate_new_code_for_existing_user(
        app_user_id,
        client_id,
        client_secret
      ) do
    params = %{
      app_user_id: app_user_id,
      client_id: client_id,
      client_secret: client_secret
    }

    client = HTTP.post_client(@auth_url)

    with {:ok, response} <- HTTP.post(client, params),
         true <- Map.get(Jason.decode!(response.body), "success") do
      %{app_user_id: app_user_id, code: Map.get(Jason.decode!(response.body), "code")}
    else
      error ->
        "code could not be generated (unexpected response: #{inspect(error)})"
    end
  end

  @doc """
    Use the following API call to exchange the OAuth Access Code received in  following cases:
    1. Create New User or
    2. Generate New Auth Code for Existing User.

    The code variable is the OAuth2 access code. You must exchange that to get the OAuth2 access token by following the
    the OAuth2 token grant steps. The access_token and refresh_token will be used to gain access to user data.
    Keep those secure via HIPAA compliant means of transmission and storage, along with all other patient data.
    The auth token expires after 7200 seconds (2 hours).

    You must also replace the values for client_id and client_secret with values obtained when registering your
    application (visit https://1up.health/dev/quick-start).
  """
  def exchange_code_for_access_token(
        code,
        grant_type,
        client_id,
        client_secret
      ) do
    params = %{
      code: code,
      grant_type: grant_type,
      client_id: client_id,
      client_secret: client_secret
    }

    client = HTTP.post_client(@token_url)

    case HTTP.post(client, params) do
      {:ok, response} ->
        Jason.decode!(response.body)

      {:error, error} ->
        "could not exchange code with access token (#{inspect(error)})"

      error ->
        "could not exchange code with access token (unexpected response: #{inspect(error)})"
    end
  end

  @doc """
    Once 7200 seconds passes (which is 2 hours), the access_token will no longer be valid.To get a new token, you can
    either use the refresh token you received with `exchange_code_for_access_token` method.
    You must also replace the values for client_id and client_secret with values obtained when registering your
    application (visit https://1up.health/dev/quick-start).
  """
  def refresh_access_token(
        refresh_token,
        grant_type,
        client_id,
        client_secret
      ) do
    params = %{
      refresh_token: refresh_token,
      grant_type: grant_type,
      client_id: client_id,
      client_secret: client_secret
    }

    client = HTTP.post_client(@token_url)

    case HTTP.post(client, params) do
      {:ok, response} ->
        Jason.decode!(response.body)

      {:error, error} ->
        "could not refresh access token (#{inspect(error)})"

      error ->
        "could not refresh access token (unexpected response: #{inspect(error)})"
    end
  end

  @doc """
    You will need to include your OAuth Access Token as a Bearer Token in the Authorization Header.
    Once you have your OAuth Access Token, you can make the following call to create a FHIR Resource (in this case a
    Patient resource, but you can also obtain other resources as listed here:
    https://1up.health/dev/reference/fhir-resources) by including the resource elements in the Body of the request
  """
  def create_patient(params, access_token) do
    headers = [{"authorization", "Bearer #{access_token}"}]
    client = HTTP.post_client(@patient_url, headers)

    case HTTP.post(client, params) do
      {:ok, response} ->
        Jason.decode!(response.body)

      {:error, error} ->
        "could not create patient (#{inspect(error)})"

      error ->
        "could not create patient  (unexpected response: #{inspect(error)})"
    end
  end

  @doc """
  The Provider Search API can be used to make custom provider search interface for patients or retrieve results returned
  from connected health systems. Plug the access_token with the client_id and client_secret for the application in the
  header as a Bearer Token and search term as a query parameter in the url.

  https://1up.health/dev/doc/provider-search-ui

  Result is a list a health systems, clinics, hospitals or doctors for the searched term with 1up health system id which
  can be used to direct an user to a quick connect page or a patient portal (using the same access token) to initiate
  the login process.
  """
  def provider_search(access_token, params) do
    headers = [{"authorization", "Bearer #{access_token}"}]
    client = HTTP.post_client(@query_url, headers)

    case HTTP.post(client, params) do
      {:ok, response} ->
        Jason.decode!(response.body)

      {:error, error} ->
        "could not search provider with the provided access token (#{inspect(error)})"

      error ->
        "could not search provider with the provided access token (unexpected response: #{
          inspect(error)
        })"
    end
  end

  @doc """
  You will need to include your OAuth Access Token as a Bearer Token in the Authorization Header and patient_id.
  then you can query the user resource for Patient by using patient ID and the user token. You’ll only see basic data
  with this endpoint. Once you add a health system EHR, you’ll query other endpoints to get more data.

  """
  def get_patient_record(patient_id, access_token) do
    url = Enum.join([@patient_url, patient_id], "/")
    headers = [{"authorization", "Bearer #{access_token}"}]
    client = HTTP.get_client(url, [], headers)

    case HTTP.get(client, "") do
      {:ok, response} ->
        Jason.decode!(response.body)

      {:error, error} ->
        "could not get patient record with patient_id: #{patient_id} (#{inspect(error)})"

      error ->
        "could not get patient record with patient_id: #{patient_id} (unexpected response: #{
          inspect(error)
        })"
    end
  end

  @doc """
    You will need to include your OAuth Access Token as a Bearer Token in the Authorization Header.
    Once you have your OAuth Access Token, you can make the following call to obtain a bundle of available FHIR Resources
    (in this case Patient, but you can also obtain other resources as listed here:
    https://1up.health/dev/reference/fhir-resources).
    You can also include https://api.1up.health/fhir/dstu2/Patient/{{resource_id}} when you know the resource id.
  """
  def get_all_patient(access_token) do
    headers = [{"authorization", "Bearer #{access_token}"}]
    client = HTTP.get_client(@patient_url, [], headers)

    case HTTP.get(client) do
      {:ok, response} ->
        Jason.decode!(response.body)

      {:error, error} ->
        "could not get all patient (#{inspect(error)})"

      error ->
        "could not get all patient (unexpected response: #{inspect(error)})"
    end
  end

  @doc """
  Currently 1upHealth supports 1000s of health systems(https://1up.health/health-systems).
  You can find the full list by querying the endpoint here.
  You will need the client_id and client_secret environment variables.
  """
  def get_all_connected_health_systems(client_id, client_secret) do
    params = %{client_id: client_id, client_secret: client_secret}
    client = HTTP.get_client(@clinical_url, params)

    case HTTP.get(client) do
      {:ok, response} ->
        Jason.decode!(response.body)

      {:error, error} ->
        "could not get all connected health systems (#{inspect(error)})"

      error ->
        "could not get all connected health systems (unexpected response: #{inspect(error)})"
    end
  end

  @doc """
  Request the analytics bulk-data endpoint with the FHIR® $export operator to retrieve a list of bulk data files for
  your client application to download.

  https://1up.health/dev/doc/fhir-bulk-data-export

  This will return at least one bulk data download url for each resource type for which resources exist. This will only
  return resources that your given application client id and user id have access to. Optionally include a _type query
  parameter with a comma-separated list of FHIR® resources to limit the types of resources that you want to export, e.g.

  https://analytics.1up.health/bulk-data/dstu2/$export?_type=Patient,Observation
  """
  def extract_bulk_data_export_url(resources, access_token) do
    resources = Enum.join(resources, ",")
    params = %{_type: resources}
    headers = [{"authorization", "Bearer #{access_token}"}]
    client = HTTP.get_client(@analytics_url, params, headers)

    case HTTP.get(client, "/$export") do
      {:ok, response} ->
        Jason.decode!(response.body)
        |> Map.get("output")

      {:error, error} ->
        "could not extract bulk data export urls (#{inspect(error)})"

      error ->
        "could not extract bulk data export urls (unexpected response: #{inspect(error)})"
    end
  end

  @doc """
  Request the analytics bulk-data endpoint with the FHIR® $export operator to retrieve bulk data files from urls
  obtained with extract_bulk_data_export_url function.
  """
  def bulk_data_export(resource_urls, access_token, path \\ "/tmp") do
    resource_urls
    |> Enum.map(fn %{"type" => type, "url" => url} ->
      headers = [{"authorization", "Bearer #{access_token}"}]
      client = HTTP.get_client(url, %{}, headers)

      case HTTP.get(client) do
        nil ->
          nil

        {:ok, %Tesla.Env{body: body}} ->
          datetime = DateTime.utc_now() |> Timex.format!("%Y-%m-%dT%H:%M:%S:%L", :strftime)
          File.write("#{path}/#{type}_#{datetime}.json", body, [:write])
      end
    end)
  end

  @doc """
  Get new access token for an existing user with its user_app_id
  """
  def get_access_token_with_user_app_id(
        user_app_id,
        client_id,
        client_secret,
        grant_type
      ) do
    One.generate_new_code_for_existing_user(user_app_id, client_id, client_secret)
    |> Map.get(:code)
    |> One.exchange_code_for_access_token(grant_type, client_id, client_secret)
    |> Map.get("access_token")
  end
end
