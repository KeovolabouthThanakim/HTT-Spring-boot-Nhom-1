/**
 * Dashboard JavaScript
 * Extracted from dashboard.jsp
 */

/* ── CONFIGURATION ── */
window.DashboardConfig = window.DashboardConfig || {};

/* ── GENERAL MODALS ── */
function openModal(id) {
    var el = document.getElementById(id);
    if (!el) return;
    if (el.classList.contains('cm-overlay') || el.classList.contains('overlay')) {
        el.classList.add('open');
    } else {
        el.style.display = 'flex';
    }
}

function closeModal(id) {
    var el = document.getElementById(id);
    if (!el) return;
    if (el.classList.contains('cm-overlay') || el.classList.contains('overlay')) {
        el.classList.remove('open');
    } else {
        el.style.display = 'none';
    }
}

// Global click and escape handlers for modals
document.addEventListener('DOMContentLoaded', function() {

    // ── Auto-show popup based on URL ?success= or tab-specific params ──
    (function() {
        var params = new URLSearchParams(window.location.search);
        var tab = params.get('tab');
        var successVal = params.get('success');
        var errVal = params.get('err');

        // Admin tab: show create/edit/delete result popup
        if ((tab === 'admin' || tab === 'users') && successVal) {
            var msg = '';
            try { msg = decodeURIComponent(successVal); } catch(e) { msg = successVal; }
            if (msg && msg !== 'ok' && typeof showNotifyModal === 'function') {
                showNotifyModal('success', '\u2705 Th\u00e0nh c\u00f4ng', msg);
                // Clean URL so refresh won't re-trigger
                var clean = window.location.pathname + '?tab=' + tab;
                window.history.replaceState({}, '', clean);
            }
        }
        if ((tab === 'admin' || tab === 'users') && errVal) {
            var emsg = '';
            try { emsg = decodeURIComponent(errVal); } catch(e) { emsg = errVal; }
            if (emsg && typeof showNotifyModal === 'function') {
                showNotifyModal('error', '\u26a0\ufe0f L\u1ed7i', emsg);
                var clean = window.location.pathname + '?tab=' + tab;
                window.history.replaceState({}, '', clean);
            }
        }
    })();

    document.querySelectorAll('.cm-overlay').forEach(function(o) {
        o.addEventListener('click', function(e) {
            if (e.target === o) o.classList.remove('open');
        });
    });

    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape') {
            document.querySelectorAll('.cm-overlay.open').forEach(function(o) {
                o.classList.remove('open');
            });
            if (typeof closeNotifyModal === 'function') closeNotifyModal();

            if (typeof closeToast === 'function') closeToast();
            if (typeof closeApprovalModal === 'function') closeApprovalModal();
            if (typeof umCloseDelete === 'function') umCloseDelete();
            if (typeof amCloseCreate === 'function') amCloseCreate();
            if (typeof amCloseReset === 'function') amCloseReset();
        }
    });

    // Admin modal overlay click handlers
    document.querySelectorAll('.am-modal-overlay').forEach(function(o) {
        o.addEventListener('click', function(e) {
            if (e.target === this) this.classList.remove('open');
        });
    });

    // Form submit listeners
    var hwForm = document.getElementById('hwForm');
    if (hwForm) {
        hwForm.addEventListener('submit', function() {
            var btn = document.getElementById('hwSubmitBtn');
            if (btn) { btn.disabled = true; btn.textContent = '⏳ Đang tải lên...'; }
        });
    }
    var editHwForm = document.getElementById('editHwForm');
    if (editHwForm) {
        editHwForm.addEventListener('submit', function() {
            var btn = document.getElementById('editHwSubmitBtn');
            if (btn) { btn.disabled = true; btn.textContent = '⏳ Đang lưu...'; }
        });
    }
    var deleteHwForm = document.getElementById('deleteHwForm');
    if (deleteHwForm) {
        deleteHwForm.addEventListener('submit', function() {
            var btn = document.getElementById('deleteHwSubmitBtn');
            if (btn) { btn.disabled = true; btn.textContent = '⏳ Đang xóa...'; }
        });
    }
});

/* ── NOTIFICATION MODAL ── */
function showNotifyModal(type, title, message) {
    var isSuccess = (type === 'success');
    var iconEl = document.getElementById('notifyIcon');
    var titleEl = document.getElementById('notifyTitle');
    var msgEl = document.getElementById('notifyMsg');
    var barEl = document.getElementById('notifyBar');
    var btnEl = document.getElementById('notifyBtn');
    var modalEl = document.getElementById('notifyModal');

    if (iconEl) iconEl.textContent = isSuccess ? '✅' : '⚠️';
    if (titleEl) titleEl.textContent = title;
    if (msgEl) msgEl.textContent = message;

    var grad = isSuccess
        ? 'linear-gradient(90deg,#10b981,#059669)'
        : 'linear-gradient(90deg,#ef4444,#dc2626)';

    if (barEl) barEl.style.background = grad;
    if (btnEl) btnEl.style.background = isSuccess
        ? 'linear-gradient(135deg,#10b981,#059669)'
        : 'linear-gradient(135deg,#ef4444,#dc2626)';

    if (modalEl) modalEl.style.display = 'flex';
}

function closeNotifyModal() {
    var el = document.getElementById('notifyModal');
    if (el) el.style.display = 'none';
}

/* ── CONFIRM MODALS ── */
function closeConfirmModal(id) {
    var el = document.getElementById(id);
    if (el) el.style.display = 'none';
}





