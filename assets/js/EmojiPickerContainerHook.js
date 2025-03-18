/**
 * @type {import("phoenix_live_view").ViewHookInterface}
 */
export default {
  mounted() {
    const emojiPicker = document.querySelector("emoji-picker");

    emojiPicker.addEventListener("emoji-click", (event) => {
      this.pushEvent("append_emoji", { emoji: event.detail.unicode });
    });
  },
};
