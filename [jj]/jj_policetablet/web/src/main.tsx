import '@mantine/core/styles.css';
import '@mantine/dates/styles.css';
import '@mantine/tiptap/styles.css';
import './styles/global.css';
import { MantineProvider, createTheme } from '@mantine/core';
import { createRoot } from 'react-dom/client';
import { RecoilRoot } from 'recoil';
import { App } from './App';

// El amarillo de Mantine pasa a morado en toda la tablet
const theme = createTheme({
  colors: {
    yellow: ['#f3f0ff', '#ebe4ff', '#d0bfff', '#b197fc', '#9775fa', '#845ef7', '#7950f2', '#7048e8', '#6741d9', '#5f3dc4'],
  },
});

createRoot(document.getElementById('root')!).render(
  <RecoilRoot>
    <MantineProvider theme={theme} defaultColorScheme="dark">
      <App />
    </MantineProvider>
  </RecoilRoot>,
);