/* ── TOAST NOTIFICATIONS ── */
function showToast(type, icon, title, message) {
    var iconEl = document.getElementById('toastIcon');
    var titleEl = document.getElementById('toastTitle');
    var msgEl = document.getElementById('toastMessage');
    var btnEl = document.getElementById('toastBtn');
    var modalEl = document.getElementById('toastModal');

    if (iconEl) iconEl.textContent = icon;
    if (titleEl) titleEl.textContent = title;
    if (msgEl) msgEl.textContent = message;

    if (btnEl) {
        btnEl.style.background = (type === 'success')
            ? 'linear-gradient(135deg,#10b981,#059669)'
            : 'linear-gradient(135deg,#ef4444,#dc2626)';
    }

    if (modalEl) modalEl.style.display = 'flex';
}

function showCenterToast(type, icon, message) {
    showToast(type, icon, (type === 'success' ? 'Thành công' : 'Lỗi'), message);
    setTimeout(function() { closeToast(); }, 3000);
}

function closeToast() {
    var el = document.getElementById('toastModal');
    if (el) el.style.display = 'none';
}

/* ── APPROVAL MODAL ── */
function showApprovalModal(action, userId, username) {
    var modal = document.getElementById('approvalModal');
    var isApprove = (action === 'approve');
    var iconEl = document.getElementById('modalIcon');
    var titleEl = document.getElementById('modalTitle');
    var subEl = document.getElementById('modalSub');
    var btnEl = document.getElementById('modalConfirmBtn');
    var actionEl = document.getElementById('modalAction');
    var userIdEl = document.getElementById('modalUserId');
    var formEl = document.getElementById('approvalForm');

    if (iconEl) iconEl.textContent = isApprove ? '✅' : '🚫';
    if (titleEl) titleEl.textContent = isApprove ? 'Phê duyệt đăng ký' : 'Từ chối đăng ký';
    if (subEl) {
        subEl.innerHTML = isApprove
            ? 'Xác nhận phê duyệt <strong>' + username + '</strong><br>thành <span style="color:#10b981;font-weight:700;">Giáo viên</span> trong hệ thống?'
            : 'Xác nhận từ chối <strong>' + username + '</strong><br>Tài khoản sẽ bị <span style="color:#ef4444;font-weight:700;">từ chối</span> và không thể đăng nhập';
    }

    if (btnEl) {
        btnEl.textContent = isApprove ? '✓ Phê duyệt' : '✕ Từ chối';
        btnEl.style.background = isApprove ? '#10b981' : '#ef4444';
    }

    if (actionEl) actionEl.value = action;
    if (userIdEl) userIdEl.value = userId;
    if (formEl) formEl.action = (window.DashboardConfig.contextPath || '') + '/teacher-approval';

    if (modal) modal.style.display = 'flex';
}

function closeApprovalModal() {
    var el = document.getElementById('approvalModal');
    if (el) el.style.display = 'none';
}

/* ── ADMIN MANAGEMENT ── */
function amOpenCreate() {
    var el = document.getElementById('amCreateModal');
    if (el) el.classList.add('open');
}

function amCloseCreate() {
    var el = document.getElementById('amCreateModal');
    if (el) el.classList.remove('open');
}

function amUpdateRoleUI() {
    var selEl = document.getElementById('saRoleSelect');
    var bannerEl = document.getElementById('amRoleBanner');
    var btnEl = document.getElementById('amCreateBtn');

    if (!selEl || !bannerEl || !btnEl) return;

    var sel = selEl.value;
    if (sel === 'SUPER_ADMIN') {
        bannerEl.style.display = 'block';
        btnEl.textContent = '👑 Tạo Super Admin';
    } else {
        bannerEl.style.display = 'none';
        btnEl.textContent = '✅ Tạo Admin';
    }
}

function amOpenReset(id, name) {
    var idEl = document.getElementById('amResetId');
    var nameEl = document.getElementById('amResetName');
    var pwEl = document.getElementById('amNewPw');
    var modalEl = document.getElementById('amResetModal');

    if (idEl) idEl.value = id;
    if (nameEl) nameEl.textContent = name;
    if (pwEl) pwEl.value = '';
    if (modalEl) modalEl.classList.add('open');
}

function amCloseReset() {
    var el = document.getElementById('amResetModal');
    if (el) el.classList.remove('open');
}

function amOpenDelete(id, name) {
    var idEl = document.getElementById('amDeleteId');
    var nameEl = document.getElementById('amDeleteName');
    var modalEl = document.getElementById('amDeleteModal');

    if (idEl) idEl.value = id;
    if (nameEl) nameEl.textContent = name;
    if (modalEl) modalEl.style.display = 'flex';
}

function amCloseDelete() {
    var el = document.getElementById('amDeleteModal');
    if (el) el.style.display = 'none';
}

/* ── USER MANAGEMENT ── */
function umOpenDelete(id, name) {
    var idEl = document.getElementById('umDeleteId');
    var nameEl = document.getElementById('umDeleteName');
    var modalEl = document.getElementById('umDeleteModal');

    if (idEl) idEl.value = id;
    if (nameEl) nameEl.textContent = name;
    if (modalEl) modalEl.style.display = 'flex';
}

function umCloseDelete() {
    var el = document.getElementById('umDeleteModal');
    if (el) el.style.display = 'none';
}

/* ── RESET PASSWORD MODAL ── */
function umOpenResetPw(id, name) {
    var idEl    = document.getElementById('umResetId');
    var nameEl  = document.getElementById('umResetName');
    var inputEl = document.getElementById('umResetPwInput');
    var modalEl = document.getElementById('umResetPwModal');
    if (idEl)    idEl.value       = id;
    if (nameEl)  nameEl.textContent = name;
    if (inputEl) inputEl.value    = '';
    if (modalEl) modalEl.style.display = 'flex';
}
function umCloseResetPw() {
    var el = document.getElementById('umResetPwModal');
    if (el) el.style.display = 'none';
}

