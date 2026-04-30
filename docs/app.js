const STORAGE_KEYS = {
  logs: "insomniaTracWebLogs",
  welcomeSeen: "insomniaTracWebWelcomeSeen",
  reminders: "insomniaTracWebReminders",
  notified: "insomniaTracWebLastNotified"
};

const COMMON_ACTIVITIES = [
  "Workout",
  "Work",
  "School",
  "Study",
  "Walking",
  "Screen Time",
  "Social",
  "Napping",
  "Travel",
  "Gaming"
];

const state = {
  currentTab: "overview",
  logs: [],
  selectedActivities: new Set(),
  editingLogId: null,
  reminderTimer: null
};

const els = {
  pages: document.querySelectorAll(".page"),
  tabs: document.querySelectorAll(".tab"),
  welcomeOverlay: document.getElementById("welcome-overlay"),
  welcomeStart: document.getElementById("welcome-start"),
  welcomeLoadSample: document.getElementById("welcome-load-sample"),
  jumpLog: document.querySelector("[data-jump-log]"),
  loadSampleOverview: document.getElementById("load-sample-overview"),
  generateSummary: document.getElementById("generate-summary"),
  coachEmpty: document.getElementById("coach-empty"),
  coachOutput: document.getElementById("coach-output"),
  coachHeadline: document.getElementById("coach-headline"),
  coachBody: document.getElementById("coach-body"),
  metricGrid: document.getElementById("metric-grid"),
  chart: document.getElementById("sleep-chart"),
  historyList: document.getElementById("history-list"),
  saveLog: document.getElementById("save-log"),
  cancelEditing: document.getElementById("cancel-editing"),
  form: document.getElementById("sleep-form"),
  logDate: document.getElementById("log-date"),
  bedtime: document.getElementById("bedtime"),
  wakeTime: document.getElementById("wake-time"),
  logTitle: document.getElementById("log-title"),
  logSubtitle: document.getElementById("log-subtitle"),
  selectedDateLabel: document.getElementById("selected-date-label"),
  sleepHours: document.getElementById("sleep-hours"),
  sleepHoursValue: document.getElementById("sleep-hours-value"),
  feeling: document.getElementById("feeling"),
  difficulty: document.getElementById("difficulty"),
  difficultyValue: document.getElementById("difficulty-value"),
  difficultyText: document.getElementById("difficulty-text"),
  wakeups: document.getElementById("wakeups"),
  wakeupsValue: document.getElementById("wakeups-value"),
  wakeupsText: document.getElementById("wakeups-text"),
  energy: document.getElementById("energy"),
  energyValue: document.getElementById("energy-value"),
  energyText: document.getElementById("energy-text"),
  activityLevel: document.getElementById("activity-level"),
  activityLevelValue: document.getElementById("activity-level-value"),
  activityGrid: document.getElementById("activity-grid"),
  customActivity: document.getElementById("custom-activity"),
  addCustomActivity: document.getElementById("add-custom-activity"),
  selectedActivities: document.getElementById("selected-activities"),
  notes: document.getElementById("notes"),
  lateNightEating: document.getElementById("late-night-eating"),
  waterIntake: document.getElementById("water-intake"),
  waterIntakeValue: document.getElementById("water-intake-value"),
  coffeeIntake: document.getElementById("coffee-intake"),
  coffeeIntakeValue: document.getElementById("coffee-intake-value"),
  alcoholIntake: document.getElementById("alcohol-intake"),
  alcoholIntakeValue: document.getElementById("alcohol-intake-value"),
  heroTitle: document.getElementById("hero-title"),
  heroSubtitle: document.getElementById("hero-subtitle"),
  pillAvg: document.getElementById("pill-avg"),
  pillScore: document.getElementById("pill-score"),
  pillCount: document.getElementById("pill-count"),
  eveningReminder: document.getElementById("evening-reminder"),
  morningReminder: document.getElementById("morning-reminder"),
  enableNotifications: document.getElementById("enable-notifications"),
  saveReminders: document.getElementById("save-reminders"),
  notificationStatus: document.getElementById("notification-status"),
  notificationMessage: document.getElementById("notification-message")
};

