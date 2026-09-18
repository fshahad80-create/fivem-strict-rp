// fivem-strict-rp :: html/script.js
// واجهة السجن + HUD الاحتياجات + الطقس + النوافذ العامة + التابلت.

const $ = (id) => document.getElementById(id);
const jailEl = $('jail'), timerEl = $('timer'), reasonEl = $('reason');
const needsEl = $('needs'), weatherEl = $('weather'), weatherTx = $('weather-text');
const modalEl = $('modal'), modalTitle = $('modal-title'), modalBody = $('modal-body'), modalFoot = $('modal-foot');
const tabletEl = $('tablet'), appGrid = $('app-grid'), appContent = $('app-content');
const toastEl = $('toast');

const bars = {
    hunger:  $('bar-hunger'),
    thirst:  $('bar-thirst'),
    energy:  $('bar-energy'),
    hygiene: $('bar-hygiene'),
};

let modalOpen = false, tabletOpen = false, currentAction = null;
let tabletData = { jobs: [], businesses: [], crops: [] };

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
    if (data.action === 'tabletOpen') {
        tabletData = { jobs: data.jobs || [], businesses: data.businesses || [], crops: data.crops || [] };
        openTablet();
    }
    if (data.action === 'tabletClose') closeTablet();
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

const APPS = [
    { id: 'jobs',     ico: '💼', label: 'الوظائف' },
    { id: 'business', ico: '🏢', label: 'الأعمال' },
    { id: 'farm',     ico: '🌾', label: 'المزرعة' },
    { id: 'dealer',   ico: '🚗', label: 'المعارض' },
    { id: 'mechanic', ico: '🔧', label: 'الورشة' },
];

function openTablet() {
    tabletOpen = true;
    appGrid.innerHTML = '';
    APPS.forEach((app) => {
        const btn = document.createElement('div');
        btn.className = 'app-btn';
        btn.dataset.app = app.id;
        btn.innerHTML = `<span class="app-ico">${app.ico}</span>${app.label}`;
        btn.addEventListener('click', () => selectApp(app.id));
        appGrid.appendChild(btn);
    });
    appContent.innerHTML = '<div class="app-empty">اختر تطبيقاً من الأعلى</div>';
    tabletEl.classList.remove('hidden');
}

function closeTablet() {
    tabletOpen = false;
    tabletEl.classList.add('hidden');
    post('tablet:close');
}

function selectApp(appId) {
    document.querySelectorAll('.app-btn').forEach(b => b.classList.toggle('active', b.dataset.app === appId));
    if (appId === 'jobs') {
        renderList(tabletData.jobs.map(j => ({ id: j.id, title: `${j.icon || ''} ${j.label}`, sub: 'اضغط للتوظيف', app: 'jobs' })));
    } else if (appId === 'business') {
        renderList(tabletData.businesses.map(b => ({ id: b.id, title: `${b.icon || ''} ${b.label}`, sub: `السعر: $${b.price}`, app: 'business' })));
    } else if (appId === 'farm') {
        renderList(tabletData.crops.map(c => ({ id: c.id, title: `${c.label}`, sub: `ينمو ${c.grow} دقيقة · بيع $${c.sell}`, app: 'farm' })));
    } else if (appId === 'dealer') {
        renderList([{ id: 'city', title: 'معرض المدينة', sub: 'اقتصادي · عائلي', app: 'dealer' },
                    { id: 'luxury', title: 'معرض الفخامة', sub: 'رياضي · فخم', app: 'dealer' },
                    { id: 'industrial', title: 'معرض الصناعي', sub: 'صناعي · خدمي', app: 'dealer' }]);
    } else if (appId === 'mechanic') {
        renderList([{ id: 'garages', title: 'ورش الصيانة', sub: 'افتح قائمة الخدمات', app: 'mechanic' }]);
    }
}

function renderList(items) {
    appContent.innerHTML = '';
    if (!items.length) { appContent.innerHTML = '<div class="app-empty">لا يوجد محتوى</div>'; return; }
    const wrap = document.createElement('div');
    wrap.className = 'app-list';
    items.forEach((it) => {
        const el = document.createElement('div');
        el.className = 'app-item';
        el.innerHTML = `<div class="ai-title">${it.title}</div><div class="ai-sub">${it.sub || ''}</div>`;
        el.addEventListener('click', () => { post('tablet:action', { app: it.app, id: it.id }); closeTablet(); });
        wrap.appendChild(el);
    });
    appContent.appendChild(wrap);
}

$('modal-close').addEventListener('click', closeModal);
$('tablet-close').addEventListener('click', closeTablet);
document.addEventListener('keyup', (e) => {
    if (e.key === 'Escape') { if (modalOpen) closeModal(); else if (tabletOpen) closeTablet(); }
});
modalEl.addEventListener('click', (e) => { if (e.target === modalEl) closeModal(); });
tabletEl.addEventListener('click', (e) => { if (e.target === tabletEl) closeTablet(); });
