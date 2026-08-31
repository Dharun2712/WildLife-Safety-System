/**
 * ForestGuard Sentinel — Tactical Command Center JavaScript
 * Continuous wildlife threat surveillance, unblocked instant alerting,
 * Web Audio synth alarms, and live incident streaming.
 */

const ANIMAL_CONFIGS = {
    tiger: { name: 'Tiger', color: '#f97316' },
    elephant: { name: 'Elephant', color: '#00d2ff' },
    lion: { name: 'Lion', color: '#ef4444' },
    leopard: { name: 'Leopard', color: '#eab308' },
    bear: { name: 'Bear', color: '#94a3b8' },
};

// Global State
let isCameraActionInProgress = false;
let isSoundAlertEnabled = true;
let audioContext = null;
let lastProcessedIncidentId = null;
let lastAudioAlertTime = 0;
let lastBrowserNotificationTime = 0;
let displayedToastIds = new Set();

// --- Web Audio API Synth Alarm Engine ---

function initAudioContext() {
    if (!audioContext) {
        const AudioCtx = window.AudioContext || window.webkitAudioContext;
        if (AudioCtx) {
            audioContext = new AudioCtx();
        }
    }
}

function playWildlifeAlertChime(animalType) {
    if (!isSoundAlertEnabled) return;
    const nowMs = Date.now();
    // 0.6s debounce to prevent audio overlap while allowing rapid subsequent alerts
    if (nowMs - lastAudioAlertTime < 600) return;
    lastAudioAlertTime = nowMs;

    try {
        initAudioContext();
        if (!audioContext) return;

        if (audioContext.state === 'suspended') {
            audioContext.resume();
        }

        const now = audioContext.currentTime;

        // Tone 1: High Alert Pulse
        const osc1 = audioContext.createOscillator();
        const gain1 = audioContext.createGain();
        osc1.type = 'sawtooth';

        const baseFreq = animalType === 'tiger' || animalType === 'lion' ? 950 : 850;
        osc1.frequency.setValueAtTime(baseFreq, now);
        osc1.frequency.exponentialRampToValueAtTime(baseFreq + 350, now + 0.15);

        gain1.gain.setValueAtTime(0.3, now);
        gain1.gain.exponentialRampToValueAtTime(0.01, now + 0.22);

        osc1.connect(gain1);
        gain1.connect(audioContext.destination);
        osc1.start(now);
        osc1.stop(now + 0.22);

        // Tone 2: Futuristic Sine Chime
        const osc2 = audioContext.createOscillator();
        const gain2 = audioContext.createGain();
        osc2.type = 'sine';
        osc2.frequency.setValueAtTime(1400, now + 0.16);
        osc2.frequency.exponentialRampToValueAtTime(1780, now + 0.38);

        gain2.gain.setValueAtTime(0.35, now + 0.16);
        gain2.gain.exponentialRampToValueAtTime(0.001, now + 0.45);

        osc2.connect(gain2);
        gain2.connect(audioContext.destination);
        osc2.start(now + 0.16);
        osc2.stop(now + 0.45);
    } catch (e) {
        console.warn('Audio chime error:', e);
    }
}

function toggleSoundAlert() {
    isSoundAlertEnabled = !isSoundAlertEnabled;
    const btn = document.getElementById('sound-btn');
    const icon = document.getElementById('sound-icon');
    const label = document.getElementById('sound-label');

    if (btn && icon && label) {
        if (isSoundAlertEnabled) {
            btn.className = 'icon-action-btn sound-active';
            icon.textContent = '🔊';
            label.textContent = 'Sound ON';
            playWildlifeAlertChime('tiger');
        } else {
            btn.className = 'icon-action-btn sound-muted';
            icon.textContent = '🔇';
            label.textContent = 'Muted';
        }
    }
}

// --- Browser Desktop Notification System ---

async function requestNotificationPermission() {
    if (!('Notification' in window)) {
        alert('This browser does not support desktop notifications.');
        return;
    }

    const perm = await Notification.requestPermission();
    const btn = document.getElementById('notif-btn');
    const label = document.getElementById('notif-label');

    if (btn && label) {
        if (perm === 'granted') {
            btn.style.borderColor = 'rgba(16, 185, 129, 0.5)';
            btn.style.color = '#34d399';
            label.textContent = 'Active';
            new Notification('🌲 ForestGuard Sentinel Command', {
                body: 'Surveillance notifications active for Camera C-01 wildlife detections.',
            });
        } else {
            btn.style.color = '#f87171';
            label.textContent = 'Denied';
        }
    }
}

