defmodule ElixirBenchWeb.Schema do
  use Absinthe.Schema

  alias ElixirBenchWeb.Schema

  alias ElixirBench.{Repos, Benchmarks}

  import_types Absinthe.Type.Custom
  import_types Schema.ContentTypes

  query do
    field :repos, list_of(:repo) do
      resolve fn _, _ ->
        {:ok, Repos.list_repos()}
      end
    end

    field :repo, non_null(:repo) do
      arg :slug, non_null(:string)
      resolve fn %{slug: slug}, _ ->
        Repos.fetch_repo_by_slug(slug)
      end
    end

    field :benchmark, non_null(:benchmark) do
      arg :repo_slug, non_null(:string)
      arg :name, non_null(:string)
      resolve fn %{repo_slug: slug, name: name}, _ ->
        with {:ok, repo_id} <- Repos.fetch_repo_id_by_slug(slug) do
          Benchmarks.fetch_benchmark(repo_id, name)
        end
      end
    end

    field :measurement, non_null(:measurement) do
      arg :id, non_null(:id)
      resolve fn %{id: id}, _ ->
        Benchmarks.fetch_measurement(id)
      end
    end

    field :jobs, list_of(:job) do
      resolve fn _, _ ->
        {:ok, Benchmarks.list_jobs()}
      end
    end

    field :job, non_null(:job) do
      arg :id, non_null(:id)
      resolve fn %{id: id}, _ ->
        Benchmarks.fetch_job(id)
      end
    end
  end

  mutation do
    field :schedule_job, type: :job do
      arg :branch_name, non_null(:string)
      arg :commit_sha, non_null(:string)
      arg :repo_slug, non_null(:string)

      resolve fn %{repo_slug: slug} = data, _ ->
        with {:ok, repo} <- Repos.fetch_repo_by_slug(slug) do
          Benchmarks.create_job(repo, data)
        end
      end
    end
  end

  def context(ctx) do
    loader =
      Dataloader.new
      |> Dataloader.add_source(Repos, Repos.data())
      |> Dataloader.add_source(Benchmarks, Benchmarks.data())

    Map.put(ctx, :loader, loader)
  end

  def plugins do
    [Absinthe.Middleware.Dataloader] ++ Absinthe.Plugin.defaults()
  end
end
