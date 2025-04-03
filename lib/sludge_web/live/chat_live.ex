defmodule SludgeWeb.ChatLive do
  use Phoenix.LiveView

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
        class="h-[256px] overflow-y-scroll flex-grow flex flex-col gap-6 p-6"
        phx-hook="ScrollDownHook"
        id="message_box"
        phx-update="stream"
      >
        <li :for={{id, msg} <- @streams.messages} id={id} class="flex flex-col gap-1">
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
        class="border-t border-indigo-200 p-6 dark:border-zinc-800"
      >
        <textarea
          class="sludge-input-primary resize-none h-[96px] w-full dark:text-neutral-400"
          placeholder="Your message"
          maxlength="500"
          name="body"
          value={@msg_body}
          disabled={is_nil(@author)}
        />
        <div class="flex flex-col sm:flex-row gap-2">
          <input
            class="sludge-input-primary px-4 py-2 dark:text-neutral-400"
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

    socket =
      socket
      |> stream(:messages, [])
      |> assign(msg_body: nil, author: nil, next_msg_id: 0)

    {:ok, socket}
  end

  @impl true
  def handle_info({:new_msg, msg}, socket) do
    {:noreply, stream(socket, :messages, [msg])}
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
