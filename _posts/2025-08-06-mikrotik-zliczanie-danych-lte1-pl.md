---
layout: single
title: "Chateau LTE18 ax - Zliczanie danych dla interfejsu LTE"
locale: pl-PL
date: 2025-08-06
last_modified_at: 2025-08-06 14:14:00 +0200
categories: posts
translation_id: post-mikrotik-zliczanie-danych-lte1-2025-08-06
---

# Skrypt do dziennej agregacji transferu LTE na MikroTik

## Cel i zastosowanie

Przedstawiam autorski skrypt do routerów MikroTik, który umożliwia precyzyjne monitorowanie dziennego zużycia transferu danych na interfejsie LTE. Skrypt jest przeznaczony do uruchamiania cyklicznego (np. co 15 minut przez Scheduler) i pozwala na sumowanie ilości pobranych (download) oraz wysłanych (upload) danych w ciągu doby. Dzięki temu można łatwo kontrolować limity transferu narzucone przez operatora lub po prostu monitorować własne zużycie.

## Zasada działania

### Wybór interfejsu LTE
Na początku skryptu definiowana jest nazwa interfejsu LTE, z którego będą pobierane statystyki (domyślnie `lte1`).

### Pobranie aktualnych liczników
Skrypt odczytuje bieżące wartości liczników bajtów pobranych (`rx-byte`) i wysłanych (`tx-byte`) z wybranego interfejsu.

### Obsługa zmiennych globalnych
Do przechowywania sumy dziennej oraz ostatnich wartości liczników wykorzystywane są zmienne globalne:

- `rxPrevAgg`, `txPrevAgg` – ostatnie odczyty liczników RX/TX
- `globalDownload`, `globalUpload` – sumaryczny transfer od początku dnia

Jeśli zmienne nie istnieją (np. po restarcie routera), są inicjalizowane odpowiednimi wartościami.

### Obliczanie przyrostu transferu
Skrypt wylicza różnicę pomiędzy aktualnym a poprzednim odczytem liczników. Jeśli licznik się „przewinie” lub router zostanie zrestartowany, przyrost jest ustawiany na aktualną wartość licznika.

### Sumowanie transferu
Obliczony przyrost jest dodawany do sumy dziennej (`globalDownload` i `globalUpload`).

### Aktualizacja zmiennych
Na koniec skrypt aktualizuje zmienne globalne, aby przy kolejnym wywołaniu znać poprzedni stan liczników.

### Logowanie
Po każdej agregacji do logów systemowych trafia informacja o przyroście transferu oraz sumie dziennej (w MB).

## Przykładowy kod
```shell
# Skrypt: Agregacja transferu LTE MikroTik
# Autor: Mirosław Biernat
# Data utworzenia: 2025-08-05
# Data ostatniej modyfikacji: 2025-08-05
#
# Opis:
# Skrypt uruchamiany co 15 minut. Przy każdym wywołaniu agreguje przyrost transferu download (RX) i upload (TX) do zmiennych globalnych globalDownload i globalUpload. Pozwala na sumowanie transferu w ciągu dnia.
#
# Historia wersji:
# - 1.0 (2025-08-05): Pierwsza wersja produkcyjna, agregacja RX/TX do zmiennych globalnych, logowanie przyrostów i sumy dziennej.
#
# Opis zmiennych:
# - rxPrevAgg, txPrevAgg – ostatnie wartości liczników RX/TX do porównania przy kolejnym wywołaniu
# - globalDownload, globalUpload – sumaryczny transfer download/upload od początku dnia (w bajtach)
# - deltaRX, deltaTX – przyrost transferu od ostatniego wywołania (w bajtach)
# - iface – nazwa interfejsu LTE
#
# Logi informują o przyroście i sumie dziennej po każdej agregacji.

:local iface "lte1"

# Pobierz aktualne liczniki RX/TX (w bajtach)
:local rxNow [/interface get $iface rx-byte]
:local txNow [/interface get $iface tx-byte]

# Pobierz poprzednie wartości z globalnych zmiennych (jeśli istnieją)
:global rxPrevAgg
:global txPrevAgg
:global globalDownload
:global globalUpload

# Inicjalizacja zmiennych globalnych, jeśli nie istnieją
if ([:typeof $rxPrevAgg] != "num") do={ :set rxPrevAgg $rxNow }
if ([:typeof $txPrevAgg] != "num") do={ :set txPrevAgg $txNow }
if ([:typeof $globalDownload] != "num") do={ :set globalDownload 0 }
if ([:typeof $globalUpload] != "num") do={ :set globalUpload 0 }

# Oblicz przyrost transferu od ostatniego wywołania
:local deltaRX ($rxNow - $rxPrevAgg)
:local deltaTX ($txNow - $txPrevAgg)
if ($deltaRX < 0) do={ :set deltaRX $rxNow }
if ($deltaTX < 0) do={ :set deltaTX $txNow }

# Dodaj przyrost do sumy dziennej
:set globalDownload ($globalDownload + $deltaRX)
:set globalUpload ($globalUpload + $deltaTX)

# Zaktualizuj zmienne globalne do kolejnego wywołania
:set rxPrevAgg $rxNow
:set txPrevAgg $txNow

# Loguj agregację
:log info ("[AGGREGACJA] Dodano do sumy: RX: " . ($deltaRX / 1048576) . " MB, TX: " . ($deltaTX / 1048576) . " MB. Suma dzienna RX: " . ($globalDownload / 1048576) . " MB, TX: " . ($globalUpload / 1048576) . " MB")
```
