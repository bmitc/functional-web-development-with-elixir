defmodule IslandsInterfaceWeb.LayoutView do
  use IslandsInterfaceWeb, :view

  # Phoenix LiveDashboard is available only in development by default,
  # so we instruct Elixir to not warn if the dashboard route is missing.
  @compile {:no_warn_undefined, {Helpers, :live_dashboard_path, 2}}
end
