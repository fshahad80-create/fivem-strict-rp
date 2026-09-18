const jailEl   = document.getElementById('jail');
const timerEl  = document.getElementById('timer');
const reasonEl = document.getElementById('reason');

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
});
