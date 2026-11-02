import { defineConfig } from 'vite';

export default defineConfig({
  // FiveM sirve la interfaz desde nui://, así que las rutas tienen que ser relativas
  base: './',
  build: {
    outDir: 'dist',
    emptyOutDir: true,
  },
});