function sendDesktopNotification(animalType, confidencePercent, timeStr) {
    if (!('Notification' in window) || Notification.permission !== 'granted') return;

    const now = Date.now();
    // 1.5s cooldown for OS notifications
    if (now - lastBrowserNotificationTime < 1500) return;
    lastBrowserNotificationTime = now;

    const config = ANIMAL_CONFIGS[animalType] || { name: animalType };
    new Notification(`WILDLIFE DETECTED: ${config.name.toUpperCase()}`, {
        body: `${config.name} identified (${confidencePercent}% conf) at ${timeStr} · Dispatched to Rangers & Tourists!`,
        tag: `wildlife-alert-${now}`,
        requireInteraction: false,
    });
}

// --- Camera Hardware Control ---

async function toggleCamera() {
    if (isCameraActionInProgress) return;
    isCameraActionInProgress = true;

    initAudioContext();
    const masterBtn = document.getElementById('master-cam-toggle-btn');
    const quickBtn = document.getElementById('quick-stream-toggle');
    const msgDiv = document.getElementById('cam-feedback-msg');

    if (masterBtn) masterBtn.style.opacity = '0.6';
    if (quickBtn) quickBtn.style.opacity = '0.6';

    try {
        const res = await fetch('/api/camera/toggle', { method: 'POST' });
        const data = await res.json();

        if (msgDiv) {
            msgDiv.style.display = 'block';
            if (data.success) {
                msgDiv.className = 'cam-feedback-msg success';
                msgDiv.textContent = data.running ? '✅ Camera Online & Monitoring' : '⏹️ Camera Offline';
            } else {
                msgDiv.className = 'cam-feedback-msg error';
                msgDiv.textContent = `❌ ${data.message || 'Action failed'}`;
            }
            setTimeout(() => { msgDiv.style.display = 'none'; }, 3000);
        }

        await updateSentinelStatus();
    } catch (e) {
        console.error('Camera toggle error:', e);
        if (msgDiv) {
            msgDiv.style.display = 'block';
            msgDiv.className = 'cam-feedback-msg error';
            msgDiv.textContent = `❌ Network error: ${e.message}`;
            setTimeout(() => { msgDiv.style.display = 'none'; }, 3000);
        }
    } finally {
        isCameraActionInProgress = false;
        if (masterBtn) masterBtn.style.opacity = '1';
        if (quickBtn) quickBtn.style.opacity = '1';
    }
}

// --- Precision Threshold Tuning ---

function onThresholdSliderInput(value) {
    const badge = document.getElementById('threshold-display-badge');
    if (badge) badge.textContent = `${value}%`;
    highlightActivePresetPill(value / 100);
}

let thresholdSaveDebounce = null;
function onThresholdSliderChange(value) {
    clearTimeout(thresholdSaveDebounce);
    thresholdSaveDebounce = setTimeout(() => {
        saveThresholdToServer(value / 100);
    }, 80);
}

function applyThresholdPreset(val) {
    const input = document.getElementById('threshold-range-input');
    const badge = document.getElementById('threshold-display-badge');
    const pct = Math.round(val * 100);

    if (input) input.value = pct;
    if (badge) badge.textContent = `${pct}%`;

    highlightActivePresetPill(val);
    saveThresholdToServer(val);
}

function highlightActivePresetPill(val) {
    const presets = [
        { idx: 0, val: 0.35 },
        { idx: 1, val: 0.50 },
        { idx: 2, val: 0.65 },
        { idx: 3, val: 0.80 },
    ];
    const pills = document.querySelectorAll('.threshold-preset-grid .preset-pill');
    pills.forEach((pill, i) => {
        const p = presets[i];
        if (p && Math.abs(p.val - val) < 0.04) {
            pill.classList.add('active');
        } else {
            pill.classList.remove('active');
        }
    });
}