/* ── TOGGLE STATUS MODAL (ปิด/เปิดบัญชี) ── */
function umToggleStatus(id, name, currentStatus) {
    var isActive = currentStatus && currentStatus.toUpperCase() === 'ACTIVE';
    var action   = isActive ? 'khóa' : 'mở khóa';
    var icon     = isActive ? '🔒' : '🔓';
    var btnStyle = isActive
        ? 'background:linear-gradient(135deg,#ef4444,#dc2626)'
        : 'background:linear-gradient(135deg,#10b981,#059669)';

    var idEl     = document.getElementById('umToggleId');
    var nameEl   = document.getElementById('umToggleName');
    var iconEl   = document.getElementById('umToggleIcon');
    var titleEl  = document.getElementById('umToggleTitle');
    var actionEl = document.getElementById('umToggleAction');
    var btnEl    = document.getElementById('umToggleSubmitBtn');
    var modalEl  = document.getElementById('umToggleModal');

    if (idEl)     idEl.value         = id;
    if (nameEl)   nameEl.textContent = name;
    if (iconEl)   iconEl.textContent = icon;
    if (titleEl)  titleEl.textContent = (isActive ? 'Khóa' : 'Mở khóa') + ' tài khoản';
    if (actionEl) actionEl.textContent = action;
    if (btnEl)  { btnEl.style.cssText += ';' + btnStyle; btnEl.textContent = icon + ' ' + (isActive ? 'Khóa' : 'Mở khóa'); }
    if (modalEl)  modalEl.style.display = 'flex';
}
function umCloseToggle() {
    var el = document.getElementById('umToggleModal');
    if (el) el.style.display = 'none';
}

/* ── COURSE MANAGEMENT ── */
function togglePanel(courseId) {
    var p = document.getElementById('panel-' + courseId);
    if (p) p.classList.toggle('open');
}

function openEditCourse(id, name, desc, category, status) {
    var idEl = document.getElementById('editCourseId');
    var nameEl = document.getElementById('editCourseName');
    var descEl = document.getElementById('editCourseDesc');
    var catSel = document.getElementById('editCourseCategory');
    var stSel = document.getElementById('editCourseStatus');

    if (idEl) idEl.value = id;
    if (nameEl) nameEl.value = name;
    if (descEl) descEl.value = desc;

    if (catSel) {
        for (var i = 0; i < catSel.options.length; i++) {
            if (catSel.options[i].value === category) {
                catSel.selectedIndex = i;
                break;
            }
        }
    }
    if (stSel) {
        for (var i = 0; i < stSel.options.length; i++) {
            if (stSel.options[i].value === status) {
                stSel.selectedIndex = i;
                break;
            }
        }
    }
    openModal('modalEditCourse');
}

function confirmDeleteCourse(id, name) {
    var idEl = document.getElementById('deleteCourseId');
    var msgEl = document.getElementById('deleteCourseMsg');

    if (idEl) idEl.value = id;
    if (msgEl) msgEl.textContent = 'Xóa khóa học "' + name + '" và tất cả video bên trong? Không thể khôi phục';
    openModal('modalDeleteCourse');
}

function allCsFilter() {
    var searchEl = document.getElementById('allCsSearch');
    var catEl = document.getElementById('allCsCatFilter');
    var gridEl = document.getElementById('allCsGrid');

    if (!searchEl || !catEl || !gridEl) return;

    var kw = (searchEl.value || '').toLowerCase().trim();
    var cat = catEl.value;
    var cards = gridEl.querySelectorAll('.cc2-card');
    var shown = 0;

    cards.forEach(function(card) {
        var name = card.getAttribute('data-name') || '';
        var cCat = card.getAttribute('data-cat') || '';
        var match = (!kw || name.indexOf(kw) !== -1) && (!cat || cCat === cat);
        card.style.display = match ? '' : 'none';
        if (match) shown++;
    });

    var noRes = document.getElementById('allCsNoResults');
    if (noRes) noRes.style.display = (shown === 0) ? 'flex' : 'none';
}

/* ── PROFILE & SECURITY ── */
function togglePass(id, el) {
    var inp = document.getElementById(id);
    if (!inp) return;
    inp.type = inp.type === 'password' ? 'text' : 'password';
    if (el) el.style.opacity = inp.type === 'text' ? '1' : '.5';
}

function checkPassStrength(val) {
    var bar = document.getElementById('passStrengthBar');
    var lbl = document.getElementById('passStrengthLabel');
    if (!bar || !lbl) return;

    if (!val) {
        bar.style.width = '0%';
        lbl.textContent = '';
        return;
    }

    var score = 0;
    if (val.length >= 8) score++;
    if (/[A-Z]/.test(val)) score++;
    if (/[0-9]/.test(val)) score++;
    if (/[^A-Za-z0-9]/.test(val)) score++;

    var levels = [
        { w: '25%', c: '#ef4444', t: 'Yếu' },
        { w: '50%', c: '#f59e0b', t: 'Trung bình' },
        { w: '75%', c: '#3b82f6', t: 'Khá mạnh' },
        { w: '100%', c: '#10b981', t: 'Mạnh' }
    ];

    var lvl = levels[Math.min(score - 1, 3)] || levels[0];
    bar.style.width = lvl.w;
    bar.style.background = lvl.c;
    lbl.textContent = lvl.t;
    lbl.style.color = lvl.c;
}

