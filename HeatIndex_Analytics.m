clc; clear; close all;

HI_historical = [
    29.1094, 30.6665, 30.1539, 35.2819, 36.2997, 34.9604, ...  % 2023 Jan-Jun
    35.1826, 35.6366, 35.6366, 34.9604, 33.6943, 31.5001, ...  % 2023 Jul-Dec
    30.6665, 30.2788, 32.1855, 35.6165, 37.0061, 37.3851, ...  % 2024 Jan-Jun
    35.4080, 35.4080, 36.1035, 34.9604, 33.8973, 32.0991, ...  % 2024 Jul-Dec
    31.2136, 31.0736, 32.7273, 35.8839, 37.0061, 35.4080, ...  % 2025 Jan-Jun
    33.5731, 35.4080, 33.4007, 35.8685, 35.1826, 31.9461, ...  % 2025 Jul-Dec
    29.1094, 30.4059, 29.7921                                    % 2026 Jan-Mar
];

% Generate month numbers for the 39 months of data
month_nums = [1:12, 1:12, 1:12, 1:3]; 

% STEP 1: SEASONAL AVERAGES (Numerical Approximations)

monthlyHI = zeros(1, 12);
for m = 1:12
    idx = (month_nums == m);
    monthlyHI(m) = mean(HI_historical(idx));
end

month_labels = {'Jan','Feb','Mar','Apr','May','Jun', ...
                'Jul','Aug','Sep','Oct','Nov','Dec'};

% STEP 2: 24-MONTH FORECAST (Apr 2026 - Mar 2028)

numForecast = 24;
start_month = 4;  
HI_forecast = zeros(1, numForecast);
forecast_month_nums = zeros(1, numForecast);

for i = 1:numForecast
    m = mod(start_month + i - 2, 12) + 1;
    HI_forecast(i) = monthlyHI(m);
    forecast_month_nums(i) = m;
end

forecast_labels = {};
yr = 2026; mo = 4;
for i = 1:numForecast
    forecast_labels{i} = sprintf('%s %d', month_labels{mo}, yr);
    mo = mo + 1;
    if mo > 12; mo = 1; yr = yr + 1; end
end

% STEP 3: SLIDING WINDOW OPTIMIZATION

L = 10;
n = numForecast;
window_sums = zeros(1, n - L + 1);
for i = 1:(n - L + 1)
    window_sums(i) = sum(HI_forecast(i:i+L-1));
end

[min_sum, best_start] = min(window_sums);
best_end = best_start + L - 1;
max_sum = max(window_sums);

fprintf('=== OPTIMIZATION RESULTS ===\n');
fprintf('Optimal start: %s\n', forecast_labels{best_start});
fprintf('Optimal end:   %s\n', forecast_labels{best_end});
fprintf('Min cumulative HI: %.4f C\n', min_sum);
fprintf('Max cumulative HI: %.4f C\n', max_sum);

% ERROR ESTIMATION

seasonal_fit = monthlyHI(month_nums);
residuals = HI_historical - seasonal_fit;

mae_per_month = zeros(1, 12);
for m = 1:12
    idx = (month_nums == m);
    mae_per_month(m) = mean(abs(residuals(idx)));
end

% Running minimum
num_windows = n - L + 1;
running_min = zeros(1, num_windows);
improvement_delta = zeros(1, num_windows);
cur_min = inf;
for i = 1:num_windows
    prev = cur_min;
    if window_sums(i) < cur_min
        cur_min = window_sums(i);
    end
    running_min(i) = cur_min;
    improvement_delta(i) = max(0, prev - cur_min);
end
improvement_delta(1) = 0;

hist_labels_short = {};
yr2 = 2023; mo2 = 1;
for i = 1:39
    hist_labels_short{i} = sprintf('%s %d', month_labels{mo2}(1:3), yr2);
    mo2 = mo2 + 1;
    if mo2 > 12; mo2 = 1; yr2 = yr2 + 1; end
end

window_labels = {};
for i = 1:num_windows
    window_labels{i} = sprintf('W%d', i);
end

