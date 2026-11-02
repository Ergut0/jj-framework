import '@mantine/core/styles.css';
import './styles/global.css';
import { MantineProvider } from '@mantine/core';
import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { App } from './App';
import { theme } from './theme';
import { isBrowser } from './utils/nui';

const rootElement = document.getElementById('root')!;

// En el navegador se pone un fondo del juego para poder ver la interfaz
if (isBrowser()) {
  rootElement.style.backgroundImage = 'url("https://i.imgur.com/3pzRj9n.png")';
  rootElement.style.backgroundSize = 'cover';
  rootElement.style.backgroundRepeat = 'no-repeat';
  rootElement.style.backgroundPosition = 'center';
}

createRoot(rootElement).render(
  <StrictMode>
    <MantineProvider theme={theme} defaultColorScheme="dark">
      <App />
    </MantineProvider>
  </StrictMode>,
);