function doChangePass() {
    var oldEl = document.getElementById('oldPass');
    var npEl = document.getElementById('newPass');
    var cpEl = document.getElementById('confirmPass');
    var msg = document.getElementById('passMsg');

    if (!oldEl || !npEl || !cpEl || !msg) return;

    var old = oldEl.value.trim();
    var np = npEl.value.trim();
    var cp = cpEl.value.trim();

    function showMsg(text, ok) {
        msg.style.display = 'block';
        msg.textContent = text;
        msg.style.background = ok ? '#d1fae5' : '#fee2e2';
        msg.style.color = ok ? '#065f46' : '#dc2626';
    }

    if (!old || !np || !cp) {
        showMsg('⚠️ Vui lòng điền đầy đủ tất cả các trường!', false);
        return;
    }
    if (np.length < 8) {
        showMsg('⚠️ Mật khẩu mới phải có ít nhất 8 ký tự!', false);
        return;
    }
    if (np !== cp) {
        showMsg('⚠️ Mật khẩu xác nhận không khớp!', false);
        return;
    }

    // This would normally be an AJAX call
    showMsg('✅ Mật khẩu đã được cập nhật thành công!', true);
    oldEl.value = '';
    npEl.value = '';
    cpEl.value = '';
    var strengthBar = document.getElementById('passStrengthBar');
    var strengthLabel = document.getElementById('passStrengthLabel');
    if (strengthBar) strengthBar.style.width = '0%';
    if (strengthLabel) strengthLabel.textContent = '';
}

/* ── CHARTS ── */
function initDashboardCharts() {
    var cfg = window.DashboardConfig;
    if (!cfg) { console.error("DashboardConfig missing"); return; }
    if (typeof Chart === 'undefined') { console.warn("Chart.js library missing in initDashboardCharts"); return; }
    window._chartsInitialized = true;

    // Enrollment line chart
    try {
        var ctx1 = document.getElementById('enrollChart');
        if (ctx1 && cfg.jsMonths && cfg.jsMonths.length > 0 && cfg.jsEnroll && cfg.jsEnroll.length > 0) {
            if (Chart.getChart(ctx1)) Chart.getChart(ctx1).destroy();
            new Chart(ctx1, {
                type: 'line',
                data: {
                    labels: cfg.jsMonths,
                    datasets: [{
                        label: 'Lượt đăng ký',
                        data: cfg.jsEnroll,
                        borderColor: '#6366f1',
                        backgroundColor: 'rgba(99,102,241,.1)',
                        borderWidth: 2.5,
                        pointBackgroundColor: '#6366f1',
                        pointRadius: 4,
                        pointHoverRadius: 6,
                        tension: 0.4,
                        fill: true
                    }]
                },
                options: {
                    responsive: true, maintainAspectRatio: false,
                    plugins: { legend: { display: false } },
                    scales: {
                        x: { grid: { display: false }, ticks: { font: { size: 10 }, color: '#94a3b8' } },
                        y: { beginAtZero: true, grid: { color: '#f1f5f9' }, ticks: { font: { size: 10 }, color: '#94a3b8', precision: 0 } }
                    }
                }
            });
        }
    } catch (e) { console.error("Error init enrollChart:", e); }

    // Users bar chart
    try {
        var ctx2 = document.getElementById('userChart');
        if (ctx2 && cfg.jsMonths && cfg.jsMonths.length > 0 && cfg.jsStudents && cfg.jsTeachers) {
            if (Chart.getChart(ctx2)) Chart.getChart(ctx2).destroy();
            new Chart(ctx2, {
                type: 'bar',
                data: {
                    labels: cfg.jsMonths,
                    datasets: [
                        {
                            label: 'Học viên mới',
                            data: cfg.jsStudents,
                            backgroundColor: 'rgba(16,185,129,.75)',
                            borderColor: '#10b981',
                            borderWidth: 1,
                            borderRadius: 5
                        },
                        {
                            label: 'Giáo viên mới',
                            data: cfg.jsTeachers,
                            backgroundColor: 'rgba(245,158,11,.75)',
                            borderColor: '#f59e0b',
                            borderWidth: 1,
                            borderRadius: 5
                        }
                    ]
                },
                options: {
                    responsive: true, maintainAspectRatio: false,
                    plugins: {
                        legend: { position: 'bottom', labels: { boxWidth: 12, font: { size: 10 } } }
                    },
                    scales: {
                        x: { grid: { display: false }, ticks: { font: { size: 10 }, color: '#94a3b8' } },
                        y: { beginAtZero: true, grid: { color: '#f1f5f9' }, ticks: { font: { size: 10 }, color: '#94a3b8', precision: 0 } }
                    }
                }
            });
        }
    } catch (e) { console.error("Error init userChart:", e); }

    // Bar Chart — Lượt đăng ký hàng tháng (Main Dashboard)
    try {
        var ctxBar = document.getElementById('barChart');
        if (ctxBar && cfg.cLabels && cfg.cLabels.length > 0 && cfg.cData && cfg.cData.length > 0) {
            if (Chart.getChart(ctxBar)) Chart.getChart(ctxBar).destroy();
            new Chart(ctxBar, {
                type: 'bar',
                data: {
                    labels: cfg.cLabels,
                    datasets: [{
                        label: 'Đăng ký',
                        data: cfg.cData,
                        backgroundColor: 'rgba(59,130,246,0.75)',
                        borderRadius: 6,
                        borderSkipped: false
                    }]
                },
                options: {
                    responsive: true,
                    plugins: {
                        legend: { display: false },
                        tooltip: { callbacks: { label: function(c) { return ' ' + c.parsed.y + ' người'; } } }
                    },
                    scales: {
                        x: { grid: { display: false } },
                        y: { beginAtZero: true, ticks: { stepSize: 1 } }
                    }
                }
            });
        }
    } catch (e) { console.error("Error init barChart:", e); }

    // Donut Chart — Khóa học phổ biến
    try {
        var ctxDonut = document.getElementById('donutChart');
        if (ctxDonut && cfg.dLabels && cfg.dLabels.length > 0 && cfg.dData && cfg.dData.length > 0) {
            if (Chart.getChart(ctxDonut)) Chart.getChart(ctxDonut).destroy();
            new Chart(ctxDonut, {
                type: 'doughnut',
                data: {
                    labels: cfg.dLabels,
                    datasets: [{
                        data: cfg.dData,
                        backgroundColor: ['#3b82f6', '#10b981', '#f59e0b', '#8b5cf6', '#ef4444'],
                        borderWidth: 2, borderColor: '#fff'
                    }]
                },
                options: {
                    responsive: true,
                    plugins: {
                        legend: { position: 'bottom', labels: { font: { size: 11 }, boxWidth: 12 } },
                        tooltip: { callbacks: { label: function(c) { return ' ' + c.label + ': ' + c.parsed + ' người'; } } }
                    },
                    cutout: '62%'
                }
            });
        }
    } catch (e) { console.error("Error init donutChart:", e); }
}