init();

function init() {
  state.logs = loadLogs();
  renderActivityButtons();
  bindEvents();
  loadReminderSettings();
  resetForm();
  renderAll();
  startReminderTimer();

  if (!localStorage.getItem(STORAGE_KEYS.welcomeSeen)) {
    els.welcomeOverlay.classList.remove("hidden");
  }
}

function bindEvents() {
  els.tabs.forEach((tab) => {
    tab.addEventListener("click", () => switchTab(tab.dataset.tab));
  });

  els.welcomeStart.addEventListener("click", () => {
    localStorage.setItem(STORAGE_KEYS.welcomeSeen, "true");
    els.welcomeOverlay.classList.add("hidden");
  });

  els.welcomeLoadSample.addEventListener("click", () => {
    loadSampleData();
    localStorage.setItem(STORAGE_KEYS.welcomeSeen, "true");
    els.welcomeOverlay.classList.add("hidden");
  });

  els.jumpLog.addEventListener("click", () => switchTab("log"));
  els.loadSampleOverview.addEventListener("click", loadSampleData);
  els.generateSummary.addEventListener("click", generateSummary);
  els.saveLog.addEventListener("click", saveLog);
  els.cancelEditing.addEventListener("click", () => resetForm());

  els.logDate.addEventListener("input", updateDateLabel);
  els.sleepHours.addEventListener("input", () => {
    els.sleepHoursValue.textContent = `${Number(els.sleepHours.value).toFixed(1)}h`;
  });
  els.difficulty.addEventListener("input", updateSliderLabels);
  els.wakeups.addEventListener("input", updateSliderLabels);
  els.energy.addEventListener("input", updateSliderLabels);
  els.activityLevel.addEventListener("input", updateSliderLabels);

  els.addCustomActivity.addEventListener("click", addCustomActivity);
  document.querySelectorAll("[data-stepper]").forEach((button) => {
    button.addEventListener("click", () => stepValue(button.dataset.stepper, Number(button.dataset.step)));
  });

  els.enableNotifications.addEventListener("click", requestNotifications);
  els.saveReminders.addEventListener("click", saveReminderSettings);
}

function switchTab(tabName) {
  state.currentTab = tabName;
  els.tabs.forEach((tab) => tab.classList.toggle("active", tab.dataset.tab === tabName));
  els.pages.forEach((page) => page.classList.toggle("active", page.dataset.page === tabName));
}

function renderAll() {
  updateOverview();
  renderHistory();
  updateNotificationStatus();
}

function loadLogs() {
  try {
    return JSON.parse(localStorage.getItem(STORAGE_KEYS.logs) || "[]");
  } catch {
    return [];
  }
}

function persistLogs() {
  localStorage.setItem(STORAGE_KEYS.logs, JSON.stringify(state.logs));
}

function getWeeklyLogs() {
  return [...state.logs]
    .sort((a, b) => new Date(b.date) - new Date(a.date))
    .slice(0, 7)
    .reverse();
}

function average(values) {
  if (!values.length) return 0;
  return values.reduce((sum, value) => sum + value, 0) / values.length;
}

function insomniaScore(log) {
  return (log.difficultyFallingAsleep + log.nighttimeWakeUps + (6 - log.morningEnergy)) / 3;
}

function formatOneDecimal(value) {
  return Number(value).toFixed(1);
}

function shortDate(dateValue) {
  return new Date(dateValue).toLocaleDateString(undefined, { month: "short", day: "numeric" });
}

function fullDate(dateValue) {
  return new Date(dateValue).toLocaleDateString(undefined, {
    weekday: "long",
    year: "numeric",
    month: "long",
    day: "numeric"
  });
}

function timeLabel(timeValue) {
  const [hours, minutes] = timeValue.split(":").map(Number);
  const d = new Date();
  d.setHours(hours, minutes, 0, 0);
  return d.toLocaleTimeString([], { hour: "numeric", minute: "2-digit" });
}

