defmodule Azurex.Blob do
  @moduledoc """
  Implementation of Azure Blob Storage.
  """
  alias Azurex.Blob.Config
  alias Azurex.Authorization.SharedKey

  @typep optional_string :: String.t() | nil

  def list_containers do
    %HTTPoison.Request{
      url: Config.api_url() <> "/?comp=list"
    }
    |> SharedKey.sign(
      storage_account_name: Config.storage_account_name(),
      storage_account_key: Config.storage_account_key()
    )
    |> HTTPoison.request()
    |> case do
      {:ok, %{body: xml, status_code: 200}} -> {:ok, xml}
      {:ok, err} -> {:error, err}
      {:error, err} -> {:error, err}
    end
  end

  @doc """
  Upload a blob

  Currenty it lacks the possibility of sending parameters but using the default container.
  """
  @spec put_blob(String.t(), binary, String.t(), optional_string, keyword) ::
          :ok
          | {:error, HTTPoison.AsyncResponse.t() | HTTPoison.Error.t() | HTTPoison.Response.t()}
  def put_blob(name, blob, content_type, container \\ nil, params \\ []) do
    %HTTPoison.Request{
      method: :put,
      url: get_url(container, name),
      params: params,
      body: blob,
      headers: [
        {"x-ms-blob-type", "BlockBlob"}
      ],
      # Blob storage only answers when the whole file has been uploaded, so recv_timeout
      # is not applicable for the put request, so we set it to infinity
      options: [recv_timeout: :infinity]
    }
    |> SharedKey.sign(
      storage_account_name: Config.storage_account_name(),
      storage_account_key: Config.storage_account_key(),
      content_type: content_type
    )
    |> HTTPoison.request()
    |> case do
      {:ok, %{status_code: 201}} -> :ok
      {:ok, err} -> {:error, err}
      {:error, err} -> {:error, err}
    end
  end

  @doc """
  Download a blob

  Currenty it lacks the possibility of sending parameters but using the default container.
  """
  @spec get_blob(String.t(), optional_string) ::
          {:ok, binary()}
          | {:error, HTTPoison.AsyncResponse.t() | HTTPoison.Error.t() | HTTPoison.Response.t()}
  def get_blob(name, container \\ nil, params \\ []) do
    %HTTPoison.Request{
      method: :get,
      url: get_url(container, name),
      params: params
    }
    |> SharedKey.sign(
      storage_account_name: Config.storage_account_name(),
      storage_account_key: Config.storage_account_key()
    )
    |> HTTPoison.request()
    |> case do
      {:ok, %{body: blob, status_code: 200}} -> {:ok, blob}
      {:ok, err} -> {:error, err}
      {:error, err} -> {:error, err}
    end
  end

  @spec list_blobs(optional_string) ::
          {:ok, binary()}
          | {:error, HTTPoison.AsyncResponse.t() | HTTPoison.Error.t() | HTTPoison.Response.t()}
  def list_blobs(container \\ nil, params \\ []) do
    %HTTPoison.Request{
      url: "#{Config.api_url()}/#{get_container(container)}",
      params:
        [
          comp: "list",
          restype: "container"
        ] ++ params
    }
    |> SharedKey.sign(
      storage_account_name: Config.storage_account_name(),
      storage_account_key: Config.storage_account_key()
    )
    |> HTTPoison.request()
    |> case do
      {:ok, %{body: xml, status_code: 200}} -> {:ok, xml}
      {:ok, err} -> {:error, err}
      {:error, err} -> {:error, err}
    end
  end

  @spec get_url(optional_string) :: String.t()
  def get_url(container) do
    "#{Config.api_url()}/#{get_container(container)}"
  end

  @spec get_url(optional_string, String.t()) :: String.t()
  def get_url(container, name) do
    "#{get_url(container)}/#{name}"
  end

  def get_container(container) do
    container || Config.default_container()
  end
end
