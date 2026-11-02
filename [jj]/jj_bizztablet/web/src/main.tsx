import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { createTheme, MantineProvider } from '@mantine/core';
import { Notifications } from '@mantine/notifications';
import '@mantine/core/styles.css';
import '@mantine/notifications/styles.css';
import './global.css';
import { App } from './App';

const theme = createTheme({
  primaryColor: 'grape',
  fontFamily: '"Open Sans", sans-serif',
  headings: { fontFamily: '"Fjalla One", sans-serif', fontWeight: '400' },
  defaultRadius: 'md',
});

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <MantineProvider defaultColorScheme="dark" theme={theme}>
      <Notifications position="top-center" zIndex={500} />
      <App />
    </MantineProvider>
  </StrictMode>,
);