function updateOverview() {
  const weeklyLogs = getWeeklyLogs();
  const avgSleep = average(weeklyLogs.map((log) => log.sleepHours));
  const avgEnergy = average(weeklyLogs.map((log) => log.morningEnergy));
  const avgWakeups = average(weeklyLogs.map((log) => log.nighttimeWakeUps));
  const avgScore = average(weeklyLogs.map(insomniaScore));
  const avgCoffee = average(weeklyLogs.map((log) => log.coffeeIntakeCups));
  const lateNightCount = weeklyLogs.filter((log) => log.lateNightEating).length;
  const sleepValues = weeklyLogs.map((log) => log.sleepHours);
  const sleepRange = sleepValues.length ? Math.max(...sleepValues) - Math.min(...sleepValues) : 0;

  els.pillAvg.textContent = weeklyLogs.length ? `${formatOneDecimal(avgSleep)}h` : "--";
  els.pillScore.textContent = weeklyLogs.length ? `${formatOneDecimal(avgScore)} / 5` : "--";
  els.pillCount.textContent = String(weeklyLogs.length);

  if (!weeklyLogs.length) {
    els.heroTitle.textContent = "Start your first sleep log";
    els.heroSubtitle.textContent = "Use the Log tab to add your first entry, then come back here to review your patterns.";
  } else if (avgSleep < 7) {
    els.heroTitle.textContent = "You are running short on sleep";
    els.heroSubtitle.textContent = "Your overview is for trends and reflection. Add another log whenever you want to keep the pattern accurate.";
  } else {
    els.heroTitle.textContent = "Your sleep is in a healthy range";
    els.heroSubtitle.textContent = "Overview helps you review patterns, while the Log tab captures new nights as they happen.";
  }

  const metricCards = [
    {
      title: "Average Sleep",
      value: weeklyLogs.length ? `${formatOneDecimal(avgSleep)}h` : "--",
      detail: !weeklyLogs.length
        ? "Track a few nights to see your weekly average."
        : avgSleep < 7
          ? "Your recent average is below the 7-9 hour range."
          : "Your recent average is within a healthy sleep window."
    },
    {
      title: "Consistency",
      value: weeklyLogs.length ? `${formatOneDecimal(sleepRange)}h` : "--",
      detail: !weeklyLogs.length
        ? "Consistency appears after a few entries."
        : sleepRange < 1
          ? "Your recent sleep duration looks fairly steady."
          : "There is some visible swing between nights."
    },
    {
      title: "Morning Energy",
      value: weeklyLogs.length ? `${formatOneDecimal(avgEnergy)} / 5` : "--",
      detail: !weeklyLogs.length
        ? "Morning energy will show up here."
        : avgEnergy < 3
          ? "Mornings have been feeling low energy."
          : "Your energy is holding up fairly well."
    },
    {
      title: "Wake-Ups",
      value: weeklyLogs.length ? `${formatOneDecimal(avgWakeups)} / night` : "--",
      detail: !weeklyLogs.length
        ? "Wake-up trends will show up here."
        : avgWakeups >= 3
          ? "Frequent wake-ups may be affecting sleep quality."
          : "Your recent nights show fewer interruptions."
    }
  ];

  els.metricGrid.innerHTML = metricCards.map((metric) => `
    <article class="metric-card">
      <span>${metric.title}</span>
      <strong>${metric.value}</strong>
      <p>${metric.detail}</p>
    </article>
  `).join("");

  renderChart(weeklyLogs);

  const summary = createSummary(weeklyLogs);
  if (!weeklyLogs.length || weeklyLogs.length < 3) {
    els.coachEmpty.classList.remove("hidden");
    els.coachOutput.classList.add("hidden");
    els.generateSummary.disabled = weeklyLogs.length < 3;
    els.generateSummary.textContent = weeklyLogs.length ? "Need More Logs" : "Generate Summary";
  } else {
    els.coachEmpty.classList.add("hidden");
    els.generateSummary.disabled = false;
    els.generateSummary.textContent = "Generate Summary";
    if (summary.generated) {
      els.coachOutput.classList.remove("hidden");
      els.coachHeadline.textContent = summary.headline;
      els.coachBody.textContent = summary.body;
    } else {
      els.coachOutput.classList.add("hidden");
    }
  }

  state.overviewContext = {
    weeklyLogs,
    avgSleep,
    avgEnergy,
    avgWakeups,
    avgCoffee,
    lateNightCount
  };
}