async function saveThresholdToServer(thresholdVal) {
    const toast = document.getElementById('threshold-feedback-msg');
    try {
        const res = await fetch('/api/config/threshold', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ threshold: thresholdVal }),
        });
        const data = await res.json();
        if (data.success && toast) {
            toast.style.display = 'block';
            toast.textContent = `🎯 Threshold set to ${data.percentage}%`;
            setTimeout(() => { toast.style.display = 'none'; }, 2200);
        }
    } catch (e) {
        console.error('Failed to sync threshold:', e);
    }
}

async function loadInitialThreshold() {
    try {
        const res = await fetch('/api/config/threshold');
        const data = await res.json();
        if (data.threshold !== undefined) {
            const pct = Math.round(data.threshold * 100);
            const input = document.getElementById('threshold-range-input');
            const badge = document.getElementById('threshold-display-badge');
            if (input) input.value = pct;
            if (badge) badge.textContent = `${pct}%`;
            highlightActivePresetPill(data.threshold);
        }
    } catch (e) {
        console.error('Failed to fetch initial threshold:', e);
    }
}

// --- Real-Time Continuous Incident Stream & Toast Alerts ---

function showFloatingThreatToast(incident) {
    const container = document.getElementById('floating-alerts');
    if (!container || !incident) return;

    const toastId = `toast-${incident.id || Date.now()}`;
    if (displayedToastIds.has(toastId)) return;
    displayedToastIds.add(toastId);

    const config = ANIMAL_CONFIGS[incident.animal_type] || { name: incident.animal_type };
    const confPct = Math.round(incident.confidence * 100);

    const toast = document.createElement('div');
    toast.id = toastId;
    toast.className = 'threat-toast';
    toast.innerHTML = `
        <div class="toast-body">
            <div class="toast-header-row">
                <span class="toast-title">${config.name}</span>
                <span class="toast-time mono">${incident.time_str || ''}</span>
            </div>
            <div class="toast-sub">${confPct}% AI Match · Zone A</div>
            <div class="toast-status-pill">Dispatched to Rangers & Tourists</div>
        </div>
    `;

    container.prepend(toast);

    // Auto-remove after 4 seconds
    setTimeout(() => {
        toast.style.opacity = '0';
        toast.style.transform = 'translateX(60px)';
        toast.style.transition = 'all 0.3s ease';
        setTimeout(() => {
            toast.remove();
            displayedToastIds.delete(toastId);
        }, 300);
    }, 4000);
}

function renderIncidentStream(incidents) {
    const feed = document.getElementById('incident-feed');
    const counter = document.getElementById('incident-counter');

    if (!feed) return;
    if (counter) counter.textContent = incidents.length;

    if (!incidents || incidents.length === 0) {
        feed.innerHTML = `
            <div class="incident-empty-state">
                <div class="empty-radar-anim"></div>
                <span class="empty-title">Scanning Forest Perimeter...</span>
                <span class="empty-sub">Surveillance active. Wildlife detections will stream live here.</span>
            </div>
        `;
        return;
    }

    feed.innerHTML = incidents.slice(0, 25).map(inc => {
        const config = ANIMAL_CONFIGS[inc.animal_type] || { name: inc.animal_type };
        const confPct = Math.round(inc.confidence * 100);
        const isDanger = confPct >= 70;
        const iconClass = isDanger ? 'success' : 'muted';
        const iconName = isDanger ? 'pets' : 'flutter_dash';

        return `
            <div class="detection-item">
                <div class="det-icon-box ${iconClass}">
                    <span class="material-symbols-outlined">${iconName}</span>
                </div>
                <div class="det-info">
                    <div class="det-info-row">
                        <h3>${config.name}</h3>
                        <span class="det-time">${inc.time_str || 'Just now'}</span>
                    </div>
                    <div class="det-meta-row">
                        <span class="det-confidence">Confidence: ${confPct}%</span>
                        <button class="det-bookmark"><span class="material-symbols-outlined">bookmark_border</span></button>
                    </div>
                </div>
            </div>
        `;
    }).join('');
}

async function clearIncidentLogs() {
    try {
        await fetch('/api/alerts/clear_history', { method: 'POST' });
        displayedToastIds.clear();
        lastProcessedIncidentId = null;
        renderIncidentStream([]);
        const banner = document.getElementById('tactical-threat-banner');
        if (banner) banner.style.display = 'none';
        await updateSentinelStatus();
    } catch (e) {
        console.error('Failed to clear logs:', e);
    }
}

