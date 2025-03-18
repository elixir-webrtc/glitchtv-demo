/**
 * @type {import("phoenix_live_view").ViewHookInterface}
 */
export default {
  mounted() {
    const darkModePreference = window.matchMedia(
      "(prefers-color-scheme: dark)"
    );

    if (
      localStorage.getItem("color-theme") === "dark" ||
      (!("color-theme" in localStorage) && darkModePreference.matches)
    ) {
      document.documentElement.classList.add("dark");
      this.el.checked = true;
    } else {
      document.documentElement.classList.remove("dark");
      this.el.checked = false;
    }

    darkModePreference.addEventListener("change", (e) => {
      if (e.matches) {
        document.documentElement.classList.add("dark");
      } else {
        document.documentElement.classList.remove("dark");
      }
    });

    this.el.addEventListener("change", (e) => {
      if (e.target.checked) {
        document.documentElement.classList.add("dark");
        localStorage.setItem("color-theme", "dark");
      } else {
        document.documentElement.classList.remove("dark");
        localStorage.setItem("color-theme", "light");
      }
    });
  },
};
