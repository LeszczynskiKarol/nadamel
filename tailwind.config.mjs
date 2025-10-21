/** @type {import('tailwindcss').Config} */
export default {
  content: ['./src/**/*.{astro,html,js,jsx,md,mdx,svelte,ts,tsx,vue}'],
  theme: {
    extend: {
      colors: {
        primary: {
          50: '#fef5ee',
          100: '#fde8d7',
          200: '#facead',
          300: '#f7ab79',
          400: '#f37e43',
          500: '#f05d1f',
          600: '#e14215',
          700: '#bb2f13',
          800: '#952717',
          900: '#792316',
          950: '#410e09',
        },
        wood: {
          50: '#faf8f3',
          100: '#f3ede1',
          200: '#e6dac1',
          300: '#d5c19a',
          400: '#c4a474',
          500: '#b88d59',
          600: '#aa7a4e',
          700: '#8d6242',
          800: '#74513a',
          900: '#5e4432',
          950: '#32231a',
        }
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
        display: ['Poppins', 'system-ui', 'sans-serif'],
      },
    },
  },
  plugins: [],
}
