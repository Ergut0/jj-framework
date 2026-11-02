import { createTheme } from '@mantine/core';

export const theme = createTheme({
  primaryColor: 'yellow',
  colors: {
    // El amarillo original del tema pasa a morado
    yellow: ['#f3f0ff', '#ebe4ff', '#d0bfff', '#b197fc', '#9775fa', '#845ef7', '#7950f2', '#7048e8', '#6741d9', '#5f3dc4'],
    green: [
      '#faf5ff',
      '#e9d5ff',
      '#d8b4fe',
      '#a855f7',
      '#9333ea',
      '#7e22ce',
      '#6b21a8',
      '#581c87',
      '#4c1d95',
      '#3f2206',
    ],
  },
});

