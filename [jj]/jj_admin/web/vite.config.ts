import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  // FiveM sirve la interfaz desde nui://, así que las rutas tienen que ser relativas
  base: './',
  build: {
    outDir: 'dist',
    emptyOutDir: true,
  },
});