function renderChart(weeklyLogs) {
  const svg = els.chart;
  if (!weeklyLogs.length) {
    svg.innerHTML = `
      <text x="20" y="90" fill="rgba(229,222,255,0.72)" font-size="14">
        Add a few nights to see your sleep trend here.
      </text>
    `;
    return;
  }

  const width = 320;
  const height = 180;
  const pad = 18;
  const maxY = Math.max(12, ...weeklyLogs.map((log) => log.sleepHours), 10) + 1;
  const xStep = weeklyLogs.length > 1 ? (width - pad * 2) / (weeklyLogs.length - 1) : 0;
  const toY = (value) => height - pad - ((value / maxY) * (height - pad * 2));

  const points = weeklyLogs.map((log, index) => ({
    x: pad + (index * xStep),
    y: toY(log.sleepHours),
    label: shortDate(log.date),
    value: log.sleepHours
  }));

  const line = points.map((point, index) => `${index === 0 ? "M" : "L"} ${point.x} ${point.y}`).join(" ");
  const area = `${line} L ${points[points.length - 1].x} ${height - pad} L ${points[0].x} ${height - pad} Z`;

  const goal7 = toY(7);
  const goal9 = toY(9);

  svg.innerHTML = `
    <defs>
      <linearGradient id="webAreaFade" x1="0" x2="0" y1="0" y2="1">
        <stop offset="0%" stop-color="rgba(184,148,255,0.66)"></stop>
        <stop offset="100%" stop-color="rgba(184,148,255,0.02)"></stop>
      </linearGradient>
    </defs>
    <line x1="${pad}" y1="${goal7}" x2="${width - pad}" y2="${goal7}" stroke="rgba(247,231,188,0.38)" stroke-dasharray="6 6"></line>
    <line x1="${pad}" y1="${goal9}" x2="${width - pad}" y2="${goal9}" stroke="rgba(247,231,188,0.22)" stroke-dasharray="6 6"></line>
    <path d="${area}" fill="url(#webAreaFade)"></path>
    <path d="${line}" fill="none" stroke="#f2ecff" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"></path>
    ${points.map((point) => `
      <circle cx="${point.x}" cy="${point.y}" r="4.5" fill="${point.value >= 7 ? "#f7e7bc" : "#b894ff"}"></circle>
      <text x="${point.x}" y="${height - 4}" text-anchor="middle" fill="rgba(229,222,255,0.75)" font-size="10">${point.label}</text>
    `).join("")}
  `;
}

