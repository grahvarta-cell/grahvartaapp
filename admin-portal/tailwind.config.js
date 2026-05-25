/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,jsx}'],
  theme: {
    extend: {
      colors: {
        background: '#0D0D0D',
        surface: '#1A1A1A',
        'surface-light': '#222222',
        card: '#1E1E1E',
        orange: {
          DEFAULT: '#E8762A',
          light: '#F08C3E',
          dark: '#B85C1A',
        },
        gold: '#D4A843',
        'text-primary': '#FFFFFF',
        'text-secondary': '#AAAAAA',
        'text-muted': '#666666',
        border: '#2A2A2A',
        divider: '#1F1F1F',
        error: '#E53935',
        success: '#43A047',
      },
      fontFamily: {
        sans: ['Inter', 'sans-serif'],
      },
      borderRadius: {
        xl: '12px',
        '2xl': '16px',
      },
    },
  },
  plugins: [],
};
