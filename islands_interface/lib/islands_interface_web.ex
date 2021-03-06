defmodule IslandsInterfaceWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use IslandsInterfaceWeb, :controller
      use IslandsInterfaceWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  @doc """
  Phoenix generated function
  """
  @spec controller() :: any()
  def controller() do
    quote do
      use Phoenix.Controller, namespace: IslandsInterfaceWeb

      import Plug.Conn
      import IslandsInterfaceWeb.Gettext
      alias IslandsInterfaceWeb.Router.Helpers
    end
  end

  @doc """
  Phoenix generated function
  """
  @spec view() :: any()
  def view() do
    quote do
      use Phoenix.View,
        root: "lib/islands_interface_web/templates",
        namespace: IslandsInterfaceWeb

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_flash: 1, get_flash: 2, view_module: 1, view_template: 1]

      # Include shared imports and aliases for views
      unquote(view_helpers())
    end
  end

  @doc """
  Phoenix generated function
  """
  @spec live_view() :: any()
  def live_view() do
    quote do
      use Phoenix.LiveView,
        layout: {IslandsInterfaceWeb.LayoutView, "live.html"}

      unquote(view_helpers())
    end
  end

  @doc """
  Phoenix generated function
  """
  @spec live_component() :: any()
  def live_component() do
    quote do
      use Phoenix.LiveComponent

      unquote(view_helpers())
    end
  end

  @doc """
  Phoenix generated function
  """
  @spec component() :: any()
  def component() do
    quote do
      use Phoenix.Component

      unquote(view_helpers())
    end
  end

  @doc """
  Phoenix generated function
  """
  @spec router() :: any()
  def router() do
    quote do
      use Phoenix.Router

      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  @doc """
  Phoenix generated function
  """
  @spec channel() :: any()
  def channel() do
    quote do
      use Phoenix.Channel
      import IslandsInterfaceWeb.Gettext
    end
  end

  @spec view_helpers() :: any()
  defp view_helpers() do
    quote do
      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      # Import LiveView and .heex helpers (live_render, live_patch, <.form>, etc)
      import Phoenix.LiveView.Helpers

      # Import basic rendering functionality (render, render_layout, etc)
      import Phoenix.View

      import IslandsInterfaceWeb.ErrorHelpers
      import IslandsInterfaceWeb.Gettext
      alias IslandsInterfaceWeb.Router.Helpers
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