// --- Threat Matrix State Update ---

function updateThreatMatrix(threatLevel, latestAlert) {
    const indicator = document.getElementById('threat-matrix-indicator');
    const dot = indicator ? indicator.querySelector('.matrix-dot') : null;
    const text = document.getElementById('threat-matrix-text');
    const banner = document.getElementById('tactical-threat-banner');

    if (!threatLevel) return;

    if (threatLevel.level === 'CRITICAL' || threatLevel.level === 'ELEVATED') {
        if (indicator) {
            indicator.style.background = 'rgba(239, 68, 68, 0.15)';
            indicator.style.borderColor = 'rgba(239, 68, 68, 0.4)';
        }
        if (dot) dot.className = `matrix-dot ${threatLevel.level.toLowerCase()}`;
        if (text) {
            text.textContent = `ALERT: ${threatLevel.level} THREAT DETECTED`;
            text.style.color = '#ef4444';
        }

        // Show banner if active
        if (banner && latestAlert) {
            const config = ANIMAL_CONFIGS[latestAlert.animal_type] || { name: latestAlert.animal_type };
            const bannerTitle = document.getElementById('banner-animal-title');
            const bannerDesc = document.getElementById('banner-animal-desc');

            if (bannerTitle) bannerTitle.textContent = `${config.name.toUpperCase()} DETECTED IN ZONE A`;
            if (bannerDesc) bannerDesc.textContent = `${Math.round(latestAlert.confidence * 100)}% match at ${latestAlert.time_str}. Notification automatically broadcasted to all tourists & rangers.`;

            banner.style.display = 'block';
        }
    } else {
        if (indicator) {
            indicator.style.background = 'rgba(16, 185, 129, 0.08)';
            indicator.style.borderColor = 'rgba(16, 185, 129, 0.25)';
        }
        if (dot) dot.className = 'matrix-dot secure';
        if (text) {
            text.textContent = 'PERIMETER SECURE';
            text.style.color = '#10b981';
        }
        if (banner) banner.style.display = 'none';
    }
}

// --- Main Telemetry & Polling Loop ---

async function updateSentinelStatus() {
    try {
        const res = await fetch('/api/status');
        const data = await res.json();
        const isCamOnline = data.camera && data.camera.status === 'online';

        // 1. Header Chips
        const camChipDot = document.querySelector('#chip-cam .chip-dot');
        const camChipText = document.getElementById('chip-cam-text');
        if (camChipDot) camChipDot.className = `chip-dot ${isCamOnline ? 'online' : 'offline'}`;
        if (camChipText) camChipText.textContent = isCamOnline ? 'CAM C-01: LIVE' : 'CAM C-01: OFF';

        // 2. Viewport Header Badges
        const streamBadge = document.getElementById('stream-state-badge');
        if (streamBadge) {
            streamBadge.className = `stream-pill ${isCamOnline ? 'live' : 'offline'}`;
            streamBadge.textContent = isCamOnline ? 'LIVE STREAM' : 'STANDBY';
        }

        const fpsVal = document.getElementById('fps-val');
        if (fpsVal) fpsVal.textContent = isCamOnline ? (data.camera.fps || 0.0).toFixed(1) : '0.0';

        const inferVal = document.getElementById('infer-val');
        if (inferVal) {
            const ms = data.yolo.last_inference_ms || 0;
            inferVal.textContent = ms > 0 ? `${Math.round(ms)}ms` : '--';
        }

        // 3. Hardware Controls
        const masterBtn = document.getElementById('master-cam-toggle-btn');
        const quickBtn = document.getElementById('quick-stream-toggle');
        const quickText = document.getElementById('quick-stream-text');
        const hwIndicator = document.getElementById('hw-status-indicator');

        if (masterBtn) {
            if (isCamOnline) {
                masterBtn.className = 'cam-action-btn stop';
                masterBtn.innerHTML = '<span class="cam-action-icon">⏹</span><span class="cam-action-text">PAUSE SURVEILLANCE</span>';
            } else {
                masterBtn.className = 'cam-action-btn start';
                masterBtn.innerHTML = '<span class="cam-action-icon">▶</span><span class="cam-action-text">START SURVEILLANCE</span>';
            }
        }

        if (quickBtn && quickText) {
            if (isCamOnline) {
                quickBtn.className = 'stream-master-btn stop';
                quickText.textContent = 'STOP';
            } else {
                quickBtn.className = 'stream-master-btn start';
                quickText.textContent = 'START SURVEILLANCE';
            }
        }

        if (hwIndicator) {
            hwIndicator.className = `hw-badge ${isCamOnline ? 'online' : 'offline'}`;
            hwIndicator.textContent = isCamOnline ? 'Active Capturing' : 'Stopped';
        }

        // 4. Telemetry Card Metrics
        const statDetections = document.getElementById('stat-total-detections');
        if (statDetections) statDetections.textContent = data.yolo.total_detections || 0;

        const statAlerts = document.getElementById('stat-dispatched-alerts');
        if (statAlerts) statAlerts.textContent = data.yolo.total_alerts_dispatched || 0;

        const statInfer = document.getElementById('stat-inference-ms');
        if (statInfer) statInfer.textContent = data.yolo.last_inference_ms ? `${Math.round(data.yolo.last_inference_ms)}ms` : '--';

        const statFps = document.getElementById('stat-detection-fps');
        if (statFps) statFps.textContent = isCamOnline ? `${(data.camera.fps || 0.0).toFixed(0)} FPS` : '~30';

        // 5. Threat Matrix & Incidents
        const recentAlerts = data.recent_alerts || [];
        const latestAlert = recentAlerts.length > 0 ? recentAlerts[0] : null;

        updateThreatMatrix(data.threat_level, latestAlert);

        // Process newly detected animal incidents
        if (latestAlert && latestAlert.id !== lastProcessedIncidentId) {
            lastProcessedIncidentId = latestAlert.id;
            showFloatingThreatToast(latestAlert);
            playWildlifeAlertChime(latestAlert.animal_type);
            sendDesktopNotification(latestAlert.animal_type, Math.round(latestAlert.confidence * 100), latestAlert.time_str);
        }

        renderIncidentStream(recentAlerts);

    } catch (e) {
        console.error('Sentinel polling failed:', e);
    }
}

