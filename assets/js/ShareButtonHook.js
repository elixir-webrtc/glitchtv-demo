/**
 * @type {import("phoenix_live_view").ViewHookInterface}
 */
export default {
  mounted() {
    this.el.addEventListener("click", async () => {
      await navigator.clipboard.writeText(window.location.href);

      const previous = this.el.innerHTML;
      this.el.innerHTML = "Copied!";

      setTimeout(() => (this.el.innerHTML = previous), 2000);
    });
  },
};
