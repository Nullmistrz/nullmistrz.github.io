---
layout: single
title: "Chateau LTE18 ax - Zliczanie danych dla interfejsu LTE"
locale: pl-PL
date: 2025-08-06
last_modified_at: 2025-08-17 10:40:00 +0200
categories: posts
translation_id: post-mikrotik-zliczanie-danych-lte1-2025-08-06
---

## 1. Skrypt do dziennej agregacji transferu LTE na MikroTik

### 1.1 Cel i zastosowanie

Przedstawiam autorski skrypt do routerów MikroTik, który umożliwia precyzyjne monitorowanie dziennego zużycia transferu danych na interfejsie LTE. Skrypt jest przeznaczony do uruchamiania cyklicznego (np. co 15/30/60 minut przez Scheduler) i pozwala na sumowanie ilości pobranych (download) oraz wysłanych (upload) danych w ciągu doby. Dzięki temu można łatwo kontrolować limity transferu narzucone przez operatora lub po prostu monitorować własne zużycie.

Skrypt był testowany na routerze MikroTik:

| Model                      | Wersja RouterOS | Status testu |
|----------------------------|-----------------|--------------|
| S53UG+5HaxD2HaxD&EG18-EA   | 7.19.1          | OK           |
| S53UG+5HaxD2HaxD&EG18-EA   | 7.19.4          | W trakcie    |

Tabelka będzie aktualizowana o kolejne wersje systemu RouterOS oraz modele urządzeń.


### 1.2 Zasada działania

### 1.2.1 Wybór interfejsu LTE
Na początku skryptu definiowana jest nazwa interfejsu LTE, z którego będą pobierane statystyki (domyślnie `lte1`).

### 1.2.2 Pobranie aktualnych liczników
Skrypt odczytuje bieżące wartości liczników bajtów pobranych (`rx-byte`) i wysłanych (`tx-byte`) z wybranego interfejsu.

### 1.2.3 Obsługa zmiennych globalnych
Do przechowywania sumy dziennej oraz ostatnich wartości liczników wykorzystywane są zmienne globalne:

- `rxPrevAgg`, `txPrevAgg` – ostatnie odczyty liczników RX/TX
- `globalDownload`, `globalUpload` – sumaryczny transfer od początku dnia

Jeśli zmienne nie istnieją (np. po restarcie routera), są inicjalizowane odpowiednimi wartościami.

### 1.2.4 Obliczanie przyrostu transferu
Skrypt wylicza różnicę pomiędzy aktualnym a poprzednim odczytem liczników. Jeśli licznik się „przewinie” lub router zostanie zrestartowany, przyrost jest ustawiany na aktualną wartość licznika.

### 1.2.5 Sumowanie transferu
Obliczony przyrost jest dodawany do sumy dziennej (`globalDownload` i `globalUpload`).

### 1.2.6 Aktualizacja zmiennych
Na koniec skrypt aktualizuje zmienne globalne, aby przy kolejnym wywołaniu znać poprzedni stan liczników.

### 1.2.7 Logowanie
Po każdej agregacji do logów systemowych trafia informacja o przyroście transferu oraz sumie dziennej (w MB).

### 1.3 Przykładowy kod
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
---
# Współpraca skryptów

W moim przypadku pierwszy skrypt (agregujący) uruchamiany jest co 59 min 59 sek, a drugi – podsumowujący – raz na dobę o 23:59:00. Dzięki temu uzyskuję pełny, automatyczny monitoring i raportowanie dziennego transferu LTE.

---

## 2. Skrypt do podsumowania dziennego transferu LTE na MikroTik – opis działania

### 2.1 Cel i zastosowanie
Skrypt służy do automatycznego podsumowania dziennego zużycia transferu danych na interfejsie LTE routera MikroTik. Jest uruchamiany raz dziennie, najlepiej tuż przed północą (np. o 23:59), aby zebrać i zarchiwizować sumaryczne wartości pobranych (download) i wysłanych (upload) danych z całego dnia. Pozwala to na łatwe monitorowanie dziennego transferu oraz otrzymywanie raportów e-mail.

