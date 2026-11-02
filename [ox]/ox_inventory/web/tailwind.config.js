module.exports = {
  content: ['./src/**/*.{html,js,tsx,ts}'],
  theme: {
    extend: {
      borderWidth: {
        DEFAULT: '0.0625rem',
        0: '0',
        2: '0.125rem',
        4: '0.25rem',
        8: '0.5rem',
      },
      outlineWidth: {
        0: '0',
        1: '0.0625rem',
        2: '0.125rem',
        4: '0.25rem',
      },
      ringWidth: {
        DEFAULT: '0.1875rem',
        0: '0',
        1: '0.0625rem',
        2: '0.125rem',
        4: '0.25rem',
        8: '0.5rem',
      },
    },
  },
  plugins: [],
};
