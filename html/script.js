// ══════════════════════════════════════════════════════════
//  الفرسان RP — HUD + Tablet + Carplay + Phone
// ══════════════════════════════════════════════════════════
const $ = (id) => document.getElementById(id);
const resourceName = () => (typeof GetParentResourceName === 'function') ? GetParentResourceName() : 'fivem-strict-rp';
function post(ep, data) {
    return fetch(`https://${resourceName()}/${ep}`, {
        method: 'POST', headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data || {}),
    }).catch(() => {});
}

const jailEl = $('jail'), timerEl = $('timer'), reasonEl = $('reason');
const needsEl = $('needs'), weatherEl = $('weather'), weatherTx = $('weather-text');
const bars = { hunger: $('bar-hunger'), thirst: $('bar-thirst'), energy: $('bar-energy'), hygiene: $('bar-hygiene') };
const toastEl = $('toast');

const modalEl = $('modal'), modalTitle = $('modal-title'), modalBody = $('modal-body'), modalFoot = $('modal-foot');
let modalOpen = false, currentAction = null;

function openModal(data) {
    modalOpen = true;
    currentAction = data.callback || null;
    modalTitle.textContent = data.title || 'القائمة';
    modalFoot.textContent = data.foot || '';
    modalBody.innerHTML = '';
    (data.items || []).forEach((it) => {
        const card = document.createElement('div');
        card.className = 'card' + (it.disabled ? ' disabled' : '');
        card.innerHTML = `<div class="c-title">${it.title || ''}</div><div class="c-sub">${it.sub || ''}</div>` +
            (it.price != null ? `<div class="c-price">$${it.price}</div>` : '');
        if (!it.disabled) card.addEventListener('click', () => {
            post('ui:select', { id: it.id, callback: currentAction });
            closeModal();
        });
        modalBody.appendChild(card);
    });
    modalEl.classList.remove('hidden');
}
function closeModal() { modalEl.classList.add('hidden'); modalOpen = false; post('ui:close'); }
$('modal-close').addEventListener('click', closeModal);
modalEl.addEventListener('click', (e) => { if (e.target === modalEl) closeModal(); });

// ══ التابلت ══
const tabletEl = $('tablet'), appGrid = $('app-grid'), appContent = $('app-content');
let tabletOpen = false, tabletData = { jobs: [], businesses: [], crops: [] };
const APPS = [
    { id: 'jobs', ico: '💼', label: 'الوظائف' }, { id: 'business', ico: '🏢', label: 'الأعمال' },
    { id: 'farm', ico: '🌾', label: 'المزرعة' }, { id: 'dealer', ico: '🚗', label: 'المعارض' },
    { id: 'mechanic', ico: '🔧', label: 'الورشة' },
];
function openTablet(data) {
    if (data) tabletData = { jobs: data.jobs || [], businesses: data.businesses || [], crops: data.crops || [] };
    if (data && data.cash != null) $('tab-cash').textContent = '$' + data.cash;
    if (data && data.bank != null) $('tab-bank').textContent = '$' + data.bank;
    tabletOpen = true;
    appGrid.innerHTML = '';
    APPS.forEach((app) => {
        const b = document.createElement('div');
        b.className = 'app-btn'; b.dataset.app = app.id;
        b.innerHTML = `<span class="app-ico">${app.ico}</span>${app.label}`;
        b.addEventListener('click', () => selectApp(app.id));
        appGrid.appendChild(b);
    });
    appContent.innerHTML = '<div class="app-empty">👆 اختر تطبيقاً من القائمة</div>';
    tabletEl.classList.remove('hidden');
}
function closeTablet() { tabletOpen = false; tabletEl.classList.add('hidden'); post('tablet:close'); }
function selectApp(appId) {
    document.querySelectorAll('.app-btn').forEach(b => b.classList.toggle('active', b.dataset.app === appId));
    $('tab-view-title').textContent = (APPS.find(a => a.id === appId) || {}).label || 'التطبيق';
    if (appId === 'jobs') renderAppList(tabletData.jobs.map(j => ({ id: j.id, title: `${j.icon || ''} ${j.label}`, sub: 'اضغط للتوظيف', app: 'jobs' })));
    else if (appId === 'business') renderAppList(tabletData.businesses.map(b => ({ id: b.id, title: `${b.icon || ''} ${b.label}`, sub: `السعر: $${b.price}`, app: 'business' })));
    else if (appId === 'farm') renderAppList(tabletData.crops.map(c => ({ id: c.id, title: c.label, sub: `ينمو ${c.grow} دقيقة · بيع $${c.sell}`, app: 'farm' })));
    else if (appId === 'dealer') renderAppList([
        { id: 'city', title: 'معرض المدينة', sub: 'اقتصادي · عائلي', app: 'dealer' },
        { id: 'luxury', title: 'معرض الفخامة', sub: 'رياضي · فخم', app: 'dealer' },
        { id: 'industrial', title: 'معرض الصناعي', sub: 'صناعي · خدمي', app: 'dealer' },
    ]);
    else if (appId === 'mechanic') renderAppList([{ id: 'garages', title: 'ورش الصيانة', sub: 'افتح قائمة الخدمات', app: 'mechanic' }]);
}
function renderAppList(items) {
    appContent.innerHTML = '';
    if (!items.length) { appContent.innerHTML = '<div class="app-empty">لا يوجد محتوى</div>'; return; }
    const wrap = document.createElement('div'); wrap.className = 'app-list';
    items.forEach((it) => {
        const el = document.createElement('div'); el.className = 'app-item';
        el.innerHTML = `<div class="ai-title">${it.title}</div><div class="ai-sub">${it.sub || ''}</div>`;
        el.addEventListener('click', () => { post('tablet:action', { app: it.app, id: it.id }); closeTablet(); });
        wrap.appendChild(el);
    });
    appContent.appendChild(wrap);
}
$('tablet-close').addEventListener('click', closeTablet);
tabletEl.addEventListener('click', (e) => { if (e.target === tabletEl) closeTablet(); });

