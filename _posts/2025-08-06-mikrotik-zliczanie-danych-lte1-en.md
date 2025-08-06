---
layout: single
title: "Chateau LTE18 ax - Data Counting for LTE Interface"
locale: en-US
date: 2025-08-06
last_modified_at: 2025-08-06 14:14:00 +0200
categories: posts
translation_id: post-mikrotik-zliczanie-danych-lte1-2025-08-06
---

# Script for Daily LTE Data Aggregation on MikroTik

## Purpose and Application

Here is a custom script for MikroTik routers that enables precise daily monitoring of data usage on the LTE interface. The script is intended for periodic execution (e.g., every 15 minutes via Scheduler) and allows you to sum up the amount of downloaded (download) and uploaded (upload) data during the day. This makes it easy to control operator-imposed data limits or simply monitor your own usage.

## How It Works

### Selecting the LTE Interface
At the beginning of the script, the name of the LTE interface from which statistics will be collected is defined (default is `lte1`).

### Reading Current Counters
The script reads the current values of bytes received (`rx-byte`) and sent (`tx-byte`) from the selected interface.

### Handling Global Variables
Global variables are used to store the daily sum and the last counter values:

- `rxPrevAgg`, `txPrevAgg` – last readings of RX/TX counters
- `globalDownload`, `globalUpload` – total transfer since the beginning of the day

If the variables do not exist (e.g., after a router restart), they are initialized with appropriate values.

### Calculating Data Increment
The script calculates the difference between the current and previous counter readings. If the counter "rolls over" or the router is restarted, the increment is set to the current counter value.

### Summing Data
The calculated increment is added to the daily sum (`globalDownload` and `globalUpload`).

### Updating Variables
At the end, the script updates the global variables so that the previous state of the counters is known for the next execution.

### Logging
After each aggregation, a log entry is created with information about the increment and the daily sum (in MB).

## Example Script
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