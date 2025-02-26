/**
 * @type {import("phoenix_live_view").ViewHookInterface}
 */
export default {
  mounted() {
    this.el.scrollTo(0, this.el.scrollHeight);
  },
};
