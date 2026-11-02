import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { createTheme, MantineProvider } from '@mantine/core';
import '@mantine/core/styles.css';
import './global.css';
import { App } from './App';

const theme = createTheme({
  primaryColor: 'violet',
  primaryShade: 6,
  fontFamily: 'Manrope, sans-serif',
  headings: { fontFamily: 'Manrope, sans-serif' },
  defaultRadius: 'md',
});

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <MantineProvider defaultColorScheme="dark" theme={theme}>
      <App />
    </MantineProvider>
  </StrictMode>,
);
