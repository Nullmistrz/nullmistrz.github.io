---
layout: single
title: "Chateau LTE18 ax - Data Counting for LTE Interface"
locale: en-US
date: 2025-08-06
last_modified_at: 2025-08-17 10:40:00 +0200
categories: posts
translation_id: post-mikrotik-zliczanie-danych-lte1-2025-08-06
---

## 1. LTE Daily Data Aggregation Script for MikroTik

### 1.1 Purpose and Application

This is a custom script for MikroTik routers that enables precise daily monitoring of data usage on the LTE interface. The script is intended for periodic execution (e.g., every 15/30/60 minutes via Scheduler) and allows you to sum up the amount of downloaded (download) and uploaded (upload) data during the day. This makes it easy to control operator-imposed data limits or simply monitor your own usage.

The script was tested on the following MikroTik router:

| Model                      | RouterOS Version | Test Status |
|----------------------------|------------------|-------------|
| S53UG+5HaxD2HaxD&EG18-EA   | 7.19.1           | OK          |
| S53UG+5HaxD2HaxD&EG18-EA   | 7.19.4           | In progress |

This table will be updated with new RouterOS versions and device models as further tests are performed.

### 1.2 How It Works

#### 1.2.1 LTE Interface Selection
At the beginning of the script, the name of the LTE interface from which statistics will be collected is defined (default: `lte1`).

#### 1.2.2 Reading Current Counters
The script reads the current values of bytes received (`rx-byte`) and sent (`tx-byte`) from the selected interface.

#### 1.2.3 Handling Global Variables
Global variables are used to store the daily sum and the last counter values:

- `rxPrevAgg`, `txPrevAgg` – last readings of RX/TX counters
- `globalDownload`, `globalUpload` – total transfer since the beginning of the day

If the variables do not exist (e.g., after a router restart), they are initialized with appropriate values.

#### 1.2.4 Calculating Data Increment
The script calculates the difference between the current and previous counter readings. If the counter "rolls over" or the router is restarted, the increment is set to the current counter value.

#### 1.2.5 Summing Data
The calculated increment is added to the daily sum (`globalDownload` and `globalUpload`).

#### 1.2.6 Updating Variables
At the end, the script updates the global variables so that the previous state of the counters is known for the next execution.

#### 1.2.7 Logging
After each aggregation, a log entry is created with information about the increment and the daily sum (in MB).

### 1.3 Example Script
```shell
# Script: LTE Data Aggregation on MikroTik
# Author: Mirosław Biernat
# Created: 2025-08-05
# Last Modified: 2025-08-05
#
# Description:
# Script executed every 15 minutes. On each run, it aggregates the increment of download (RX) and upload (TX) data into the global variables globalDownload and globalUpload. Allows for daily data summing.
#
# Version history:
# - 1.0 (2025-08-05): First production version, RX/TX aggregation into global variables, logging increments and daily sum.
#
# Variable descriptions:
# - rxPrevAgg, txPrevAgg – last RX/TX counter values for comparison on next run
# - globalDownload, globalUpload – total download/upload since the beginning of the day (in bytes)
# - deltaRX, deltaTX – increment since last run (in bytes)
# - iface – LTE interface name
#
# Logs provide information about the increment and daily sum after each aggregation.

:local iface "lte1"

# Get current RX/TX counters (in bytes)
:local rxNow [/interface get $iface rx-byte]
:local txNow [/interface get $iface tx-byte]

# Get previous values from global variables (if they exist)
:global rxPrevAgg
:global txPrevAgg
:global globalDownload
:global globalUpload

# Initialize global variables if they do not exist
if ([:typeof $rxPrevAgg] != "num") do={ :set rxPrevAgg $rxNow }
if ([:typeof $txPrevAgg] != "num") do={ :set txPrevAgg $txNow }
if ([:typeof $globalDownload] != "num") do={ :set globalDownload 0 }
if ([:typeof $globalUpload] != "num") do={ :set globalUpload 0 }

# Calculate increment since last run
:local deltaRX ($rxNow - $rxPrevAgg)
:local deltaTX ($txNow - $txPrevAgg)
if ($deltaRX < 0) do={ :set deltaRX $rxNow }
if ($deltaTX < 0) do={ :set deltaTX $txNow }

# Add increment to daily sum
:set globalDownload ($globalDownload + $deltaRX)
:set globalUpload ($globalUpload + $deltaTX)

# Update global variables for next run
:set rxPrevAgg $rxNow
:set txPrevAgg $txNow

# Log aggregation
:log info ("[AGGREGATION] Added to sum: RX: " . ($deltaRX / 1048576) . " MB, TX: " . ($deltaTX / 1048576) . " MB. Daily sum RX: " . ($globalDownload / 1048576) . " MB, TX: " . ($globalUpload / 1048576) . " MB")
```
**Download ready-to-use script file:** [lte_day_usage_monitor_AGG.rsc](/assets/scripts/lte_day_usage_monitor_AGG.rsc)