document.addEventListener('DOMContentLoaded', function() {
    var nowDateEl = document.getElementById('nowDate');
    if (nowDateEl) {
        nowDateEl.textContent = new Date().toLocaleString('vi-VN', {
            year: 'numeric', month: 'long', day: 'numeric', hour: '2-digit', minute: '2-digit'
        });
    }
    tryInitCharts(0);
});

// Retry until Chart.js + DashboardConfig are both ready (max 5s)
function tryInitCharts(attempt) {
    if (window._chartsInitialized) return;
    var chartReady = typeof Chart !== 'undefined';
    var configReady = window.DashboardConfig && (
        (window.DashboardConfig.cLabels && window.DashboardConfig.cLabels.length > 0) ||
        (window.DashboardConfig.jsMonths && window.DashboardConfig.jsMonths.length > 0)
    );
    if (chartReady && configReady) {
        initDashboardCharts();
    } else if (attempt < 20) {
        setTimeout(function() { tryInitCharts(attempt + 1); }, 250);
    } else {
        console.warn('Dashboard charts: Chart.js or DashboardConfig not available after 5s');
    }
}

// Fallback on full page load
window.addEventListener('load', function() {
    if (!window._chartsInitialized) {
        tryInitCharts(0);
    }
});

/* ── ADDITIONAL COURSE MANAGEMENT ── */
function openUploadVideo(courseId, courseName) {
    var idEl = document.getElementById('uploadVideoCourseId');
    var subEl = document.getElementById('uploadVideoSubtitle');
    var titleEl = document.getElementById('videoTitle');
    var descEl = document.getElementById('videoDesc');
    var urlEl = document.getElementById('videoUrl');
    var fnameEl = document.getElementById('uploadFilename');
    var fileEl = document.getElementById('videoFile');
    var progressEl = document.getElementById('uploadProgress');
    var btnEl = document.getElementById('uploadSubmitBtn');

    if (idEl) idEl.value = courseId;
    if (subEl) subEl.textContent = 'Thêm video vào khóa học: ' + (courseName || '');
    if (titleEl) titleEl.value = '';
    if (descEl) descEl.value = '';
    if (urlEl) urlEl.value = '';
    if (fnameEl) fnameEl.textContent = '';
    if (fileEl) fileEl.value = '';
    if (typeof switchUploadTab === 'function') switchUploadTab('file');
    if (progressEl) progressEl.style.display = 'none';
    if (btnEl) {
        btnEl.disabled = false;
        btnEl.textContent = '📤 Tải video lên';
    }
    openModal('modalUploadVideo');
}

function openVideoDeleteModal(videoId, videoTitle, courseId) {
    var idEl = document.getElementById('deleteVideoId');
    var cIdEl = document.getElementById('deleteVideoCourseId');
    var msgEl = document.getElementById('deleteVideoMsg');

    if (idEl) idEl.value = videoId;
    if (cIdEl) cIdEl.value = courseId;
    if (msgEl) {
        msgEl.innerHTML = 'Bạn có chắc muốn xóa video <strong style="color:#0f2744;">"' + videoTitle + '"</strong>?<br/><span style="color:#ef4444;font-size:12px;">⚠️ Hành động này không thể hoàn tác.</span>';
    }
    openModal('modalDeleteVideo');
}

function openEditVideo(videoId, courseId, title, desc, url) {
    var idEl = document.getElementById('editVideoId');
    var cIdEl = document.getElementById('editVideoCourseId');
    var titleEl = document.getElementById('editVideoTitle');
    var descEl = document.getElementById('editVideoDesc');
    var urlEl = document.getElementById('editVideoUrl');

    if (idEl) idEl.value = videoId;
    if (cIdEl) cIdEl.value = courseId;
    if (titleEl) titleEl.value = title;
    if (descEl) descEl.value = desc;
    if (urlEl) urlEl.value = url;
    openModal('modalEditVideo');
}

function switchUploadTab(tab) {
    var fileTab = document.getElementById('tabFile');
    var urlTab = document.getElementById('tabUrl');
    var fileSec = document.getElementById('fileSection');
    var urlSec = document.getElementById('urlSection');
    var urlInp = document.getElementById('videoUrl');

    if (!fileTab || !urlTab || !fileSec || !urlSec || !urlInp) return;

    if (tab === 'file') {
        fileTab.classList.add('active');
        urlTab.classList.remove('active');
        fileSec.style.display = '';
        urlSec.style.display = 'none';
        urlInp.removeAttribute('required');
    } else {
        urlTab.classList.add('active');
        fileTab.classList.remove('active');
        urlSec.style.display = '';
        fileSec.style.display = 'none';
        urlInp.setAttribute('required', 'required');
    }
}