% Color definitions
teal   = [0.11, 0.62, 0.46];
red    = [0.89, 0.29, 0.29];
blue   = [0.22, 0.53, 0.87];
amber  = [0.94, 0.62, 0.15];
purple = [0.50, 0.47, 0.87];
gray   = [0.70, 0.70, 0.67];
pink   = [0.83, 0.33, 0.49];
green2 = [0.36, 0.60, 0.13];

% FIGURE 1: Seasonal Average HI by Calendar Month

figure(1);
set(gcf, 'Position', [100, 600, 750, 420], 'Name', 'Numerical Approximations');

bar_colors = zeros(12, 3);
for m = 1:12
    if monthlyHI(m) >= 35
        bar_colors(m,:) = red;
    else
        bar_colors(m,:) = blue;
    end
end

b1 = bar(1:12, monthlyHI, 'FaceColor', 'flat');
b1.CData = bar_colors;
b1.EdgeColor = 'none';

hold on;
yline(35, '--', '35°C threshold', ...
    'Color', [0.6 0.2 0.2], 'LineWidth', 1.2, ...
    'LabelHorizontalAlignment', 'right', 'FontSize', 9);

xticks(1:12);
xticklabels(month_labels);
ylabel('Heat Index (°C)', 'FontSize', 11);
xlabel('Month', 'FontSize', 11);
title('Figure 1. Seasonal average heat index by calendar month', ...
    'FontSize', 12, 'FontWeight', 'bold');
ylim([27 39]);
grid on; box off;

for m = 1:12
    text(m, monthlyHI(m) + 0.15, sprintf('%.2f', monthlyHI(m)), ...
        'HorizontalAlignment', 'center', 'FontSize', 8, 'Color', [0.3 0.3 0.3]);
end

h1 = patch(NaN, NaN, blue, 'EdgeColor','none');
h2 = patch(NaN, NaN, red,  'EdgeColor','none');
legend([h1 h2], {'Cooler (avg < 35°C)', 'Peak heat (avg ≥ 35°C)'}, ...
    'Location', 'southwest', 'FontSize', 9);

% FIGURE 2a: 24-Month Forecast with Optimal Window

figure(2);
set(gcf, 'Position', [100, 150, 900, 420], 'Name', ' Model Behavior: Forecast');

bar_colors2 = repmat(teal, numForecast, 1);
for i = best_start:best_end
    bar_colors2(i,:) = red;
end

b2 = bar(1:numForecast, HI_forecast, 'FaceColor', 'flat');
b2.CData = bar_colors2;
b2.EdgeColor = 'none';

hold on;
yline(35, '--', '35°C threshold', ...
    'Color', [0.85 0.45 0.20], 'LineWidth', 1.2, ...
    'LabelHorizontalAlignment', 'right', 'FontSize', 9);

xticks(1:numForecast);
xticklabels(forecast_labels);
xtickangle(45);
ylabel('Heat Index (°C)', 'FontSize', 11);
xlabel('Month', 'FontSize', 11);
title('Figure 2. 24-month HI forecast with optimal academic window highlighted', ...
    'FontSize', 12, 'FontWeight', 'bold');
ylim([27 39]);
grid on; box off;

h3 = patch(NaN, NaN, teal, 'EdgeColor','none');
h4 = patch(NaN, NaN, red,  'EdgeColor','none');
legend([h3 h4], {'Forecasted HI', 'Optimal window: Jul 2026 – Apr 2027'}, ...
    'Location', 'southwest', 'FontSize', 9);

% FIGURE 3: Sliding Window Cumulative HI

figure(3);
set(gcf, 'Position', [860, 600, 700, 380], 'Name', ' Model Behavior: Windows');

bar_colors3 = repmat(amber, num_windows, 1);
bar_colors3(best_start,:) = red;

b3 = bar(1:num_windows, window_sums, 'FaceColor', 'flat');
b3.CData = bar_colors3;
b3.EdgeColor = 'none';