---
# Script Cooperation

In my case, the first script (aggregation) runs every 59 min 59 sec, and the second – summary – once a day at 23:59:00. This provides full, automatic monitoring and daily LTE data reporting.

---

## 2. LTE Daily Data Summary Script for MikroTik – How It Works

### 2.1 Purpose and Application
This script is used to automatically summarize the daily data usage on the LTE interface of a MikroTik router. It is run once a day, preferably just before midnight (e.g., at 23:59), to collect and archive the total values of downloaded and uploaded data for the entire day. This allows for easy daily monitoring and receiving e-mail reports.

### 2.2 Step-by-step Operation
- The script reads the total download and upload values from global variables (`globalDownload`, `globalUpload`), which were aggregated by another script running cyclically during the day.
- Converts byte values to megabytes (MB) for report readability.
- Logs daily data usage (download and upload) in the system.
- Prepares an e-mail message with a daily data summary, including the date and the amount of downloaded and uploaded data.
- Sends an e-mail to the specified address (can be changed in the `emailTo` variable).
- Resets the global variables `globalDownload` and `globalUpload` to zero to start summing data for the next day.
- Logs information about the variable reset.

### 2.3 Purpose and Benefits
The script is a perfect complement to daily LTE data aggregation on MikroTik. It allows for automatic reporting and archiving of data usage, which is especially useful for limited packages or when data usage needs to be accounted for. Thanks to the automatic variable reset, it requires no manual operation and works fully autonomously.

### 2.4 Implementation Tips
- The script should be run once a day, preferably via Scheduler in the evening.
- The recipient e-mail address can be freely changed in the `emailTo` variable.
- The script requires prior operation of the aggregation script (e.g., [`lte_day_usage_monitor_AGG.rsc`](/assets/scripts/lte_day_usage_monitor_AGG.rsc)), which sums the data during the day.

---

### 2.5 Daily Data Summary Script Code
```shell
# Script: LTE Daily Data Summary on MikroTik
# Author: Mirosław Biernat
# Created: 2025-08-05
# Last Modified: 2025-08-05
#
# Description:
# Script run between 23:54–23:59. Reads the total download/upload from global variables globalDownload/globalUpload, logs the summary, sends an e-mail, and resets the variables to zero for the next day.
#
# Version history:
# - 1.0 (2025-08-05): First production version, daily transfer summary and reset, e-mail sending.
#
# Variable descriptions:
# - globalDownload, globalUpload – total download/upload since the beginning of the day (in bytes)
# - dailyDownloadMB, dailyUploadMB – total transfer in MB
# - emailTo, emailSubject, emailBody – e-mail sending parameters
#
# Logs provide information about the summary and variable reset.

# Get daily sums from aggregation
:global globalDownload
:global globalUpload

# Convert to MB
:local dailyDownloadMB ($globalDownload / 1048576)
:local dailyUploadMB ($globalUpload / 1048576)

# Log summary
:log info ("[SUMMARY] Daily data usage: Download: " . $dailyDownloadMB . " MB, Upload: " . $dailyUploadMB . " MB")

# Send e-mail with summary
:local emailTo "youremail@mail.com"
:local emailSubject ("LTE1 Daily Summary - " . [/system clock get date])
:local emailBody ("Daily data usage:\r\nDownload: " . $dailyDownloadMB . " MB\r\nUpload: " . $dailyUploadMB . " MB")
/tool e-mail send to=$emailTo subject=$emailSubject body=$emailBody

# Reset global variables for the next day
:set globalDownload 0
:set globalUpload 0

# Log reset
:log info "[SUMMARY] globalDownload and globalUpload global variables reset to 0."
```
**Download ready-to-use script file:** [lte_day_summary.rsc](/assets/scripts/lte_day_summary.rsc)