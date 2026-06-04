import react from "@vitejs/plugin-react";
import { defineConfig } from "vite";

import { orcaPlugin } from "./server/orcaPlugin.js";

export default defineConfig({
  plugins: [react(), orcaPlugin()],
  server: { port: 5183, open: true },
});
