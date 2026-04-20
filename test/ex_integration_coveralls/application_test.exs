defmodule ExIntegrationCoveralls.ApplicationTest do
  use ExUnit.Case, async: false
  alias ExIntegrationCoveralls.Application, as: App

  test "is_use_cov_worker?/0 returns configured value" do
    # Default is true
    assert App.is_use_cov_worker?() == true
  end

  test "is_use_cov_worker?/0 respects config" do
    original = Application.get_env(:cov_worker, :enable_cov_worker)

    on_exit(fn ->
      if original == nil do
        Application.delete_env(:cov_worker, :enable_cov_worker)
      else
        Application.put_env(:cov_worker, :enable_cov_worker, original)
      end
    end)

    Application.put_env(:cov_worker, :enable_cov_worker, false)
    refute App.is_use_cov_worker?()

    Application.put_env(:cov_worker, :enable_cov_worker, true)
    assert App.is_use_cov_worker?()
  end
end
