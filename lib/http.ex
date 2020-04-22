defmodule HTTP do
  def get(client, path \\ "") do
    Tesla.get(client, path)
  end

  def post(client, params, path \\ "") do
    Tesla.post(client, path, params)
  end

  def get_client(url, params \\ %{}, headers \\ [], options \\ []) do
    middleware = [
      {Tesla.Middleware.BaseUrl, url},
      {Tesla.Middleware.Headers, headers},
      {Tesla.Middleware.Query, params},
      {Tesla.Middleware.Opts, options}
    ]

    Tesla.client(middleware)
  end

  def post_client(url, headers \\ []) do
    middleware = [
      Tesla.Middleware.FormUrlencoded,
      {Tesla.Middleware.BaseUrl, url},
      {Tesla.Middleware.Headers, headers}
    ]

    Tesla.client(middleware)
  end
end