// ══ الكار بلاي ══
const carplayEl = $('carplay');
let carplayOpen = false, autopilotOn = false, cruiseOn = false;
function openCarplay(data) {
    carplayOpen = true;
    $('cp-plate').textContent = data.plate || '---';
    if (data.vehData) {
        $('cp-fuel').textContent = '⛽ ' + Math.floor(data.vehData.fuel || 0) + '%';
        $('cp-speed').textContent = '🏁 ' + (data.vehData.speed || 0) + ' كم/س';
    }
    const st = $('cp-stations'); st.innerHTML = '';
    (data.stations || []).forEach((s) => {
        const el = document.createElement('div');
        el.className = 'cp-station'; el.dataset.sid = s.id;
        el.innerHTML = `<div class="cs-freq">${s.freq} FM</div><div class="cs-label">${s.label}</div>`;
        el.addEventListener('click', () => {
            document.querySelectorAll('.cp-station').forEach(x => x.classList.remove('active'));
            el.classList.add('active');
            post('carplay:action', { action: 'station', stationId: s.id });
        });
        st.appendChild(el);
    });
    const cg = $('cp-controls'); cg.innerHTML = '';
    const ctrls = data.controls || {};
    Object.keys(ctrls).forEach((k) => {
        if (k === 'autopilot' || k === 'cruise') return;
        const el = document.createElement('div');
        el.className = 'cp-control'; el.dataset.ctrl = k;
        el.innerHTML = `<span class="cc-ico">${ctrls[k].icon}</span>${ctrls[k].label}`;
        el.addEventListener('click', () => {
            const act = (k === 'camera') ? 'cam' : (k === 'hazards') ? 'hazards' : k;
            if (act === 'cam') post('carplay:cam', {});
            else if (act === 'hazards') { el.classList.toggle('on'); post('carplay:action', { action: 'hazards', state: el.classList.contains('on') }); }
            else post('carplay:action', { action: act });
        });
        cg.appendChild(el);
    });
    const nav = $('cp-nav-list'); nav.innerHTML = '';
    ['المستشفى', 'مركز الشرطة', 'المنجم', 'المزرعة', 'المعارض'].forEach((label) => {
        const el = document.createElement('div'); el.className = 'cp-station';
        el.innerHTML = `<div class="cs-label">🗺️ ${label}</div>`;
        el.addEventListener('click', () => post('carplay:action', { action: 'nav', x: 0, y: 0, z: 0, label }));
        nav.appendChild(el);
    });
    $('cp-vehstatus').innerHTML = '';
    carplayEl.classList.remove('hidden');
}
function closeCarplay() { carplayOpen = false; carplayEl.classList.add('hidden'); post('carplay:close'); }
document.querySelectorAll('.cp-tab').forEach((tab) => {
    tab.addEventListener('click', () => {
        document.querySelectorAll('.cp-tab').forEach(t => t.classList.remove('active'));
        document.querySelectorAll('.cp-panel').forEach(p => p.classList.remove('active'));
        tab.classList.add('active');
        $('cp-panel-' + tab.dataset.cptab).classList.add('active');
    });
});
$('cp-volume').addEventListener('input', (e) => {
    $('cp-vol-val').textContent = e.target.value + '%';
    post('carplay:action', { action: 'volume', volume: e.target.value });
});
$('cp-autopilot').addEventListener('click', function () {
    autopilotOn = !autopilotOn;
    this.classList.toggle('on', autopilotOn);
    $('cp-auto-status').textContent = autopilotOn ? '🤖 القيادة الذاتية تعمل...' : '';
    post('carplay:action', { action: 'autopilot' });
});
$('cp-cruise').addEventListener('click', function () {
    cruiseOn = !cruiseOn;
    this.classList.toggle('on', cruiseOn);
    $('cp-auto-status').textContent = cruiseOn ? '🎯 تثبيت السرعة نشط — ↑↓ للتحكم' : '';
    post('carplay:action', { action: 'cruise' });
});
$('carplay-close').addEventListener('click', closeCarplay);
carplayEl.addEventListener('click', (e) => { if (e.target === carplayEl) closeCarplay(); });