function createSummary(weeklyLogs = getWeeklyLogs()) {
  if (weeklyLogs.length < 3) {
    return { generated: false, headline: "", body: "" };
  }

  const avgSleep = average(weeklyLogs.map((log) => log.sleepHours));
  const avgWakeups = average(weeklyLogs.map((log) => log.nighttimeWakeUps));
  const avgEnergy = average(weeklyLogs.map((log) => log.morningEnergy));
  const avgCoffee = average(weeklyLogs.map((log) => log.coffeeIntakeCups));
  const avgAlcohol = average(weeklyLogs.map((log) => log.alcoholIntakeDrinks));
  const lateNightCount = weeklyLogs.filter((log) => log.lateNightEating).length;

  let headline = "Weekly Sleep Summary";
  let summary = `You averaged ${formatOneDecimal(avgSleep)} hours of sleep with ${formatOneDecimal(avgWakeups)} wake-ups a night and ${formatOneDecimal(avgEnergy)} / 5 morning energy. `;
  let nextStep = "Keep logging consistently so subtler patterns stay visible.";

  if (avgSleep < 7) {
    headline = "Protect your sleep window";
    nextStep = "Try protecting a longer 7-9 hour sleep window for the next few nights.";
  } else if (avgCoffee >= 2) {
    headline = "Caffeine may be worth testing";
    nextStep = "Try one lighter caffeine day and compare your sleep and energy.";
  } else if (avgAlcohol >= 1) {
    headline = "Alcohol may be affecting recovery";
    nextStep = "Try reducing evening drinks for a few nights and compare wake-ups and morning energy.";
  } else if (lateNightCount >= 3) {
    headline = "Earlier meals may help";
    nextStep = "Try finishing meals earlier this week and see whether your nights feel steadier.";
  } else if (avgWakeups >= 3) {
    headline = "Focus on fewer interruptions";
    nextStep = "Try a calmer wind-down routine and compare your next few nights.";
  } else {
    headline = "Your routine looks fairly steady";
    nextStep = "Keep repeating the habits behind your strongest nights.";
  }

  return {
    generated: true,
    headline,
    body: `${summary}${nextStep}`
  };
}

function generateSummary() {
  const summary = createSummary();
  if (!summary.generated) return;
  els.coachEmpty.classList.add("hidden");
  els.coachOutput.classList.remove("hidden");
  els.coachHeadline.textContent = summary.headline;
  els.coachBody.textContent = summary.body;
}

function renderActivityButtons() {
  els.activityGrid.innerHTML = COMMON_ACTIVITIES.map((activity) => `
    <button type="button" class="activity-button" data-activity="${activity}">${activity}</button>
  `).join("");

  els.activityGrid.querySelectorAll("[data-activity]").forEach((button) => {
    button.addEventListener("click", () => toggleActivity(button.dataset.activity));
  });
}

function toggleActivity(activity) {
  if (state.selectedActivities.has(activity)) {
    state.selectedActivities.delete(activity);
  } else {
    state.selectedActivities.add(activity);
  }
  syncActivityButtons();
  renderSelectedActivities();
}

function syncActivityButtons() {
  els.activityGrid.querySelectorAll("[data-activity]").forEach((button) => {
    button.classList.toggle("active", state.selectedActivities.has(button.dataset.activity));
  });
}

function renderSelectedActivities() {
  if (!state.selectedActivities.size) {
    els.selectedActivities.innerHTML = "";
    return;
  }
  els.selectedActivities.innerHTML = [...state.selectedActivities]
    .sort()
    .map((activity) => `<span class="selected-chip">${activity}</span>`)
    .join("");
}

function addCustomActivity() {
  const value = els.customActivity.value.trim();
  if (!value) return;
  state.selectedActivities.add(value);
  els.customActivity.value = "";
  renderSelectedActivities();
}

function updateDateLabel() {
  els.selectedDateLabel.textContent = fullDate(els.logDate.value);
}

function updateSliderLabels() {
  els.difficultyValue.textContent = `${els.difficulty.value}/5`;
  els.wakeupsValue.textContent = `${els.wakeups.value}/5`;
  els.energyValue.textContent = `${els.energy.value}/5`;
  els.activityLevelValue.textContent = `${els.activityLevel.value}/5`;

  els.difficultyText.textContent = difficultyText(Number(els.difficulty.value));
  els.wakeupsText.textContent = wakeupText(Number(els.wakeups.value));
  els.energyText.textContent = energyText(Number(els.energy.value));
}

function difficultyText(value) {
  if (value <= 2) return "Low difficulty";
  if (value === 3) return "Moderate difficulty";
  return "High difficulty";
}

function wakeupText(value) {
  if (value <= 2) return "Few wake-ups";
  if (value === 3) return "Some wake-ups";
  return "Frequent wake-ups";
}

function energyText(value) {
  if (value <= 2) return "Low morning energy";
  if (value === 3) return "Moderate morning energy";
  return "High morning energy";
}

