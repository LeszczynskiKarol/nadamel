# Nadamel - Strona Usług Stolarskich

Nowoczesna, zoptymalizowana pod SEO strona dla firmy stolarskiej Nadamel.

## 🚀 Technologie

- **Astro** - framework do budowy statycznych stron
- **Tailwind CSS** - utility-first CSS framework
- **TypeScript** - typowanie statyczne

## 📦 Instalacja

```bash
# Instalacja zależności
npm install

# Uruchomienie serwera deweloperskiego
npm run dev

# Budowanie produkcyjne
npm run build

# Preview budowania produkcyjnego
npm run preview
```

## 📁 Struktura projektu

```
/
├── public/              # Pliki statyczne
│   ├── favicon.svg
│   └── robots.txt
├── src/
│   ├── components/      # Komponenty reużywalne
│   │   ├── Header.astro
│   │   ├── Footer.astro
│   │   ├── Hero.astro
│   │   ├── ServiceCard.astro
│   │   ├── CTAButton.astro
│   │   ├── ServicesSection.astro
│   │   ├── BenefitsSection.astro
│   │   └── ContactSection.astro
│   ├── layouts/         # Layouty
│   │   └── Layout.astro
│   ├── pages/           # Strony
│   │   ├── index.astro
│   │   ├── drzwi-wewnetrzne.astro
│   │   ├── fronty-meblowe.astro
│   │   └── lakierowanie.astro
│   └── styles/          # Style globalne
│       └── global.css
├── astro.config.mjs     # Konfiguracja Astro
├── tailwind.config.mjs  # Konfiguracja Tailwind
└── tsconfig.json        # Konfiguracja TypeScript
```

## 🎨 Funkcje

### SEO

- ✅ Meta tagi dla wszystkich stron
- ✅ Open Graph i Twitter Cards
- ✅ JSON-LD structured data
- ✅ Canonical URLs
- ✅ Sitemap automatyczny
- ✅ Robots.txt

### Performance

- ✅ Statyczna generacja stron
- ✅ Optymalizowane CSS
- ✅ Minimalizacja HTML
- ✅ Fast by default z Astro

### Design

- ✅ Responsywny design (mobile-first)
- ✅ Nowoczesny UI z Tailwind
- ✅ Niestandardowa paleta kolorów
- ✅ Animacje i przejścia
- ✅ Accessibility

### Komponenty

- ✅ Reużywalne komponenty
- ✅ Header z mobilnym menu
- ✅ Footer z kontaktem
- ✅ Karty usług
- ✅ Sekcje korzyści
- ✅ Formularz kontaktowy
- ✅ FAQ z akordeonami

## 🔧 Customizacja

### Kolory

Edytuj `tailwind.config.mjs`:

```javascript
colors: {
  primary: { /* kolory główne */ },
  wood: { /* kolory drewna */ }
}
```

### Treść

Wszystkie treści znajdują się w plikach `.astro` w katalogu `src/pages/` i `src/components/`.

### SEO

Edytuj meta tagi w `src/layouts/Layout.astro` oraz JSON-LD structured data.

## 📞 Kontakt

- **Telefon:** 577 708 677
- **Email:** biuro@nadamel.pl
- **Godziny:** Pn-Pt 07:00-17:00

## 📄 Licencja

© 2025 Nadamel. Wszelkie prawa zastrzeżone.
