// fivem-strict-rp :: html/script.js
// واجهة السجن + HUD الاحتياجات + شارة الطقس.

const jailEl    = document.getElementById('jail');
const timerEl   = document.getElementById('timer');
const reasonEl  = document.getElementById('reason');
const needsEl   = document.getElementById('needs');
const weatherEl = document.getElementById('weather');
const weatherTx = document.getElementById('weather-text');

const bars = {
    hunger:  document.getElementById('bar-hunger'),
    thirst:  document.getElementById('bar-thirst'),
    energy:  document.getElementById('bar-energy'),
    hygiene: document.getElementById('bar-hygiene'),
};

window.addEventListener('message', (event) => {
    const data = event.data || {};

    if (data.action === 'jailCountdown') {
        jailEl.classList.remove('hidden');
        timerEl.textContent = data.time || '00:00';
        reasonEl.textContent = data.reason || '';
    }

    if (data.action === 'jailEnd') {
        jailEl.classList.add('hidden');
    }

    if (data.action === 'updateNeeds') {
        needsEl.classList.remove('hidden');
        for (const key of Object.keys(bars)) {
            const v = Math.max(0, Math.min(100, Number(data[key]) || 0));
            bars[key].style.width = v + '%';
        }
    }

    if (data.action === 'setWeather') {
        weatherEl.classList.remove('hidden');
        weatherTx.textContent = data.weather || 'CLEAR';
    }
});
