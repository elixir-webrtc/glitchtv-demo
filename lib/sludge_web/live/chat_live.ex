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
        class="w-[448px] h-[0px] overflow-y-auto flex-grow first:*:rounded-t-lg"
        phx-hook="ScrollDownHook"
        id="message_box"
        phx-update="stream"
      >
        <li :for={{id, msg} <- @streams.messages} id={id} class="flex flex-col gap-1 px-6 py-3">
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
        </li>
      </ul>
      <form
        phx-change="validate-form"
        phx-submit="submit-form"
        class="flex flex-col gap-2 border-t border-indigo-200 p-6 dark:border-zinc-800"
      >
        <div class="flex items-end gap-2 relative">
          <textarea
            name="body"
            class="sludge-input-primary resize-none h-[128px] dark:text-neutral-400"
            placeholder="Your message"
            maxlength="500"
            disabled={is_nil(@author)}
          >{@msg_body}</textarea>
          <button
            type="button"
            class="border border-indigo-200 rounded-lg px-2 py-1"
            phx-click="toggle-emoji-overlay"
          >
            <.icon name="hero-face-smile" />
          </button>

          <div
            class={["absolute bottom-[95%] right-0", !@show_emoji_overlay && "hidden"]}
            id="emoji-picker-container"
            phx-hook="EmojiPickerContainerHook"
          >
            <emoji-picker></emoji-picker>
          </div>
        </div>
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
      |> stream(:messages, [
        %{
          author: "Jan",
          body: "Hello, world",
          id: "Jan:Hello, world",
          timestamp: timestamp
        },
        %{
          author: "Zbigniew",
          body: "Hello, world",
          id: "Zbigniew:Hello, world",
          timestamp: timestamp
        }
      ])
      |> assign(msg_body: nil, author: nil, next_msg_id: 0)
      |> assign(show_emoji_overlay: false)

    {:ok, socket}
  end

  @impl true
  def handle_info({:new_msg, msg}, socket) do
    {:noreply, stream(socket, :messages, [msg])}
  end

  @impl true
  def handle_event("append_emoji", %{"emoji" => emoji}, socket) do
    msg_body =
      if socket.assigns.msg_body != nil do
        socket.assigns.msg_body <> emoji
      else
        emoji
      end

    socket =
      socket
      |> assign(msg_body: msg_body)
      |> assign(show_emoji_overlay: false)

    {:noreply, socket}
  end

  @impl true
  def handle_event("toggle-emoji-overlay", _, socket) do
    socket = assign(socket, :show_emoji_overlay, !socket.assigns.show_emoji_overlay)

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

  defp subscribe() do
    Phoenix.PubSub.subscribe(Sludge.PubSub, "chatroom")
  end

  defp send_message(body, author, id) do
    {:ok, timestamp} = DateTime.now("Etc/UTC")
    msg = %{author: author, body: body, id: "#{author}:#{id}", timestamp: timestamp}
    Phoenix.PubSub.broadcast(Sludge.PubSub, "chatroom", {:new_msg, msg})
  end
end
