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
    <div class="flex flex-col justify-between border border-indigo-200 rounded-lg h-full dark:border-zinc-800">
      <ul
        class="w-[448px] h-[0px] overflow-y-scroll flex-grow flex flex-col gap-6 p-6"
        phx-hook="ScrollDownHook"
        id="message_box"
        phx-update="stream"
      >
        <li :for={{id, msg} <- @streams.messages} id={id} class="flex flex-col gap-1">
          <p class="text-indigo-800 text-[13px] text-medium dark:text-indigo-400">
            {msg.author}
          </p>
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
        <textarea
          class="border border-indigo-200 rounded-lg resize-none h-[128px] text-[13px] dark:text-neutral-400 dark:bg-zinc-800 dark:border-none"
          placeholder="Your message"
          maxlength="500"
          name="body"
          value={@msg_body}
          disabled={is_nil(@author)}
        />
        <div class="flex gap-2">
          <input
            class="flex-grow border border-indigo-200 rounded-lg px-4 text-[13px] dark:text-neutral-400 dark:bg-zinc-800 dark:border-none"
            placeholder="Your nickname"
            maxlength="25"
            name="author"
            value={@author}
            disabled={not is_nil(@author)}
          />
          <button
            type="submit"
            class="bg-indigo-800 text-white px-12 py-2 rounded-lg text-[13px] font-medium"
          >
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
    msg = %{author: author, body: body, id: "#{author}:#{id}"}
    Phoenix.PubSub.broadcast(Sludge.PubSub, "chatroom", {:new_msg, msg})
  end
end
