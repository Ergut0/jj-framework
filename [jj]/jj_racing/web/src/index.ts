import { serve } from "bun";
import index from "./index.html";

// Servidor de desarrollo: sirve la UI en el navegador con datos simulados (ver lib/mock)
//   ?view=admin   abre el panel de administracion
//   ?hud=1        arranca una carrera simulada para ver el HUD
//   ?creator=1    muestra el overlay del editor de circuitos
const server = serve({
  routes: {
    "/*": index,
  },
  development: process.env.NODE_ENV !== "production" && {
    hmr: true,
    console: true,
  },
});

console.log(`Races UI dev server: ${server.url}  (?view=admin | ?hud=1 | ?creator=1)`);