xticks(1:num_windows);
xticklabels(window_labels);
ylabel('Cumulative Heat Index (°C)', 'FontSize', 11);
xlabel('Window', 'FontSize', 11);
title('Figure 3. Cumulative HI for all 15 sliding windows', ...
    'FontSize', 12, 'FontWeight', 'bold');
ylim([332 348]);
grid on; box off;

for i = 1:num_windows
    text(i, window_sums(i) + 0.08, sprintf('%.1f', window_sums(i)), ...
        'HorizontalAlignment', 'center', 'FontSize', 7.5, 'Color', [0.3 0.3 0.3]);
end

h5 = patch(NaN, NaN, amber, 'EdgeColor','none');
h6 = patch(NaN, NaN, red,   'EdgeColor','none');
legend([h5 h6], {'Candidate windows', 'Optimal: W4 (Jul 2026 – Apr 2027)'}, ...
    'Location', 'north', 'FontSize', 9);

% FIGURE 4: Mean Absolute Error per Calendar Month

figure(4);
set(gcf, 'Position', [100, 100, 500, 360], 'Name', 'Error Trends: MAE');

b4 = bar(1:12, mae_per_month, 'FaceColor', purple, 'EdgeColor', 'none');

xticks(1:12);
xticklabels(month_labels);
ylabel('Mean Absolute Error (°C)', 'FontSize', 11);
xlabel('Month', 'FontSize', 11);
title('Figure 4. Mean absolute error per calendar month', ...
    'FontSize', 12, 'FontWeight', 'bold');
ylim([0 1.4]);
grid on; box off;

for m = 1:12
    text(m, mae_per_month(m) + 0.02, sprintf('%.4f', mae_per_month(m)), ...
        'HorizontalAlignment', 'center', 'FontSize', 7.5, 'Color', [0.3 0.3 0.3]);
end

% FIGURE 5: Historical HI vs. Seasonal Average Forecast

figure(5);
set(gcf, 'Position', [620, 500, 700, 360], 'Name', 'Error Trends: Fit vs Actual');

x_idx = 1:39;
plot(x_idx, seasonal_fit, '-o', 'Color', teal, 'LineWidth', 2, ...
    'MarkerSize', 4, 'MarkerFaceColor', teal, 'DisplayName', 'Seasonal avg forecast');
hold on;
plot(x_idx, HI_historical, '--s', 'Color', pink, 'LineWidth', 1.5, ...
    'MarkerSize', 4, 'MarkerFaceColor', pink, 'DisplayName', 'Actual historical HI');

xticks(1:3:39);
tick_labels = hist_labels_short(1:3:39);
xticklabels(tick_labels);
xtickangle(45);
ylabel('Heat Index (°C)', 'FontSize', 11);
xlabel('Month', 'FontSize', 11);
title('Figure 5. Actual historical HI vs. seasonal average forecast (Jan 2023 – Mar 2026)', ...
    'FontSize', 12, 'FontWeight', 'bold');
ylim([27 39]);
legend('Location', 'southwest', 'FontSize', 9);
grid on; box off;

% FIGURE 6: Residual Errors Across 39 Months

figure(6); % Re-added this missing line
set(gcf, 'Position', [620, 100, 700, 360], 'Name', 'Error Trends: Residuals');

pos_res = residuals; pos_res(residuals < 0) = 0;
neg_res = residuals; neg_res(residuals >= 0) = 0;

bar(x_idx, pos_res, 'FaceColor', purple, 'EdgeColor', 'none', ...
    'DisplayName', 'Positive residual (actual > forecast)');
hold on;
bar(x_idx, neg_res, 'FaceColor', [0.94 0.60 0.47], 'EdgeColor', 'none', ...
    'DisplayName', 'Negative residual (actual < forecast)');
yline(0, '--', 'Color', gray, 'LineWidth', 1.2, 'HandleVisibility', 'off');

xticks(1:3:39);
xticklabels(tick_labels);
xtickangle(45);
ylabel('Residual (°C)', 'FontSize', 11);
xlabel('Month', 'FontSize', 11);
title('Figure 6. Residual errors across all 39 historical months', ...
    'FontSize', 12, 'FontWeight', 'bold');
