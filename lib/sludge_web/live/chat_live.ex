defmodule SludgeWeb.ChatLive do
  use SludgeWeb, :live_view

  attr(:socket, Phoenix.LiveView.Socket, required: true, doc: "Parent live view socket")
  attr(:role, :string, required: true, doc: "Admin or user")
  attr(:id, :string, required: true, doc: "Component id")

  def live_render(assigns) do
    ~H"""
    {live_render(@socket, __MODULE__, id: @id, session: %{"role" => @role})}
    """
  end

  @impl true
  def render(%{role: "user"} = assigns) do
    ~H"""
    {render_chat(assigns)}
    """
  end

  def render(%{role: "admin"} = assigns) do
    ~H"""
    <div class="rounded-lg border border-indigo-200 flex flex-col h-full dark:border-zinc-800">
      <ul class="flex *:flex-1 items-center border-b border-indigo-200 dark:border-zinc-800">
        <li>
          <button
            phx-click="select-tab"
            phx-value-tab="chat"
            class={[
              "w-full h-full px-4 py-3 rounded-tl-[7px] text-center text-indigo-700 text-indigo-800 text-sm hover:text-white hover:bg-indigo-900 dark:text-white",
              @current_tab == "chat" &&
                "text-white bg-indigo-800 dark:hover:bg-indigo-700"
            ]}
          >
            Chat
          </button>
        </li>
        <li>
          <button
            phx-click="select-tab"
            phx-value-tab="reported"
            class={[
              "w-full h-full px-4 py-3 rounded-tr-[7px] text-center text-indigo-700 text-indigo-800 text-sm hover:text-white hover:bg-indigo-900 dark:text-white",
              @current_tab == "reported" &&
                "text-white bg-indigo-800 dark:hover:bg-indigo-700"
            ]}
          >
            Reported
          </button>
        </li>
      </ul>
      {render_chat(assigns)}
      {render_reported(assigns)}
    </div>
    """
  end

  def render_chat(assigns) do
    ~H"""
    <div
      class={[
        "h-full justify-between flex-col",
        @current_tab == "chat" && "flex",
        @current_tab != "chat" && "hidden",
        @role == "admin" && "",
        @role == "user" && "rounded-lg border border-indigo-200 dark:border-zinc-800"
      ]}
      id="sludge_chat"
    >
      <ul
        class="w-[440px] h-[0px] overflow-y-auto flex-grow flex flex-col"
        phx-hook="ScrollDownHook"
        id="message_box"
      >
        <li
          :for={msg <- @messages}
          id={msg.id <> "-msg"}
          class={[
            "flex flex-col gap-1 px-6 py-4 relative hover:bg-stone-100 dark:hover:bg-stone-800",
            msg.flagged && @role == "user" &&
              "bg-red-100 hover:bg-red-200 dark:bg-red-900 dark:hover:bg-red-800",
            @role == "user" && "first:rounded-t-[7px]"
          ]}
        >
          <div class="flex gap-4 justify-between items-center">
            <p class="text-indigo-800 text-sm text-medium dark:text-indigo-400">
              {msg.author}
            </p>
            <p class="text-xs text-neutral-500">
              {Calendar.strftime(msg.timestamp, "%d %b %Y %H:%M:%S")}
            </p>
          </div>
          <p class="dark:text-neutral-400">
            {msg.body}
          </p>
          <button
            class={[
              "absolute right-6 bottom-2 rounded-full hover:bg-stone-200 dark:hover:bg-stone-700 flex items-center justify-center p-2",
              msg.flagged && "hover:bg-red-300",
              @role == "admin" && "hidden"
            ]}
            phx-click="flag-message"
            phx-value-message-id={msg.id}
          >
            <.icon name="hero-flag" class="w-4 h-4 text-red-400" />
          </button>
        </li>
      </ul>
      <form
        phx-change="validate-form"
        phx-submit="submit-form"
        class="flex flex-col gap-2 border-t border-indigo-200 p-6 dark:border-zinc-800"
      >
        <textarea
          class="sludge-input-primary resize-none h-[128px] dark:text-neutral-400"
          placeholder="Your message"
          maxlength="500"
          name="body"
          value={@msg_body}
          disabled={is_nil(@author)}
        />
        <div class="flex gap-2">
          <input
            class="sludge-input-primary px-4 dark:text-neutral-400"
            placeholder="Your nickname"
            maxlength="25"
            name="author"
            value={@author}
            disabled={not is_nil(@author)}
          />
          <button type="submit" class="sludge-button-primary">
            <%= if is_nil(@author) do %>
              Join
            <% else %>
              Send
            <% end %>
          </button>
        </div>
      </form>
    </div>
    """
  end

  def render_reported(assigns) do
    ~H"""
    <div
      class={[
        "h-full justify-between flex-col",
        @current_tab == "reported" && "flex",
        @current_tab != "reported" && "hidden"
      ]}
      id="sludge_reported"
    >
      <ul class="w-[440px] overflow-y-auto flex-grow flex flex-col">
        <li
          :for={msg <- Enum.filter(@messages, fn m -> m.flagged end)}
          id={msg.id <> "-reported"}
          class={[
            "flex flex-col gap-1 px-6 py-4 relative hover:bg-stone-100 dark:hover:bg-stone-800",
            @role == "user" && "first:rounded-t-[7px]"
          ]}
        >
          <div class="flex gap-4 justify-between items-center">
            <p class="text-indigo-800 text-sm text-medium dark:text-indigo-400">
              {msg.author}
            </p>
            <p class="text-xs text-neutral-500">
              {Calendar.strftime(msg.timestamp, "%d %b %Y %H:%M:%S")}
            </p>
          </div>
          <p class="dark:text-neutral-400">
            {msg.body}
          </p>
          <div class="flex gap-4 items-center *:flex-1">
            <button
              class="bg-red-600 text-white rounded-lg py-1 mt-4"
              phx-click="delete_message"
              phx-value-message-id={msg.id}
            >
              Delete
            </button>
            <button
              class="bg-gray-600 text-white rounded-lg py-1 mt-4"
              phx-click="ignore_flag"
              phx-value-message-id={msg.id}
            >
              Ignore
            </button>
          </div>
        </li>
      </ul>
    </div>
    """
  end

  @impl true
  def mount(_params, session, socket) do
    if connected?(socket) do
      subscribe()
    end

    {:ok, timestamp} = DateTime.now("Etc/UTC")

    socket =
      socket
      |> assign(:messages, [
        %{
          author: "Jan",
          body: "Hello, world",
          id: "Jan:Hello, world",
          timestamp: timestamp,
          flagged: true
        },
        %{
          author: "Zbigniew",
          body: "Hello, world",
          id: "Zbigniew:Hello, world",
          timestamp: timestamp,
          flagged: false
        }
      ])
      |> assign(msg_body: nil, author: nil, next_msg_id: 0)
      |> assign(role: session["role"])
      |> assign(current_tab: "chat")

    {:ok, socket}
  end

  @impl true
  def handle_info({:new_msg, msg}, socket) do
    {:noreply, assign(socket, :messages, [msg])}
  end

  @impl true
  def handle_info({:msg_flagged, flagged_message_id}, socket) do
    messages =
      socket.assigns.messages
      |> Enum.map(fn message ->
        if message.id == flagged_message_id do
          Map.put(message, :flagged, !message.flagged)
        else
          message
        end
      end)

    socket =
      socket
      |> assign(:messages, messages)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:delete_msg, messageId}, socket) do
    messages =
      socket.assigns.messages
      |> Enum.filter(fn message -> message.id != messageId end)

    socket =
      socket
      |> assign(:messages, messages)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:ignore_flag, messageId}, socket) do
    messages =
      socket.assigns.messages
      |> Enum.map(fn message ->
        if message.id == messageId do
          Map.put(message, :flagged, false)
        else
          message
        end
      end)

    socket =
      socket
      |> assign(:messages, messages)

    {:noreply, socket}
  end

  def handle_event("select-tab", %{"tab" => tab}, socket) do
    socket = assign(socket, :current_tab, tab)

    {:noreply, socket}
  end

  def handle_event("delete_message", %{"message-id" => messageId}, socket) do
    Phoenix.PubSub.broadcast(Sludge.PubSub, "chatroom", {:delete_msg, messageId})

    {:noreply, socket}
  end

  def handle_event("ignore_flag", %{"message-id" => messageId}, socket) do
    Phoenix.PubSub.broadcast(Sludge.PubSub, "chatroom", {:ignore_flag, messageId})

    {:noreply, socket}
  end

  @impl true
  def handle_event("validate-form", %{"author" => _author}, socket) do
    {:noreply, socket}
  end

  def handle_event("validate-form", %{"body" => body}, socket) do
    {:noreply, assign(socket, msg_body: body)}
  end

  def handle_event("submit-form", %{"body" => body}, socket) do
    if body != "" do
      id = socket.assigns.next_msg_id
      send_message(body, socket.assigns.author, id)
      {:noreply, assign(socket, msg_body: nil, next_msg_id: id + 1)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("submit-form", %{"author" => author}, socket) do
    author =
      case author do
        "" -> nil
        n -> n
      end

    {:noreply, assign(socket, author: author)}
  end

  def handle_event("flag-message", %{"message-id" => flagged_message_id}, socket) do
    Phoenix.PubSub.broadcast(Sludge.PubSub, "chatroom", {:msg_flagged, flagged_message_id})

    {:noreply, socket}
  end

  defp subscribe() do
    Phoenix.PubSub.subscribe(Sludge.PubSub, "chatroom")
  end

  defp send_message(body, author, id) do
    {:ok, timestamp} = DateTime.now("Etc/UTC")

    msg = %{
      author: author,
      body: body,
      id: "#{author}:#{id}",
      timestamp: timestamp,
      flagged: false
    }

    Phoenix.PubSub.broadcast(Sludge.PubSub, "chatroom", {:new_msg, msg})
  end
end