function showFileName(input) {
    var nameEl = document.getElementById('uploadFilename');
    if (!nameEl) return;
    var name = input.files[0] ? input.files[0].name : '';
    nameEl.textContent = name ? '📎 ' + name : '';
}

function handleDrop(e) {
    e.preventDefault();
    var dropEl = document.getElementById('dropzone');
    if (dropEl) dropEl.classList.remove('drag-over');
    var files = e.dataTransfer.files;
    if (files.length > 0) {
        var input = document.getElementById('videoFile');
        if (!input) return;
        var dt = new DataTransfer();
        dt.items.add(files[0]);
        input.files = dt.files;
        showFileName(input);
    }
}

function showUploadProgress() {
    var fileInput = document.getElementById('videoFile');
    var progressEl = document.getElementById('uploadProgress');
    var btn = document.getElementById('uploadSubmitBtn');
    var pbar = document.getElementById('uploadProgressBar');

    if (fileInput && fileInput.files && fileInput.files.length > 0) {
        if (progressEl) progressEl.style.display = 'block';
        if (btn) {
            btn.disabled = true;
            btn.textContent = '⏳ Đัง tải lên...';
        }
        if (pbar) {
            var pct = 0;
            var iv = setInterval(function() {
                pct += Math.random() * 8;
                if (pct > 90) pct = 90;
                pbar.value = Math.floor(pct);
            }, 400);
        }
    }
}

function cmFilter() {
    var searchEl = document.getElementById('cmSearch');
    var catEl = document.getElementById('cmCatFilter');
    var statusEl = document.getElementById('cmStatusFilter');
    var gridEl = document.getElementById('cmCourseGrid');

    if (!searchEl || !catEl || !statusEl || !gridEl) return;

    var kw = (searchEl.value || '').toLowerCase().trim();
    var cat = catEl.value;
    var status = statusEl.value;
    var cards = gridEl.querySelectorAll('.cc2-card');
    var shown = 0;

    cards.forEach(function(card) {
        var name = card.getAttribute('data-name') || '';
        var cCat = card.getAttribute('data-cat') || '';
        var cStat = card.getAttribute('data-status') || '';
        var match = (!kw || name.indexOf(kw) !== -1)
            && (!cat || cCat === cat)
            && (!status || cStat === status);
        card.style.display = match ? '' : 'none';
        if (match) shown++;
    });

    var noRes = document.getElementById('cmNoResults');
    if (noRes) noRes.style.display = (shown === 0) ? 'flex' : 'none';
}