function stepValue(inputId, step) {
  const input = document.getElementById(inputId);
  const max = inputId === "water-intake" ? 16 : 10;
  const next = Math.max(0, Math.min(max, Number(input.value) + step));
  input.value = next;
  document.getElementById(`${inputId}-value`).textContent = String(next);
}

function collectFormData() {
  return {
    id: state.editingLogId || crypto.randomUUID(),
    date: els.logDate.value,
    sleepHours: Number(els.sleepHours.value),
    bedtime: els.bedtime.value,
    wakeTime: els.wakeTime.value,
    notes: els.notes.value.trim(),
    feeling: els.feeling.value,
    activities: [...state.selectedActivities].sort(),
    activityLevel: Number(els.activityLevel.value),
    lateNightEating: els.lateNightEating.checked,
    waterIntakeGlasses: Number(els.waterIntake.value),
    coffeeIntakeCups: Number(els.coffeeIntake.value),
    alcoholIntakeDrinks: Number(els.alcoholIntake.value),
    difficultyFallingAsleep: Number(els.difficulty.value),
    nighttimeWakeUps: Number(els.wakeups.value),
    morningEnergy: Number(els.energy.value)
  };
}

function saveLog() {
  if (!els.form.reportValidity()) return;

  const log = collectFormData();
  const existingIndex = state.logs.findIndex((item) => item.id === log.id);
  if (existingIndex >= 0) {
    state.logs[existingIndex] = log;
  } else {
    state.logs.unshift(log);
  }

  state.logs.sort((a, b) => new Date(b.date) - new Date(a.date));
  persistLogs();
  resetForm();
  renderAll();
  switchTab("history");
}

function resetForm() {
  state.editingLogId = null;
  const today = new Date();
  const dateString = today.toISOString().slice(0, 10);
  els.logDate.value = dateString;
  els.bedtime.value = "23:00";
  els.wakeTime.value = "07:00";
  els.sleepHours.value = "7.5";
  els.feeling.value = "Tired";
  els.difficulty.value = "3";
  els.wakeups.value = "2";
  els.energy.value = "3";
  els.activityLevel.value = "3";
  els.lateNightEating.checked = false;
  els.waterIntake.value = "6";
  els.coffeeIntake.value = "0";
  els.alcoholIntake.value = "0";
  els.notes.value = "";
  state.selectedActivities = new Set();
  syncActivityButtons();
  renderSelectedActivities();
  updateDateLabel();
  els.sleepHoursValue.textContent = "7.5h";
  els.waterIntakeValue.textContent = "6";
  els.coffeeIntakeValue.textContent = "0";
  els.alcoholIntakeValue.textContent = "0";
  updateSliderLabels();
  els.cancelEditing.classList.add("hidden");
  els.saveLog.textContent = "Save Log";
  els.logTitle.textContent = "Sleep basics";
  els.logSubtitle.textContent = "Record the core details first, then add extra context only when it matters.";
}

function renderHistory() {
  if (!state.logs.length) {
    els.historyList.innerHTML = `
      <section class="glass-card">
        <div class="empty-state">
          <h3>No logs yet</h3>
          <p>Your saved sleep entries will show up here after you add your first check-in.</p>
        </div>
      </section>
    `;
    return;
  }

  const template = document.getElementById("history-item-template");
  els.historyList.innerHTML = "";

  state.logs.forEach((log) => {
    const node = template.content.cloneNode(true);
    node.querySelector(".history-date").textContent = fullDate(log.date);
    node.querySelector(".history-hours").textContent = `${formatOneDecimal(log.sleepHours)} hours slept`;

    const pills = [
      ["Bedtime", timeLabel(log.bedtime)],
      ["Wake", timeLabel(log.wakeTime)],
      ["Feeling", log.feeling],
      ["Alcohol", `${log.alcoholIntakeDrinks} drink${log.alcoholIntakeDrinks === 1 ? "" : "s"}`],
      ["Score", `${formatOneDecimal(insomniaScore(log))} / 5`]
    ];

    node.querySelector(".history-pills").innerHTML = pills.map(([label, value]) => `
      <div class="history-pill">
        <span>${label}</span>
        <strong>${value}</strong>
      </div>
    `).join("");

    const activitiesWrap = node.querySelector(".history-activities");
    if (log.activities.length) {
      activitiesWrap.classList.remove("hidden");
      activitiesWrap.innerHTML = `
        <strong>Activities</strong>
        <div class="history-activities-list">
          ${log.activities.map((activity) => `<span class="selected-chip">${activity}</span>`).join("")}
        </div>
      `;
    }

    const notesWrap = node.querySelector(".history-notes");
    if (log.notes) {
      notesWrap.classList.remove("hidden");
      notesWrap.innerHTML = `<strong>Notes</strong><p>${escapeHtml(log.notes)}</p>`;
    }

    node.querySelector(".history-edit").addEventListener("click", () => editLog(log.id));
    node.querySelector(".history-delete").addEventListener("click", () => deleteLog(log.id));
    els.historyList.appendChild(node);
  });
}