// ══ الجوال ══
const phoneEl = $('phone'), phHome = $('ph-home'), phApp = $('ph-app'), phAppBody = $('ph-app-body'), phAppTitle = $('ph-app-title');
let phoneOpen = false, currentPhoneApp = null;
function openPhone(data) {
    phoneOpen = true;
    phHome.innerHTML = '';
    (data.apps ? Object.keys(data.apps) : []).forEach((k) => {
        const a = data.apps[k];
        const el = document.createElement('div'); el.className = 'ph-app-icon';
        el.innerHTML = `<div class="pai-ico">${a.icon}</div><div class="pai-label">${a.label}</div>`;
        el.addEventListener('click', () => openPhoneApp(k, a));
        phHome.appendChild(el);
    });
    phApp.classList.add('hidden');
    phoneEl.classList.remove('hidden');
}
function openPhoneApp(key, app) {
    currentPhoneApp = key;
    phAppTitle.textContent = app.label;
    phApp.classList.remove('hidden');
    phAppBody.innerHTML = '<div class="app-empty" style="margin-top:20px">جاري التحميل...</div>';
    if (key === 'absher') post('phone:action', { app: 'absher', action: 'docs' });
    else if (key === 'najiz') post('phone:action', { app: 'najiz' });
    else if (key === 'meda') post('phone:action', { app: 'meda', action: 'list' });
    else if (key === 'mazadi') post('phone:action', { app: 'mazadi', action: 'list' });
    else if (key === 'atlobni') post('phone:action', { app: 'atlobni', action: 'list' });
}
function closePhone() { phoneOpen = false; phoneEl.classList.add('hidden'); post('phone:close'); }
$('ph-back').addEventListener('click', () => { phApp.classList.add('hidden'); });
$('ph-homebar').addEventListener('click', closePhone);
function phoneList(items) {
    phAppBody.innerHTML = '';
    if (!items.length) { phAppBody.innerHTML = '<div class="app-empty" style="margin-top:20px">لا يوجد محتوى</div>'; return; }
    items.forEach((it) => {
        const el = document.createElement('div'); el.className = 'ph-item';
        el.innerHTML = `<div class="pi-title">${it.title}</div><div class="pi-sub">${it.sub || ''}</div>`;
        if (it.onclick) el.addEventListener('click', it.onclick);
        phAppBody.appendChild(el);
    });
}

