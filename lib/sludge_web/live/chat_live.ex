defmodule SludgeWeb.ChatLive do
  use SludgeWeb, :live_view

  attr(:socket, Phoenix.LiveView.Socket, required: true, doc: "Parent live view socket")
  attr(:id, :string, required: true, doc: "Component id")

  def live_render(assigns) do
    ~H"""
    {live_render(@socket, __MODULE__, id: @id)}
    """
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="sludge-container-primary h-full justify-between">
      <ul
        class="w-[440px] h-[0px] overflow-y-auto flex-grow flex flex-col"
        phx-hook="ScrollDownHook"
        id="message_box"
        phx-update="stream"
      >
        <li
          :for={msg <- @messages}
          id={msg.id}
          class={[
            "flex flex-col gap-1 px-6 py-4 hover:bg-stone-100 first:rounded-t-lg relative",
            msg.flagged && "bg-red-100 hover:bg-red-200"
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
              "absolute right-6 bottom-2 rounded-full hover:bg-stone-200 flex items-center justify-center p-2",
              msg.flagged && "hover:bg-red-300"
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

  @impl true
  def mount(_params, _session, socket) do
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
          flagged: false
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