### 2.2 Zasada działania krok po kroku
- Skrypt odczytuje sumaryczne wartości transferu download i upload z globalnych zmiennych (`globalDownload`, `globalUpload`), które były agregowane przez inny skrypt uruchamiany cyklicznie w ciągu dnia.
- Przelicza wartości bajtów na megabajty (MB) dla czytelności raportu.
- Loguje w systemie informację o dziennym zużyciu danych (download i upload).
- Przygotowuje wiadomość e-mail z podsumowaniem dziennego transferu, zawierającą datę oraz ilość pobranych i wysłanych danych.
- Wysyła e-mail na wskazany adres (można go zmienić w zmiennej `emailTo`).
- Resetuje zmienne globalne `globalDownload` i `globalUpload` do zera, aby rozpocząć sumowanie transferu od nowa w kolejnym dniu.
- Loguje informację o resecie zmiennych.

### 2.3 Przeznaczenie i zalety
Skrypt jest idealnym uzupełnieniem dziennej agregacji transferu LTE na MikroTik. Pozwala na automatyczne raportowanie i archiwizację zużycia danych, co jest szczególnie przydatne przy limitowanych pakietach lub konieczności rozliczania transferu. Dzięki automatycznemu resetowi zmiennych, nie wymaga ręcznej obsługi i działa w pełni autonomicznie.

### 2.4 Wskazówki wdrożeniowe
- Skrypt należy uruchamiać raz dziennie, najlepiej przez Scheduler w godzinach wieczornych.
- Adres e-mail odbiorcy raportu można dowolnie zmienić w zmiennej `emailTo`.
- Skrypt wymaga wcześniejszego działania skryptu agregującego transfer (np. [`lte_day_usage_monitor_AGG.rsc`](/assets/scripts/lte_day_usage_monitor_AGG.rsc)), który sumuje transfer w ciągu dnia.

---

### 2.5 Kod skryptu dobowego podsumowania transferu
```shell
# Skrypt: Podsumowanie dziennego transferu LTE MikroTik
# Autor: Mirosław Biernat
# Data utworzenia: 2025-08-05
# Data ostatniej modyfikacji: 2025-08-05
#
# Opis:
# Skrypt uruchamiany w przedziale 23:54–23:59. Odczytuje sumaryczny transfer download/upload z globalnych zmiennych globalDownload/globalUpload, loguje podsumowanie, wysyła e-mail i resetuje zmienne do zera na kolejny dzień.
#
# Historia wersji:
# - 1.0 (2025-08-05): Pierwsza wersja produkcyjna, podsumowanie i reset dziennych sum transferu, wysyłka e-mail.
#
# Opis zmiennych:
# - globalDownload, globalUpload – sumaryczny transfer download/upload od początku dnia (w bajtach)
# - dailyDownloadMB, dailyUploadMB – sumaryczny transfer w MB
# - emailTo, emailSubject, emailBody – parametry wysyłki e-maila
#
# Logi informują o podsumowaniu i resecie zmiennych.

# Pobierz sumy dzienne z agregacji
:global globalDownload
:global globalUpload

# Przelicz na MB
:local dailyDownloadMB ($globalDownload / 1048576)
:local dailyUploadMB ($globalUpload / 1048576)

# Loguj podsumowanie
:log info ("[PODSUMOWANIE] Dzienne zużycie danych: Download: " . $dailyDownloadMB . " MB, Upload: " . $dailyUploadMB . " MB")

# Wyślij e-mail z podsumowaniem
:local emailTo "twójadresmail@mail.com"
:local emailSubject ("Podsumowanie dzienne LTE1 - " . [/system clock get date])
:local emailBody ("Dzienne zużycie danych:\r\nDownload: " . $dailyDownloadMB . " MB\r\nUpload: " . $dailyUploadMB . " MB")
/tool e-mail send to=$emailTo subject=$emailSubject body=$emailBody

# Resetuj zmienne globalne na kolejny dzień
:set globalDownload 0
:set globalUpload 0

# Loguj reset
:log info "[PODSUMOWANIE] Zresetowano zmienne globalne globalDownload i globalUpload do 0."
```
**Pobierz gotowy plik skryptu:** [lte_day_summary.rsc](/assets/scripts/lte_day_summary.rsc)