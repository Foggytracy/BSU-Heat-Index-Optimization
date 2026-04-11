# BSU-Heat-Index-Optimization
**Identifying the safest 10-month academic calendar for Bulacan State University.**

## Overview
This project uses a **Sliding Window Optimization** algorithm to find the specific 10-month period with the lowest Heat Index (HI) exposure, helping protect the BSU community from extreme thermal stress.

## Repository Contents
* `HeatIndex_Analytics.m` – The MATLAB script for forecasting and optimization.
* `HI_historical_dataset.csv` – PAGASA-derived HI data (Jan 2023 – March 2026).
* `/figures` – Pre-generated visualizations showing the 24-month forecast and optimal window results.

## How it Works
1. **Forecast:** Uses seasonal averages to project heat trends up to March 2028.
2. **Optimize:** Slides a 10-month "window" across the calendar year.
3. **Select:** Identifies the window with the lowest cumulative heat exposure.

## Usage
* **View Results:** Check the `/figures` folder for the final research charts.
* **Run Script:** Execute `HeatIndex_Analytics.m` in MATLAB to replicate the analysis.

## Authors
* John Lor Ganary Daguyos
* Klaus Gabariel Bernardo
* Miguelito Domingo
* Alliah Francisco
* Rexine Bradley Cortez
