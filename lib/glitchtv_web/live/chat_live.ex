defmodule GlitchtvWeb.ChatLive do
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
    <div class="glitchtv-container-primary h-full justify-between">
      <ul
        class="w-[440px] h-[0px] overflow-y-scroll flex-grow flex flex-col gap-6 p-6"
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
          <p class="dark:text-neutral-400 break-all">
            {msg.body}
          </p>
        </li>
      </ul>
      <form
        phx-change="validate-form"
        phx-submit="submit-form"
        class="flex flex-col gap-2 border-t border-indigo-200 p-6 dark:border-zinc-800"
      >
        <div class="flex flex-col relative">
          <div class={
            (String.length(@msg_body || "") == @max_msg_length &&
               "absolute top-[-18px] right-[2px] text-xs w-full text-right text-rose-600 dark:text-rose-600") ||
              (String.length(@msg_body || "") > @max_msg_length - 50 &&
                 "absolute top-[-18px] right-[2px] text-xs w-full text-right text-neutral-400 dark:text-neutral-700") ||
              "hidden"
          }>
            {String.length(@msg_body || "")}/{@max_msg_length}
          </div>
          <textarea
            class="glitchtv-input-primary resize-none h-[128px] dark:text-neutral-400"
            placeholder="Your message"
            maxlength={@max_msg_length}
            name="body"
            value={@msg_body}
            disabled={not @joined}
          />
        </div>
        <div class="flex gap-2">
          <div class="flex flex-1 relative">
            <input
              class="glitchtv-input-primary px-4 dark:text-neutral-400"
              placeholder="Your nickname"
              maxlength={@max_nickname_length}
              name="author"
              value={@author}
              disabled={@joined}
            />
            <%= if not @joined do %>
              <div class={
                (String.length(@author || "") == @max_nickname_length &&
                   "absolute bottom-[-18px] right-0 text-xs w-full text-rose-600 dark:text-rose-600") ||
                  (String.length(@author || "") > @max_nickname_length - 5 &&
                     "absolute bottom-[-18px] right-0 text-xs w-full text-neutral-400 dark:text-neutral-700") ||
                  "hidden"
              }>
                {String.length(@author || "")}/{@max_nickname_length}
              </div>
            <% end %>
          </div>
          <button
            type="submit"
            class="glitchtv-button-primary"
            disabled={String.length(@author || "") == 0}
          >
            <%= if not @joined do %>
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
      |> assign(max_msg_length: 500, max_nickname_length: 25)
      |> assign(joined: false)

    {:ok, socket}
  end

  @impl true
  def handle_info({:new_msg, msg}, socket) do
    {:noreply, stream(socket, :messages, [msg])}
  end

  @impl true
  def handle_event("validate-form", %{"author" => author}, socket) do
    {:noreply, assign(socket, author: author)}
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

  def handle_event("submit-form", %{"author" => _}, socket) do
    {:noreply, assign(socket, joined: true)}
  end

  defp subscribe() do
    Phoenix.PubSub.subscribe(Glitchtv.PubSub, "chatroom")
  end

  defp send_message(body, author, id) do
    {:ok, timestamp} = DateTime.now("Etc/UTC")
    msg = %{author: author, body: body, id: "#{author}:#{id}", timestamp: timestamp}
    Phoenix.PubSub.broadcast(Glitchtv.PubSub, "chatroom", {:new_msg, msg})
  end
end