function editLog(id) {
  const log = state.logs.find((item) => item.id === id);
  if (!log) return;

  state.editingLogId = log.id;
  els.logDate.value = log.date;
  els.bedtime.value = log.bedtime;
  els.wakeTime.value = log.wakeTime;
  els.sleepHours.value = String(log.sleepHours);
  els.feeling.value = log.feeling;
  els.difficulty.value = String(log.difficultyFallingAsleep);
  els.wakeups.value = String(log.nighttimeWakeUps);
  els.energy.value = String(log.morningEnergy);
  els.activityLevel.value = String(log.activityLevel);
  els.lateNightEating.checked = log.lateNightEating;
  els.waterIntake.value = String(log.waterIntakeGlasses);
  els.coffeeIntake.value = String(log.coffeeIntakeCups);
  els.alcoholIntake.value = String(log.alcoholIntakeDrinks);
  els.notes.value = log.notes;
  state.selectedActivities = new Set(log.activities);
  syncActivityButtons();
  renderSelectedActivities();
  updateDateLabel();
  els.sleepHoursValue.textContent = `${formatOneDecimal(log.sleepHours)}h`;
  els.waterIntakeValue.textContent = String(log.waterIntakeGlasses);
  els.coffeeIntakeValue.textContent = String(log.coffeeIntakeCups);
  els.alcoholIntakeValue.textContent = String(log.alcoholIntakeDrinks);
  updateSliderLabels();
  els.cancelEditing.classList.remove("hidden");
  els.saveLog.textContent = "Update Log";
  els.logTitle.textContent = "Edit sleep log";
  els.logSubtitle.textContent = "Update the details you want to correct, then save the refreshed entry.";
  switchTab("log");
}

function deleteLog(id) {
  state.logs = state.logs.filter((item) => item.id !== id);
  persistLogs();
  if (state.editingLogId === id) {
    resetForm();
  }
  renderAll();
}

function loadSampleData() {
  state.logs = [
    sampleLog(6, 6.0, "00:10", "06:35", "Tired", ["Work", "Screen Time"], 2, true, 4, 3, 1, 4, 3, 2, "Fell asleep later than planned after scrolling."),
    sampleLog(5, 6.5, "23:40", "06:50", "Anxious", ["Work", "Study"], 3, false, 5, 2, 0, 4, 2, 2, "Busy day and mind still racing at bedtime."),
    sampleLog(4, 7.0, "23:05", "07:00", "Calm", ["Walking", "Work"], 3, false, 6, 1, 0, 3, 2, 3, "Better wind-down routine."),
    sampleLog(3, 7.5, "22:55", "07:10", "Energetic", ["Workout", "Work"], 4, false, 7, 1, 0, 2, 1, 4, "Workout seemed to help."),
    sampleLog(2, 6.0, "00:20", "06:30", "Tired", ["Social", "Screen Time"], 2, true, 4, 2, 2, 4, 3, 2, "Late dinner and social plans pushed bedtime back."),
    sampleLog(1, 7.2, "23:15", "07:05", "Calm", ["Walking", "Work"], 3, false, 6, 1, 0, 2, 1, 4, "More settled night overall."),
    sampleLog(0, 7.8, "22:50", "07:20", "Energetic", ["Workout", "Reading"], 4, false, 7, 1, 0, 2, 1, 4, "Strongest night of the week.")
  ].sort((a, b) => new Date(b.date) - new Date(a.date));
  persistLogs();
  renderAll();
}

