// fivem-strict-rp :: html/script.js
// واجهة السجن + HUD الاحتياجات + الطقس + النوافذ العامة.

const $ = (id) => document.getElementById(id);
const jailEl = $('jail'), timerEl = $('timer'), reasonEl = $('reason');
const needsEl = $('needs'), weatherEl = $('weather'), weatherTx = $('weather-text');
const modalEl = $('modal'), modalTitle = $('modal-title'), modalBody = $('modal-body'), modalFoot = $('modal-foot');
const toastEl = $('toast');

const bars = {
    hunger:  $('bar-hunger'),
    thirst:  $('bar-thirst'),
    energy:  $('bar-energy'),
    hygiene: $('bar-hygiene'),
};

let modalOpen = false;
let currentAction = null;

function resourceName() { return (typeof GetParentResourceName === 'function') ? GetParentResourceName() : 'fivem-strict-rp'; }
function post(endpoint, data) {
    return fetch(`https://${resourceName()}/${endpoint}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data || {}),
    }).catch(() => {});
}

function closeModal() {
    modalEl.classList.add('hidden');
    modalOpen = false;
    post('ui:close');
}

window.addEventListener('message', (event) => {
    const data = event.data || {};

    if (data.action === 'jailCountdown') {
        jailEl.classList.remove('hidden');
        timerEl.textContent = data.time || '00:00';
        reasonEl.textContent = data.reason || '';
    }
    if (data.action === 'jailEnd') jailEl.classList.add('hidden');

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

    if (data.action === 'openModal') openModal(data);
    if (data.action === 'closeModal') closeModal();

    if (data.action === 'toast') {
        toastEl.textContent = data.text || '';
        toastEl.classList.remove('hidden');
        setTimeout(() => toastEl.classList.add('hidden'), 2500);
    }
});

function openModal(data) {
    modalOpen = true;
    currentAction = data.callback || null;
    modalTitle.textContent = data.title || 'القائمة';
    modalFoot.textContent = data.foot || '';
    modalBody.innerHTML = '';

    (data.items || []).forEach((it) => {
        const card = document.createElement('div');
        card.className = 'card' + (it.disabled ? ' disabled' : '');
        card.innerHTML = `
            <div class="c-title">${it.title || ''}</div>
            <div class="c-sub">${it.sub || ''}</div>
            ${it.price != null ? `<div class="c-price">$${it.price}</div>` : ''}
            ${it.stock != null ? `<div class="c-stock">المتوفر: ${it.stock}</div>` : ''}
        `;
        if (!it.disabled) {
            card.addEventListener('click', () => {
                post('ui:select', { id: it.id, callback: currentAction });
                closeModal();
            });
        }
        modalBody.appendChild(card);
    });

    modalEl.classList.remove('hidden');
}

$('modal-close').addEventListener('click', closeModal);
document.addEventListener('keyup', (e) => { if (e.key === 'Escape' && modalOpen) closeModal(); });
modalEl.addEventListener('click', (e) => { if (e.target === modalEl) closeModal(); });
