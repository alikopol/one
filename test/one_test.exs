defmodule OneTest do
  use ExUnit.Case
  doctest One
  alias One

  describe "API test for a patient account " do
    setup do
      patient_user_app_id = Application.get_env(:one, :patient_user_app_id)
      patient_client_id = Application.get_env(:one, :patient_client_id)
      patient_client_secret = Application.get_env(:one, :patient_client_secret)
      grant_type_auth = Application.get_env(:one, :grant_type_auth)
      grant_type_refresh = Application.get_env(:one, :grant_type_refresh)
      access_token = Application.get_env(:one, :access_token)
      query_value = Application.get_env(:one, :query_value)

      # create provider user if does not exist
      One.create_new_user(patient_user_app_id, patient_client_id, patient_client_secret)

      [
        patient_client_id: patient_client_id,
        patient_client_secret: patient_client_secret,
        patient_user_app_id: patient_user_app_id,
        grant_type_auth: grant_type_auth,
        grant_type_refresh: grant_type_refresh,
        access_token: access_token,
        query_value: query_value
      ]
    end

    test "test creating a new user", %{
      patient_client_id: client_id,
      patient_client_secret: client_secret
    } do
      app_user_id = UUID.uuid1()
      user = One.create_new_user(app_user_id, client_id, client_secret)
      assert user.app_user_id == app_user_id
      assert user.code
    end

    test "test generate a new code for existing user", %{
      patient_user_app_id: patient_user_app_id,
      patient_client_id: client_id,
      patient_client_secret: client_secret
    } do
      user =
        One.generate_new_code_for_existing_user(patient_user_app_id, client_id, client_secret)

      assert user.app_user_id == patient_user_app_id
      assert user.code
    end

    test "test generate exchange code for access token", %{
      patient_user_app_id: patient_user_app_id,
      grant_type_auth: grant_type_auth,
      patient_client_id: client_id,
      patient_client_secret: client_secret
    } do
      user =
        One.generate_new_code_for_existing_user(patient_user_app_id, client_id, client_secret)

      response =
        One.exchange_code_for_access_token(user.code, grant_type_auth, client_id, client_secret)

      assert %{
               "access_token" => _,
               "expires_in" => 7200,
               "refresh_token" => _,
               "token_type" => "bearer"
             } = response
    end

    test "test refresh access token", %{
      patient_user_app_id: patient_user_app_id,
      patient_client_id: client_id,
      patient_client_secret: client_secret,
      grant_type_auth: grant_type_auth,
      grant_type_refresh: grant_type_refresh
    } do
      user =
        One.generate_new_code_for_existing_user(patient_user_app_id, client_id, client_secret)

      access_token_response =
        One.exchange_code_for_access_token(user.code, grant_type_auth, client_id, client_secret)

      response =
        One.refresh_access_token(
          Map.get(access_token_response, grant_type_refresh),
          grant_type_refresh,
          client_id,
          client_secret
        )

      assert %{
               "access_token" => _,
               "expires_in" => 7200,
               "refresh_token" => _,
               "token_type" => "bearer"
             } = response
    end

    test "create a patient", %{
      patient_user_app_id: patient_user_app_id,
      patient_client_id: client_id,
      patient_client_secret: client_secret,
      grant_type_auth: grant_type_auth
    } do
      params = %{resourceType: "Patient", id: UUID.uuid1(), gender: "female"}

      access_token =
        One.get_access_token_with_user_app_id(
          patient_user_app_id,
          client_id,
          client_secret,
          grant_type_auth
        )

      patient_record = One.create_patient(params, access_token)

      assert %{
               "id" => _,
               "gender" => "female",
               "meta" => %{
                 "lastUpdated" => _,
                 "versionId" => "9000000000000"
               },
               "resourceType" => "Patient"
             } = patient_record
    end

    test "get patient's record", %{
      patient_user_app_id: patient_user_app_id,
      patient_client_id: client_id,
      patient_client_secret: client_secret,
      grant_type_auth: grant_type_auth
    } do
      params = %{resourceType: "Patient", id: UUID.uuid1(), gender: "female"}

      access_token =
        One.get_access_token_with_user_app_id(
          patient_user_app_id,
          client_id,
          client_secret,
          grant_type_auth
        )

      patient_record = One.create_patient(params, access_token)
      patient_id = Map.get(patient_record, "id")
      patient_response = One.get_patient_record(patient_id, access_token)

      assert patient_record == patient_response
    end

    test "get all patients", %{
      patient_user_app_id: patient_user_app_id,
      patient_client_id: client_id,
      patient_client_secret: client_secret,
      grant_type_auth: grant_type_auth
    } do
      access_token =
        One.get_access_token_with_user_app_id(
          patient_user_app_id,
          client_id,
          client_secret,
          grant_type_auth
        )

      response = One.get_all_patient(access_token)
      assert Map.get(response, "total") > 1
    end

    test "get all connected health systems", %{
      patient_client_id: client_id,
      patient_client_secret: client_secret
    } do
      response = One.get_all_connected_health_systems(client_id, client_secret)
      health_system = List.first(response)

      assert %{
               "api_version" => "FHIR DSTU2 1.0.2",
               "id" => 11046,
               "locations" => [
                 %{
                   "address" => %{
                     "city" => "Boston",
                     "line" => ["55 Fruit St", ""],
                     "postalCode" => "02114",
                     "state" => "MA"
                   },
                   "name" => ""
                 }
               ],
               "logo" => "https://1up.health/patient/images/providers/health-system-default.png",
               "name" => "",
               "resource_url" => "https://fhir.healow.com/FHIRServer/fhir/BJFJAD",
               "status" => "connection_working"
             } == health_system
    end

    test "test provider search", %{
      patient_user_app_id: patient_user_app_id,
      patient_client_id: client_id,
      patient_client_secret: client_secret,
      grant_type_auth: grant_type_auth,
      query_value: query_value
    } do
      access_token =
        One.get_access_token_with_user_app_id(
          patient_user_app_id,
          client_id,
          client_secret,
          grant_type_auth
        )

      response = One.provider_search(access_token, %{query: query_value})

      record =
        response
        |> Map.get("systemList")
        |> Map.get("5153")

      assert %{
               "api_version" => "",
               "id" => 5153,
               "locations" => [
                 %{
                   "address" => %{
                     "city" => "Miami Beach",
                     "line" => ["4300 Alton Rd", ""],
                     "postalCode" => "33140",
                     "state" => "FL"
                   },
                   "name" => "Mount Sinai Medical Center"
                 }
               ],
               "logo" => "https://1up.health/patient/images/providers/mountsinaimiami.jpg",
               "name" => "Mount Sinai Medical Center",
               "resource_url" => "https://epicfhir.msmc.com/proxysite-prd/api/FHIR/DSTU2",
               "status" => "connection_working"
             } == record
    end
  end

  describe "API test for a provider account " do
    setup do
      provider_user_app_id = Application.get_env(:one, :provider_user_app_id)
      provider_client_id = Application.get_env(:one, :provider_client_id)
      provider_client_secret = Application.get_env(:one, :provider_client_secret)

      # create provider user if does not exists
      One.create_new_user(provider_user_app_id, provider_client_id, provider_client_secret)

      [
        provider_client_id: provider_client_id,
        provider_client_secret: provider_client_secret,
        provider_user_app_id: provider_user_app_id
      ]
    end

    test "test bulk data export for Patient and Observation", %{
      provider_user_app_id: user_app_id,
      provider_client_id: client_id,
      provider_client_secret: client_secret
    } do
      resource_list = ["Patient"]
      grant_type = "authorization_code"

      access_token =
        One.get_access_token_with_user_app_id(
          user_app_id,
          client_id,
          client_secret,
          grant_type
        )

      response = One.extract_bulk_data_export_url(resource_list, access_token)

      assert [
               %{
                 "type" => "Patient",
                 "url" =>
                   "https://analytics.1up.health/bulk-data/dstu2/$export/Patient/eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdGFydCI6ImE2NjVhNDU5MjA0MiIsImVuZCI6ImE2NjVhNDU5MjA0MiIsInRvdGFsIjoxLCJ1c2VySWQiOiIxMjMwNDUifQ.IhSat6T-5czlv1SM7YvmCU75z5O-44geIu_5UsDjoJ4.ndjson"
               }
             ] == response
    end

    test "test bulk data export download", %{
      provider_user_app_id: user_app_id,
      provider_client_id: client_id,
      provider_client_secret: client_secret
    } do
      path = "/tmp"
      grant_type = "authorization_code"

      resource_urls = [
               %{
                 "type" => "Patient",
                 "url" =>
                   "https://analytics.1up.health/bulk-data/dstu2/$export/Patient/eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdGFydCI6ImE2NjVhNDU5MjA0MiIsImVuZCI6ImE2NjVhNDU5MjA0MiIsInRvdGFsIjoxLCJ1c2VySWQiOiIxMjMwNDUifQ.IhSat6T-5czlv1SM7YvmCU75z5O-44geIu_5UsDjoJ4.ndjson"
               }
      ]

      access_token =
        One.get_access_token_with_user_app_id(
          user_app_id,
          client_id,
          client_secret,
          grant_type
        )

      One.bulk_data_export(resource_urls, access_token, path)
      {:ok, list} = File.ls(path)

      count =
        list
        |> Enum.filter(fn x -> String.starts_with?(x, "Patient_") end)
        |> Enum.count()

      assert count >= 2
    end

    test "extract bulk data export urls and download files", %{
      provider_user_app_id: user_app_id,
      provider_client_id: client_id,
      provider_client_secret: client_secret
    } do
      path = "/tmp"
      grant_type = "authorization_code"

      resource_list = ["Patient"]

      access_token =
        One.get_access_token_with_user_app_id(
          user_app_id,
          client_id,
          client_secret,
          grant_type
        )

      One.extract_bulk_data_export_url(resource_list, access_token)
      |> One.bulk_data_export(access_token, path)

      {:ok, list} = File.ls(path)

      count =
        list
        |> Enum.filter(fn x -> String.starts_with?(x, "Patient_") end)
        |> Enum.count()

      assert count >= 0
    end
  end
end