function sampleLog(daysAgo, sleepHours, bedtime, wakeTime, feeling, activities, activityLevel, lateNightEating, water, coffee, alcohol, difficulty, wakeups, energy, notes) {
  const date = new Date();
  date.setHours(0, 0, 0, 0);
  date.setDate(date.getDate() - daysAgo);

  return {
    id: crypto.randomUUID(),
    date: date.toISOString().slice(0, 10),
    sleepHours,
    bedtime,
    wakeTime,
    notes,
    feeling,
    activities,
    activityLevel,
    lateNightEating,
    waterIntakeGlasses: water,
    coffeeIntakeCups: coffee,
    alcoholIntakeDrinks: alcohol,
    difficultyFallingAsleep: difficulty,
    nighttimeWakeUps: wakeups,
    morningEnergy: energy
  };
}

function loadReminderSettings() {
  const saved = JSON.parse(localStorage.getItem(STORAGE_KEYS.reminders) || "{}");
  els.eveningReminder.value = saved.evening || "21:00";
  els.morningReminder.value = saved.morning || "08:00";
}

function saveReminderSettings() {
  const reminders = {
    evening: els.eveningReminder.value || "21:00",
    morning: els.morningReminder.value || "08:00"
  };
  localStorage.setItem(STORAGE_KEYS.reminders, JSON.stringify(reminders));
  els.notificationMessage.textContent = "Reminder times saved in this browser.";
}

function requestNotifications() {
  if (!("Notification" in window)) {
    els.notificationMessage.textContent = "This browser does not support notifications.";
    return;
  }

  Notification.requestPermission().then(() => {
    updateNotificationStatus();
    if (Notification.permission === "granted") {
      els.notificationMessage.textContent = "Notifications enabled for this browser.";
    } else {
      els.notificationMessage.textContent = "Notification permission was not granted.";
    }
  });
}

function updateNotificationStatus() {
  if (!("Notification" in window)) {
    els.notificationStatus.textContent = "Unsupported";
    return;
  }

  if (Notification.permission === "granted") {
    els.notificationStatus.textContent = "Enabled";
  } else if (Notification.permission === "denied") {
    els.notificationStatus.textContent = "Denied";
  } else {
    els.notificationStatus.textContent = "Off";
  }
}

function startReminderTimer() {
  if (state.reminderTimer) clearInterval(state.reminderTimer);
  state.reminderTimer = setInterval(checkReminders, 60 * 1000);
  checkReminders();
}

function checkReminders() {
  if (!("Notification" in window) || Notification.permission !== "granted") return;

  const reminders = JSON.parse(localStorage.getItem(STORAGE_KEYS.reminders) || "{}");
  if (!reminders.evening && !reminders.morning) return;

  const now = new Date();
  const current = `${String(now.getHours()).padStart(2, "0")}:${String(now.getMinutes()).padStart(2, "0")}`;
  const todayKey = now.toISOString().slice(0, 10);
  const lastNotified = JSON.parse(localStorage.getItem(STORAGE_KEYS.notified) || "{}");

  if (reminders.evening === current && lastNotified.evening !== todayKey) {
    new Notification("Sleep Check-In", { body: "Log your sleep indicators for tonight." });
    lastNotified.evening = todayKey;
  }

  if (reminders.morning === current && lastNotified.morning !== todayKey) {
    new Notification("Morning Sleep Reflection", { body: "How was your sleep? Log your morning energy and wake-ups." });
    lastNotified.morning = todayKey;
  }

  localStorage.setItem(STORAGE_KEYS.notified, JSON.stringify(lastNotified));
}

function escapeHtml(value) {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}
