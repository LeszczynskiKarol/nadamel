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
│   │   ├── Header.astro (Z DROPDOWN MENU!)
│   │   ├── Footer.astro
│   │   ├── Hero.astro
│   │   ├── ServiceCard.astro
│   │   ├── CTAButton.astro
│   │   ├── ServicesSection.astro
│   │   ├── BenefitsSection.astro
│   │   └── ContactSection.astro
│   ├── layouts/         # Layouty
│   │   └── Layout.astro
│   ├── pages/           # Strony (8 TOTAL!)
│   │   ├── index.astro
│   │   ├── drzwi-wewnetrzne.astro
│   │   ├── fronty-meblowe.astro
│   │   ├── lakierowanie.astro
│   │   ├── oklejanie-plyt-meblowych.astro (NOWA!)
│   │   ├── ciecie-rozkroj-plyt.astro (NOWA!)
│   │   ├── plyty-meblowe.astro (NOWA!)
│   │   └── oklejanie-mebli.astro (NOWA!)
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
- ✅ JSON-LD structured data (rozbudowane z OfferCatalog)
- ✅ Canonical URLs
- ✅ Sitemap automatyczny
- ✅ Robots.txt

### Performance

- ✅ Statyczna generacja stron (SSG)
- ✅ Optymalizowane CSS
- ✅ Minimalizacja HTML
- ✅ Fast by default z Astro

### Design

- ✅ Responsywny design (mobile-first)
- ✅ Nowoczesny UI z Tailwind
- ✅ NOWA kolorystyka (niebieski + szary)
- ✅ Animacje i przejścia
- ✅ Accessibility (WCAG)
- ✅ **DROPDOWN MEGA MENU** w Header

### Strony

- ✅ 8 kompletnych podstron
- ✅ 4 NOWE podstrony usług
- ✅ Bogata treść SEO
- ✅ FAQ na stronie głównej

### Komponenty

- ✅ Reużywalne komponenty
- ✅ Header z mega menu dropdown
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
