import { serve } from "bun";
import index from "./index.html";

// Servidor de desarrollo: sirve la UI en el navegador con datos mock (ver lib/mock.ts)
const server = serve({
  routes: {
    "/*": index,
  },
  development: process.env.NODE_ENV !== "production" && {
    hmr: true,
    console: true,
  },
});

console.log(`Crews UI dev server: ${server.url}  (admin: ${server.url}?view=admin)`);