legend('Location', 'northwest', 'FontSize', 9);
grid on; box off;

% FIGURE 7: Running Minimum Convergence

figure(7);
set(gcf, 'Position', [100, 100, 500, 360], 'Name', ' Convergence: Running Min');

plot(1:num_windows, running_min, '-o', 'Color', blue, 'LineWidth', 2, ...
    'MarkerSize', 5, 'MarkerFaceColor', blue);
hold on;
plot(best_start, running_min(best_start), 'o', 'Color', red, ...
    'MarkerSize', 9, 'MarkerFaceColor', red, 'DisplayName', 'Convergence point (W4)');

xticks(1:num_windows);
xticklabels(window_labels);
ylabel('Running minimum cumulative HI (°C)', 'FontSize', 11);
xlabel('Window iteration', 'FontSize', 11);
title('Figure 7. Running minimum HI across 15 iterations', ...
    'FontSize', 12, 'FontWeight', 'bold');
ylim([332 346]);
grid on; box off;

h7 = plot(NaN, NaN, '-o', 'Color', blue, 'LineWidth', 2, 'MarkerFaceColor', blue);
h8 = plot(NaN, NaN, 'o',  'Color', red,  'MarkerSize', 9, 'MarkerFaceColor', red);
legend([h7 h8], {'Running minimum', 'Convergence point (W4)'}, ...
    'Location', 'southwest', 'FontSize', 9);

% FIGURE 8: Improvement Delta per Iteration

figure(8);
set(gcf, 'Position', [1130, 100, 500, 360], 'Name', ' Convergence: Delta');

delta_colors = repmat([0.8 0.8 0.78], num_windows, 1);
for i = 1:num_windows
    if improvement_delta(i) > 0
        delta_colors(i,:) = [0.36 0.79 0.64];
    end
end

b5 = bar(1:num_windows, improvement_delta, 'FaceColor', 'flat');
b5.CData = delta_colors;
b5.EdgeColor = 'none';

xticks(1:num_windows);
xticklabels(window_labels);
ylabel('HI reduction vs. previous best (°C)', 'FontSize', 11);
xlabel('Window iteration', 'FontSize', 11);
title('Figure 8. Improvement delta per sliding window iteration', ...
    'FontSize', 12, 'FontWeight', 'bold');
grid on; box off;

for i = 1:num_windows
    if improvement_delta(i) > 0
        text(i, improvement_delta(i) + 0.05, sprintf('%.4f', improvement_delta(i)), ...
            'HorizontalAlignment', 'center', 'FontSize', 8, 'Color', [0.3 0.3 0.3]);
    end
end

h9  = patch(NaN, NaN, [0.36 0.79 0.64], 'EdgeColor','none');
h10 = patch(NaN, NaN, [0.8 0.8 0.78],   'EdgeColor','none');
legend([h9 h10], {'Improvement (HI reduced)', 'No improvement (delta = 0)'}, ...
    'Location', 'northeast', 'FontSize', 9);

% PRINT SUMMARY TABLE

fprintf('\n=== FIGURE 4c: COMPLETE SLIDING WINDOW TABLE ===\n');
fprintf('%-6s %-12s %-12s %-18s %-18s %-16s\n', ...
    'Win','Start','End','Cumulative HI','Avg HI/month','Running Min');
fprintf('%s\n', repmat('-', 1, 82));
cur_min2 = inf;
for i = 1:num_windows
    if window_sums(i) < cur_min2; cur_min2 = window_sums(i); end
    tag = '';
    if i == best_start; tag = '<-- OPTIMAL'; end
    if window_sums(i) == max_sum; tag = '<-- WORST'; end
    fprintf('W%-5d %-12s %-12s %-18.4f %-18.4f %-16.4f %s\n', ...
        i, forecast_labels{i}, forecast_labels{i+L-1}, ...
        window_sums(i), window_sums(i)/L, cur_min2, tag);
end

fprintf('\nAll figures generated. Use File > Save As in each figure window\n');
fprintf('to export as PNG, PDF, or EPS for your paper.\n');