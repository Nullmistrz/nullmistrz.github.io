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
