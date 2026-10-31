import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { createTheme, MantineProvider } from '@mantine/core';
import { Notifications } from '@mantine/notifications';
import '@mantine/core/styles.css';
import '@mantine/notifications/styles.css';
import './global.css';
import { App } from './App';

const theme = createTheme({
  primaryColor: 'yellow',
  primaryShade: 5,
  fontFamily: 'Manrope, sans-serif',
  headings: { fontFamily: 'Manrope, sans-serif' },
  defaultRadius: 'md',
});

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <MantineProvider defaultColorScheme="dark" theme={theme}>
      <Notifications position="top-right" zIndex={4000} />
      <App />
    </MantineProvider>
  </StrictMode>,
);
