import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { MantineProvider } from '@mantine/core';
import '@mantine/core/styles.css';
import '@mantine/dates/styles.css';
import './global.css';
import { App } from './App';
import { isBrowser } from './lib/nui';

const root = document.getElementById('root')!;

// Fondo de ejemplo para trabajar en el navegador, donde no está el juego detrás
if (isBrowser()) {
  root.style.backgroundImage = 'url("https://i.imgur.com/3pzRj9n.png")';
  root.style.backgroundSize = 'cover';
  root.style.backgroundRepeat = 'no-repeat';
  root.style.backgroundPosition = 'center';
}

createRoot(root).render(
  <StrictMode>
    <MantineProvider defaultColorScheme="dark">
      <App />
    </MantineProvider>
  </StrictMode>,
);
