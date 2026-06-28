![GitHub License](https://img.shields.io/github/license/username/repo)
![GitHub Stars](https://img.shields.io/github/stars/username/repo)
![Language](https://img.shields.io/badge/Language-Luau-blue)
![Version](https://img.shields.io/badge/Version-v34.1-red)

---

## 🚀 O Projekcie
**Xeno Suite** to najbardziej zaawansowana, modułowa platforma automatyzacji dla Roblox, napisana w całości w języku Luau. W odróżnieniu od prostych skryptów, Xeno Suite oferuje architekturę klasy produkcyjnej, izolującą moduły w osobnych wątkach, co pozwala na płynną rozgrywkę nawet przy włączonych wszystkich funkcjach.

---

## 🧠 Zaawansowane Technologie

### 🎯 HitChance Engine & Prediction
System `HitChance` w Xeno Suite wykracza poza standardowe algorytmy. 
*   **Raycasting:** Przeprowadza zaawansowane testy widoczności w czasie rzeczywistym, sprawdzając punkty wokół hitboksa, aby wyeliminować "ślepe strzały".
*   **Adaptive Prediction:** Oblicza punkt trafienia nie tylko na podstawie prędkości celu, ale także uwzględnia grawitację Roblox, czas lotu pocisku i ping użytkownika.
*   **DebugMode:** Dla najbardziej wymagających, udostępniamy okno debugowania w czasie rzeczywistym, pokazujące finalny wynik trafienia, dystans, prędkość i ping.

### 🛡️ HvH (Hack vs. Hack) Mastery
Xeno Suite to nie tylko aimbot – to kompletny zestaw narzędzi do dominacji w trudnych warunkach:
*   **Auto-Peek:** Skrypt automatycznie wykrywa dogodną pozycję za osłoną, wychyla się w odpowiednim momencie, oddaje strzał i błyskawicznie wraca do bezpiecznej strefy.
*   **Fake Lag & Jitter:** Nasz silnik manipuluje CFrame Twojej postaci, sprawiając, że dla serwera (i przeciwników) stajesz się trudnym celem, zachowując przy tym pełną płynność ruchu po Twojej stronie.

---

## 📋 Szczegółowy Przegląd Modułów

### ESP & Visuals
*   **High-Performance ESP:** Wykorzystuje `Highlight` API dla minimalnego narzutu na procesor.
*   **Bullet Tracers:** Profesjonalna wizualizacja trajektorii strzałów z konfigurowalnym kolorem i czasem życia (Duration).
*   **World Enhancements:** Pełna kontrola nad oświetleniem (Contrast, Brightness, Saturation) – pozwala na lepszą widoczność graczy w ciemnych lokacjach.

### Combat & Weapon Mods
*   **NoSpread/NoRecoil:** Dynamicznie przeszukuje drzewo obiektów broni (Tool) i zeruje wartości odpowiedzialne za rozrzut i odrzut.
*   **Auto-Scope Manager:** Automatyzuje proces celowania przez lunetę (RMB), z opcjami takimi jak `WaitUntilFullyScoped` dla precyzyjnych strzałów snajperskich.

---

## 📥 Instalacja i Wymagania

### Wymagania:
*   **Executor:** Wymagany executor wspierający funkcje `gethui`, `writefile`, `readfile`, `delfile` oraz `listfiles`.
*   **Środowisko:** Windows 11 (zalecane z użyciem Winaero Tweaker dla lepszej wydajności systemu).

### Loader:
```lua
-- Xeno Suite Loader - Wklej do konsoli executora
loadstring(game:HttpGet("[https://raw.githubusercontent.com/TWOJA_NAZWA_USERA/TWOJE_REPO/main/loader.lua](https://raw.githubusercontent.com/TWOJA_NAZWA_USERA/TWOJE_REPO/main/loader.lua)"))()