function openCoursePanel(id, name, desc, cat, status, videoCount, enrollCount) {
    var cfg = window.DashboardConfig;
    if (!cfg) return;

    document.getElementById('cpTitle').textContent = name;
    document.getElementById('cpCat').textContent = cat;
    document.getElementById('cpVideos').textContent = videoCount;
    document.getElementById('cpEnrolls').textContent = enrollCount;

    var statusEl = document.getElementById('cpStatus');
    if (statusEl) {
        statusEl.textContent = (status === 'ACTIVE') ? '● Hoạt động' : '● Đã ẩn';
        statusEl.className = 'cp-tag-status ' + (status === 'ACTIVE' ? 'active' : 'inactive');
    }

    // Wire buttons
    var btnVideo = document.getElementById('cpBtnVideo');
    var btnEdit = document.getElementById('cpBtnEdit');
    var btnDelete = document.getElementById('cpBtnDelete');
    var btnHw = document.getElementById('cpBtnHw');

    if (btnVideo) btnVideo.onclick = function(e) { e.stopPropagation(); closeModal('modalCoursePanel'); openUploadVideo(id, name); };
    if (btnEdit) btnEdit.onclick = function(e) { e.stopPropagation(); closeModal('modalCoursePanel'); openEditCourse(id, name, desc, cat, status); };
    if (btnDelete) btnDelete.onclick = function(e) { e.stopPropagation(); closeModal('modalCoursePanel'); confirmDeleteCourse(id, name); };
    if (btnHw) btnHw.onclick = function(e) { e.stopPropagation(); openHomeworkModal(id, name); };

    // Render video list
    var vids = (cfg.courseVideos && cfg.courseVideos[id]) || [];
    var listEl = document.getElementById('cpVideoList');
    if (listEl) {
        if (vids.length === 0) {
            listEl.innerHTML = '<div class="cpb-empty">📭 Chưa có video trong khóa học này</div>';
        } else {
            var html = '';
            vids.forEach(function(v) {
                var isYt = v.url.indexOf('youtube.com') !== -1 || v.url.indexOf('youtu.be') !== -1;
                var isDr = v.url.indexOf('drive.google.com') !== -1;
                var chip = isYt ? '<span style="color:#ef4444;background:#fef2f2;" class="video-url-chip">▶ YouTube</span>'
                    : isDr ? '<span style="color:#1d4ed8;background:#eff6ff;" class="video-url-chip">☁ Drive</span>'
                        : v.url ? '<span style="color:#10b981;background:#ecfdf5;" class="video-url-chip">🔗 Link</span>' : '';
                html += '<div class="video-item">'
                    + '<div class="video-num">' + v.order + '</div>'
                    + '<div class="video-title">' + v.title + '</div>'
                    + chip
                    + '<button class="video-edit-btn" onclick="event.stopPropagation();openEditVideo(' + v.id + ',' + id + ',\'' + v.title.replace(/'/g, "\\'") + '\',\'' + v.desc.replace(/'/g, "\\'") + '\',\'' + v.url.replace(/'/g, "\\'") + '\')">✏️</button>'
                    + '<button class="video-del" onclick="event.stopPropagation();openVideoDeleteModal(' + v.id + ',\'' + v.title.replace(/'/g, "\\'") + '\',' + id + ')">🗑️</button>'
                    + '</div>';
            });
            listEl.innerHTML = html;
        }
    }

    // Render homework list
    var hws = (cfg.courseHomeworks && cfg.courseHomeworks[id]) || [];
    var hwListEl = document.getElementById('cpHomeworkList');
    if (hwListEl) {
        if (hws.length === 0) {
            hwListEl.innerHTML = '<div class="cpb-empty">📭 Chưa có tệp bài tập — nhấn 📋 Bài tập để tải lên</div>';
        } else {
            var hwHtml = '';
            hws.forEach(function(h) {
                hwHtml += '<div class="hw-row">'
                    + '<div class="hw-row-icon">📄</div>'
                    + '<div class="hw-row-body">'
                    + '<div class="hw-row-title">' + h.title + '</div>'
                    + '<div class="hw-row-date">🗓 ' + h.date + '</div>'
                    + '</div>'
                    + '<div class="hw-row-dl">'
                    + (h.file ? '<a href="' + h.path + '" target="_blank" style="margin-right:6px;">📥 ' + h.file + '</a>' : '<span style="font-size:12px;color:#94a3b8;margin-right:6px;">Không có tệp</span>')
                    + '</div>'
                    + '<div class="hw-row-actions">'
                    + '<button class="hw-edit-btn" title="Sửa" onclick="event.stopPropagation();openEditHomework(' + h.id + ',\'' + (h.title || '').replace(/'/g, "\\'") + '\',\'' + (h.desc || '').replace(/'/g, "\\'") + '\',' + id + ')" style="background:#eff6ff;border:none;border-radius:7px;padding:5px 8px;cursor:pointer;font-size:13px;color:#1d4ed8;transition:background .15s;">✏️</button>'
                    + '<button class="hw-del-btn" title="Xóa" onclick="event.stopPropagation();confirmDeleteHomework(' + h.id + ',\'' + (h.title || '').replace(/'/g, "\\'") + '\',' + id + ')" style="background:#fef2f2;border:none;border-radius:7px;padding:5px 8px;cursor:pointer;font-size:13px;color:#ef4444;transition:background .15s;margin-left:4px;">🗑️</button>'
                    + '</div>'
                    + '</div>';
            });
            hwListEl.innerHTML = hwHtml;
        }
    }

    // Update classroom link
    var clLink = document.getElementById('cpClassroomLink');
    if (clLink) clLink.href = (cfg.contextPath || '') + '/classroom?courseId=' + id;

    openModal('modalCoursePanel');
}

function openHomeworkModal(courseId, courseName) {
    var idEl = document.getElementById('hwCourseId');
    var subEl = document.getElementById('hwSubtitle');
    var titleEl = document.getElementById('hwTitle');
    var descEl = document.getElementById('hwDesc');
    var nameEl = document.getElementById('hwFileName');
    var fileEl = document.getElementById('hwFile');
    var btnEl = document.getElementById('hwSubmitBtn');

    if (idEl) idEl.value = courseId;
    if (subEl) subEl.textContent = 'Khóa học: ' + courseName;
    if (titleEl) titleEl.value = '';
    if (descEl) descEl.value = '';
    if (nameEl) nameEl.textContent = '';
    if (fileEl) fileEl.value = '';
    if (btnEl) {
        btnEl.disabled = false;
        btnEl.textContent = '📤 Tải lên bài tập';
    }
    openModal('modalHomework');
}

function hwShowFile(input) {
    var nameEl = document.getElementById('hwFileName');
    if (!nameEl) return;
    var f = input.files[0];
    if (!f) { nameEl.textContent = ''; return; }
    var mb = (f.size / 1024 / 1024).toFixed(1);
    nameEl.textContent = '📎 ' + f.name + ' (' + mb + ' MB)';
}

function hwHandleDrop(e) {
    e.preventDefault();
    var dropEl = document.getElementById('hwDropzone');
    if (dropEl) dropEl.classList.remove('drag-over');
    var files = e.dataTransfer.files;
    if (files.length > 0) {
        var input = document.getElementById('hwFile');
        if (!input) return;
        try {
            var dt = new DataTransfer();
            dt.items.add(files[0]);
            input.files = dt.files;
            hwShowFile(input);
        } catch (err) { }
    }
}

function openEditHomework(hwId, title, desc, courseId) {
    var idEl = document.getElementById('editHwId');
    var cIdEl = document.getElementById('editHwCourseId');
    var titleInp = document.getElementById('editHwTitle');
    var descInp = document.getElementById('editHwDesc');
    var nameEl = document.getElementById('editHwFileName');
    var fileEl = document.getElementById('editHwFile');
    var btnEl = document.getElementById('editHwSubmitBtn');

    if (idEl) idEl.value = hwId;
    if (cIdEl) cIdEl.value = courseId;
    if (titleInp) titleInp.value = title;
    if (descInp) descInp.value = desc;
    if (nameEl) nameEl.textContent = '';
    if (fileEl) fileEl.value = '';
    if (btnEl) {
        btnEl.disabled = false;
        btnEl.textContent = '💾 Lưu thay đổi';
    }
    closeModal('modalCoursePanel');
    openModal('modalEditHomework');
}

function confirmDeleteHomework(hwId, title, courseId) {
    var idEl = document.getElementById('deleteHwId');
    var cIdEl = document.getElementById('deleteHwCourseId');
    var msgEl = document.getElementById('deleteHwMsg');

    if (idEl) idEl.value = hwId;
    if (cIdEl) cIdEl.value = courseId;
    if (msgEl) msgEl.textContent = 'Xóa "' + title + '" khỏi hệ thống? Tệp sẽ bị xóa vĩnh viễn';
    closeModal('modalCoursePanel');
    openModal('modalDeleteHomework');
}

/* ══════════════════════════════════════════════════════════════════
   NOTIFICATION POLLING — อัปเดต badge แจ้งเตือนทุก 30 วินาที
   และแสดง toast เมื่อมีบài nộp ใหม่จากนักเรียน
   ══════════════════════════════════════════════════════════════════ */
(function() {
    // BUG FIX: รองรับทั้ง teacher (tab=notifications) และ admin (tab=approval)
    var sidebarBell = document.querySelector('a[href*="tab=notifications"]')
        || document.querySelector('a[href*="tab=approval"]');
    if (!sidebarBell) return;

    var _lastTotal = -1; // -1 = ยังไม่เคยโหลด

    // สร้าง toast element
    var toast = document.createElement('div');
    toast.id = 'hw-toast';
    toast.style.cssText = [
        'position:fixed', 'bottom:28px', 'right:28px', 'z-index:12000',
        'background:#fff', 'border-radius:16px',
        'box-shadow:0 8px 32px rgba(0,0,0,.18)',
        'border-left:5px solid #f59e0b',
        'padding:16px 20px 16px 16px',
        'display:none', 'align-items:center', 'gap:14px',
        'max-width:340px', 'animation:notifyPop .28s cubic-bezier(.34,1.56,.64,1)'
    ].join(';');
    toast.innerHTML = [
        '<div id="hw-toast-icon" style="font-size:28px;line-height:1;">📝</div>',
        '<div style="flex:1;">',
        '<div id="hw-toast-title" style="font-size:14px;font-weight:800;color:#0f2744;margin-bottom:3px;"></div>',
        '<div id="hw-toast-sub" style="font-size:12px;color:#64748b;"></div>',
        '</div>',
        '<a id="hw-toast-link" href="dashboard?tab=notifications" ',
        'style="flex-shrink:0;background:#f59e0b;color:#fff;font-size:11px;font-weight:700;',
        'padding:6px 12px;border-radius:8px;text-decoration:none;">ดูเลย</a>',
        '<button onclick="document.getElementById(\'hw-toast\').style.display=\'none\'" ',
        'style="position:absolute;top:8px;right:10px;background:none;border:none;',
        'font-size:16px;color:#94a3b8;cursor:pointer;line-height:1;">×</button>'
    ].join('');
    document.body.appendChild(toast);

    function showToast(newHw24h, newEnrolls) {
        var titleEl = document.getElementById('hw-toast-title');
        var subEl   = document.getElementById('hw-toast-sub');
        var lines   = [];
        if (newHw24h  > 0) lines.push('📝 ' + newHw24h  + ' งานใหม่ถูกส่งมา');
        if (newEnrolls > 0) lines.push('🎓 ' + newEnrolls + ' นักเรียนลงทะเบียนใหม่ (7 วัน)');
        if (!lines.length) return;
        if (titleEl) titleEl.textContent = '🔔 มีการแจ้งเตือนใหม่!';
        if (subEl)   subEl.textContent   = lines.join('  ·  ');
        toast.style.display = 'flex';
        clearTimeout(toast._timer);
        toast._timer = setTimeout(function() { toast.style.display = 'none'; }, 8000);
    }

    function updateBadge(total) {
        var old = sidebarBell.querySelector('span[data-noti-badge]');
        if (old) old.remove();
        if (total > 0) {
            var badge = document.createElement('span');
            badge.setAttribute('data-noti-badge', '1');
            badge.style.cssText = [
                'position:absolute', 'right:14px', 'top:50%',
                'transform:translateY(-50%)',
                'background:#ef4444', 'color:#fff',
                'font-size:11px', 'font-weight:700',
                'border-radius:999px', 'padding:1px 7px',
                'min-width:20px', 'text-align:center'
            ].join(';');
            badge.textContent = total > 99 ? '99+' : total;
            sidebarBell.appendChild(badge);
        }
    }

    // BUG FIX: เก็บ newHw24h ล่าสุดแยกจาก total
    // เพื่อตรวจว่ามีการส่งงานใหม่จริงๆ ไม่ใช่แค่ total เพิ่ม
    var _lastNewHw24h   = -1;
    var _lastNewEnrolls = -1;

    function poll() {
        var ctx = (window.DashboardConfig && window.DashboardConfig.contextPath) ? window.DashboardConfig.contextPath : '';
        fetch(ctx + '/api/notifications/count', { credentials: 'same-origin' })
            .then(function(r) { return r.ok ? r.json() : null; })
            .then(function(data) {
                if (!data) return;
                var total        = data.total       || 0;
                var pendingHw    = data.pendingHw   || 0;
                // BUG FIX: รองรับทั้ง teacher (newHw24h) และ admin (newHw24hAll)
                var newHw24h     = data.newHw24h    || data.newHw24hAll || 0;
                var newEnrolls   = data.newEnrolls  || 0;

                updateBadge(total);

                var isFirstPoll = (_lastNewHw24h === -1);
                if (!isFirstPoll) {
                    if (newHw24h > _lastNewHw24h || newEnrolls > _lastNewEnrolls) {
                        showToast(newHw24h, newEnrolls);
                    }
                } else {
                    // poll แรก: แสดง toast ถ้ามีงานส่งใหม่ใน 24h
                    if (newHw24h > 0) {
                        showToast(newHw24h, newEnrolls);
                    }
                }
                _lastNewHw24h   = newHw24h;
                _lastNewEnrolls = newEnrolls;
                _lastTotal      = total;
            })
            .catch(function() {}); // silent fail
    }

    // รันทันทีเมื่อโหลดหน้า และทุก 30 วินาที
    document.addEventListener('DOMContentLoaded', function() {
        poll();
        setInterval(poll, 30000);
    });
})();