// ══ استقبال الأحداث ══
window.addEventListener('message', (e) => {
    const d = e.data || {};
    if (d.action === 'jailCountdown') { jailEl.classList.remove('hidden'); timerEl.textContent = d.time || '00:00'; reasonEl.textContent = d.reason || ''; }
    if (d.action === 'jailEnd') jailEl.classList.add('hidden');
    if (d.action === 'updateNeeds') {
        needsEl.classList.remove('hidden');
        for (const k of Object.keys(bars)) { const v = Math.max(0, Math.min(100, Number(d[k]) || 0)); if (bars[k]) bars[k].style.width = v + '%'; }
    }
    if (d.action === 'setWeather') { weatherEl.classList.remove('hidden'); weatherTx.textContent = d.weather || 'CLEAR'; }
    if (d.action === 'openModal') openModal(d);
    if (d.action === 'closeModal') closeModal();
    if (d.action === 'tabletOpen') openTablet(d);
    if (d.action === 'tabletClose') closeTablet();
    if (d.action === 'carplayOpen') openCarplay(d);
    if (d.action === 'carplayClose') closeCarplay();
    if (d.action === 'carplayStation') document.querySelectorAll('.cp-station').forEach(x => x.classList.toggle('active', x.dataset.sid == d.station.id));
    if (d.action === 'carplayVolume') { const v = $('cp-volume'); if (v) { v.value = d.volume; $('cp-vol-val').textContent = d.volume + '%'; } }
    if (d.action === 'carplayStatus') {
        const s = d.status || {};
        $('cp-vehstatus').innerHTML =
            `<div class="vs-row"><span>المكينة</span><div class="vs-bar"><div class="vs-fill" style="width:${Math.max(0,100 - (s.wear||0))}%"></div></div></div>` +
            `<div class="vs-row"><span>الزيت</span><b>${Math.floor(s.kmSinceOil||0)} كم</b></div>` +
            `<div class="vs-row"><span>العداد</span><b>${Math.floor(s.odometer||0)} كم</b></div>`;
    }
    if (d.action === 'phoneOpen') openPhone(d);
    if (d.action === 'phoneClose') closePhone();
    if (d.action === 'phonePanel') renderPhonePanel(d);
    if (d.action === 'toast') { toastEl.textContent = d.text || ''; toastEl.classList.remove('hidden'); setTimeout(() => toastEl.classList.add('hidden'), 2500); }
});

function renderPhonePanel(d) {
    if (d.screen === 'absher_docs') {
        const rows = d.rows || [];
        phoneList(rows.length ? rows.map(r => ({ title: (d.types && d.types[r.type] ? d.types[r.type].label : r.type), sub: 'وثيقة رسمية' })) : [{ title: 'لا وثائق', sub: 'لم تُصدر أي وثيقة بعد' }]);
    }
    else if (d.screen === 'absher_fines') phoneList((d.rows || []).map(r => ({ title: r.label, sub: `$${r.amount} · ${r.status}` })));
    else if (d.screen === 'najiz') {
        const items = [];
        (d.contracts || []).forEach(c => items.push({ title: '📜 ' + c.title, sub: `عقد #${c.id} · ${c.status}` }));
        (d.cases || []).forEach(c => items.push({ title: '⚖️ ' + c.title, sub: `قضية #${c.id} · ${c.status}` }));
        phoneList(items);
    }
    else if (d.screen === 'meda') phoneList((d.terminals || []).map(t => ({ title: t.name, sub: `مرتبط بـ ${t.linked_to || '—'}` })));
    else if (d.screen === 'mazadi') phoneList((d.auctions || []).map(a => ({ title: '🔨 ' + a.title, sub: `أعلى مزايدة $${a.high_bid}` })));
    else if (d.screen === 'atlebni') phoneList((d.orders || []).map(o => ({ title: '📢 ' + o.title, sub: `${o.qty} وحدة · ميزانية $${o.budget}` })));
}

document.addEventListener('keyup', (e) => {
    if (e.key !== 'Escape') return;
    if (modalOpen) closeModal();
    else if (tabletOpen) closeTablet();
    else if (carplayOpen) closeCarplay();
    else if (phoneOpen) closePhone();
});

setInterval(() => {
    const d = new Date();
    const t = d.getHours().toString().padStart(2, '0') + ':' + d.getMinutes().toString().padStart(2, '0');
    if ($('tab-clock')) $('tab-clock').textContent = t;
    if ($('ph-time')) $('ph-time').textContent = t;
}, 30000);