// --- Utilities: Clock, Snapshot, Video Filters, Fullscreen ---

function updateClock() {
    const now = new Date();
    const timeStr = now.toLocaleTimeString('en-US', { hour12: false });
    const clock = document.getElementById('clock-val');
    if (clock) clock.textContent = timeStr;
}

function setVideoFilter(filterName) {
    const container = document.getElementById('video-screen-container');
    const buttons = document.querySelectorAll('.filter-btn');

    if (!container) return;
    container.classList.remove('filter-night-vision', 'filter-contrast');

    if (filterName === 'night-vision') {
        container.classList.add('filter-night-vision');
    } else if (filterName === 'contrast') {
        container.classList.add('filter-contrast');
    }

    buttons.forEach(btn => {
        if (btn.textContent.toLowerCase().includes(filterName.replace('-', ' '))) {
            btn.classList.add('active');
        } else {
            btn.classList.remove('active');
        }
    });
}

function takeSnapshot() {
    window.open('/api/camera/snapshot', '_blank');
}

function toggleFullscreen() {
    const container = document.getElementById('video-screen-container');
    if (!container) return;

    if (!document.fullscreenElement) {
        container.requestFullscreen().catch(err => {
            console.warn(`Error attempting fullscreen: ${err.message}`);
        });
    } else {
        document.exitFullscreen();
    }
}

// --- Initialization ---

document.addEventListener('DOMContentLoaded', () => {
    updateClock();
    loadInitialThreshold();
    updateSentinelStatus();

    // Check existing notification permissions
    if ('Notification' in window && Notification.permission === 'granted') {
        const btn = document.getElementById('notif-btn');
        const label = document.getElementById('notif-label');
        if (btn) {
            btn.style.borderColor = 'rgba(16, 185, 129, 0.5)';
            btn.style.color = '#34d399';
        }
        if (label) label.textContent = 'Active';
    }

    // Audio context on first user gesture
    document.addEventListener('click', initAudioContext, { once: true });

    // Status polling every 1 second for ultra-responsive live detection stream
    setInterval(updateSentinelStatus, 1000);
    // Clock every 1 second
    setInterval(updateClock, 1000);
});
