var PAGES = ['home','tinh-nang','khoa-hoc','hoc-phi','lien-he','ho-so'];

function showPage(name) {
  for (var i = 0; i < PAGES.length; i++) {
    var p = PAGES[i];
    var el = document.getElementById('page-' + p);
    if (el) el.classList.remove('active');
    var nav = document.getElementById('nav-' + p);
    if (nav) nav.classList.remove('active');
    var mnav = document.getElementById('mnav-' + p);
    if (mnav) mnav.classList.remove('active');
  }
  var pg = document.getElementById('page-' + name);
  if (pg) { pg.classList.add('active'); window.scrollTo(0, 0); }
  if (name === 'khoa-hoc' && typeof catRender === 'function') { setTimeout(catRender, 50); }
  var lnk = document.getElementById('nav-' + name);
  if (lnk) lnk.classList.add('active');
  var mlnk = document.getElementById('mnav-' + name);
  if (mlnk) mlnk.classList.add('active');
  // Khi chuyển trang khác, đóng classroom nếu đang mở
  if (name !== 'khoa-hoc') closeClassroom();
  setTimeout(triggerReveal, 80);
}

/* ── Classroom inline panel ── */
function openClassroom(courseId, courseName) {
  var ctxPath  = window.StudyFlowConfig.contextPath;
  var loggedIn = window.StudyFlowConfig.isLoggedIn;
  var role     = window.StudyFlowConfig.userRole || 'guest';

  // ยังไม่ได้ login → redirect ไป login
  if (!loggedIn) {
    window.location.href = ctxPath + '/login?redirect=' + encodeURIComponent(ctxPath + '/classroom?courseId=' + courseId);
    return;
  }

  // ครู / admin → เปิด Direct URL (full page)
  if (role === 'teacher' || role === 'admin' || role === 'super_admin') {
    window.location.href = ctxPath + '/classroom?courseId=' + courseId;
    return;
  }

  // นักเรียน → Inline iframe
  var listView = document.getElementById('courseListView');
  var clsView  = document.getElementById('classroomView');
  var iframe   = document.getElementById('classroomIframe');
  var crumb    = document.getElementById('classroomBreadcrumb');
  if (!listView || !clsView || !iframe) return;
  iframe.src = ctxPath + '/classroom?courseId=' + courseId;
  if (crumb) crumb.textContent = '📚 Khóa học · ' + courseName;
  listView.style.display = 'none';
  clsView.style.display  = 'block';
  window.scrollTo(0, 0);
}

function closeClassroom() {
  var listView = document.getElementById('courseListView');
  var clsView  = document.getElementById('classroomView');
  var iframe   = document.getElementById('classroomIframe');
  if (!listView || !clsView) return;
  if (clsView.style.display === 'none') return;
  // Clear iframe to stop video
  if (iframe) iframe.src = '';
  listView.style.display = 'block';
  clsView.style.display  = 'none';
  window.scrollTo(0, 0);
}

function resizeClassroomIframe(el) {
  try {
    var h = el.contentWindow.document.body.scrollHeight;
    if (h > 400) el.style.height = h + 'px';
  } catch(e) {
    // cross-origin: keep min-height from CSS
  }
}

window.addEventListener('scroll', function() {
  var nav = document.getElementById('mainNav');
  if (nav) nav.classList.toggle('scrolled', window.scrollY > 20);
  triggerReveal();
});

function currentPage() {
  for (var i = 0; i < PAGES.length; i++) {
    var el = document.getElementById('page-' + PAGES[i]);
    if (el && el.classList.contains('active')) return PAGES[i];
  }
  return 'home';
}

function triggerReveal() {
  var pg = document.getElementById('page-' + currentPage());
  if (!pg) return;
  var items = pg.querySelectorAll('.reveal');
  for (var i = 0; i < items.length; i++) {
    if (items[i].getBoundingClientRect().top < window.innerHeight - 60) {
      items[i].classList.add('visible');
    }
  }
}

function tog(hdr) {
  var body = hdr.nextElementSibling;
  var isOpen = body.classList.contains('open');
  body.classList.toggle('open', !isOpen);
  hdr.classList.toggle('open', !isOpen);
}

function toggleMobile() {
  var m = document.getElementById('mobileMenu');
  if (m) m.classList.toggle('open');
}
function closeMobile() {
  var m = document.getElementById('mobileMenu');
  if (m) m.classList.remove('open');
}


/* ── COURSE CATALOG JS — REAL DATA ── */
(function(){
  var COURSES = window.StudyFlowConfig.courses;
  var state = {q:'',cat:'',sort:'popular'};

  function escHtml(s){ return s ? s.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;') : ''; }

  function getFiltered(){
    return COURSES.filter(function(c){
      var qOk = !state.q || c.name.toLowerCase().indexOf(state.q.toLowerCase()) >= 0 || c.inst.toLowerCase().indexOf(state.q.toLowerCase()) >= 0;
      var catOk = !state.cat || c.cat === state.cat
          || (state.cat === 'Programming' && c.cat === 'L\u1eadp tr\u00ecnh')
          || (state.cat === 'Design' && c.cat === 'Thi\u1ebft k\u1ebf')
          || (state.cat === 'Business' && c.cat === 'Kinh doanh');
      return qOk && catOk;
    }).sort(function(a,b){
      if(state.sort === 'new')    return (b.isNew ? 1 : 0) - (a.isNew ? 1 : 0);
      if(state.sort === 'videos') return b.videos - a.videos;
      if(state.sort === 'alpha')  return a.name.localeCompare(b.name,'vi');
      return b.students - a.students;
    });
  }

  // avatar gradient pool
  var GRADS = [
    'linear-gradient(135deg,#27ae60,#1a7a42)',
    'linear-gradient(135deg,#2563eb,#1d4ed8)',
    'linear-gradient(135deg,#7c3aed,#5b21b6)',
    'linear-gradient(135deg,#ea580c,#c2410c)',
    'linear-gradient(135deg,#0891b2,#0369a1)',
    'linear-gradient(135deg,#db2777,#be185d)'
  ];

  function buildCard(c, idx){
    var words = c.inst.trim().split(' ');
    var init = ((words[0]||'')[0]||'').toUpperCase() + ((words[words.length-1]||'')[0]||'').toUpperCase();
    var avGrad = GRADS[idx % GRADS.length];
    var catIcon = c.catIcon || '\uD83D\uDCDA';
    var ctxPath = window.StudyFlowConfig.contextPath;

    // Thumbnail: ใช้รูป YouTube จริง ถ้าไม่มีให้ใช้ gradient + emoji
    var thumbContent;
    if (c.thumb && c.thumb.length > 0) {
      thumbContent = '<img src="' + c.thumb + '" alt="' + escHtml(c.name)
          + '" style="width:100%;height:100%;object-fit:cover;display:block;" '
          + 'onerror="this.style.display=\'none\';this.nextSibling.style.display=\'flex\'">'
          + '<div class="cat-card-thumb-bg" style="display:none">' + catIcon + '</div>';
    } else {
      thumbContent = '<div class="cat-card-thumb-bg">' + catIcon + '</div>';
    }

    var thumbHtml = '<div class="cat-card-thumb" style="background:' + c.grad + '">'
        + thumbContent
        + '<div class="cat-card-free-badge">Miễn phí</div>'
        + (c.isNew ? '<div class="cat-card-new-ribbon">\uD83C\uDD95 M\u1edbi</div>' : '')
        + '</div>';

    var descPart = c.desc ? '<div class="cat-card-desc">' + escHtml(c.desc) + '</div>' : '';
    var stuTxt = c.students > 0 ? c.students.toLocaleString('vi-VN') + ' h\u1ecdc vi\u00ean' : '';
    var vidTxt = c.videos > 0 ? c.videos + ' b\u00e0i' : '';

    var avHtml;
    if (c.teacherPhoto && c.teacherPhoto.length > 0) {
      avHtml = '<img src="' + c.teacherPhoto + '" alt="' + escHtml(c.inst) + '"'
          + ' style="width:100%;height:100%;object-fit:cover;border-radius:50%;"'
          + ' onerror="this.parentNode.innerHTML=\'' + init + '\'">';
    } else {
      avHtml = '<span>' + init + '</span>';
    }
    var bodyHtml = '<div class="cat-card-body">'
        + '<div class="cat-card-inst-row">'
        + '<div class="cat-card-av" style="background:' + avGrad + ';overflow:hidden;display:flex;align-items:center;justify-content:center;">' + avHtml + '</div>'
        + '<div class="cat-card-inst-info">'
        + '<span class="cat-card-inst-name">' + escHtml(c.inst) + '</span>'
        + '<span class="cat-card-inst-sub">' + escHtml(c.cat) + '</span>'
        + '</div></div>'
        + '<div class="cat-card-title">' + escHtml(c.name) + '</div>'
        + descPart
        + '</div>';

    var footerHtml = '<div class="cat-card-footer">'
        + '<span class="cat-card-price-free">Miễn phí</span>'
        + '<div class="cat-card-meta-row">'
        + (stuTxt ? '<span class="cat-card-stu-chip">\uD83D\uDC65 ' + stuTxt + '</span>' : '')
        + (vidTxt ? '<span class="cat-card-vid-chip">\u25B6 ' + vidTxt + '</span>' : '')
        + '</div></div>';

    return '<div class="cat-card" onclick="openClassroom(' + c.id + ',\'' + escHtml(c.name).replace(/'/g,"&#39;") + '\')">'
        + thumbHtml + bodyHtml + footerHtml + '</div>';
  }

  window.catRender = function(){
    var filtered = getFiltered();
    var grid  = document.getElementById('catGrid');
    var empty = document.getElementById('catEmpty');
    var cnt   = document.getElementById('catCount');
    var cntAll = document.getElementById('cntAll');
    if(!grid) return;
    if(cnt) cnt.textContent = filtered.length;
    if(filtered.length === 0){ grid.innerHTML = ''; if(empty) empty.style.display=''; return; }
    if(empty) empty.style.display = 'none';
    grid.innerHTML = filtered.map(buildCard).join('');
  };

  window.catSearch = function(){
    var inp = document.getElementById('catSearchInput');
    state.q = inp ? inp.value : '';
    catRender();
  };

  window.catSetCat = function(btn, cat){
    state.cat = cat;
    document.querySelectorAll('.cat-cat-btn').forEach(function(b){ b.classList.remove('active'); });
    btn.classList.add('active');
    catRender();
  };

  document.addEventListener('DOMContentLoaded', function(){
    var s = document.getElementById('catSort');
    if(s) s.addEventListener('change', function(){ state.sort = this.value; catRender(); });
    catRender();

    // Tab switching handled by inline script after home.js load
  });
})();
// ── Notification Bell & Profile Dropdown (click-based) ────────────────
// ติดตามว่าเคย load ครั้งนี้แล้วหรือยัง (reset เมื่อ markSeen ถูกเรียก)
var _bellDataLoaded = false;

function _doMarkSeen() {
  var ctx = (window.StudyFlowConfig && window.StudyFlowConfig.contextPath) ? window.StudyFlowConfig.contextPath : '';
  fetch(ctx + '/api/notifications/markSeen', { method: 'POST', credentials: 'same-origin' })
      .then(function() {
        _updateHomeBadge(0);
        // ครั้งถัดไปที่เปิดให้ reload ข้อมูลใหม่
        _bellDataLoaded = false;
      })
      .catch(function() {});
}

function toggleBell(e) {
  e.stopPropagation();
  var drop = document.getElementById('navBellDrop');
  var btn  = document.getElementById('navBellBtn');
  var profileWrap = document.getElementById('navUserWrap');
  // ปิด profile ก่อน
  if (profileWrap) profileWrap.classList.remove('open');
  // toggle bell
  var wasOpen = drop.classList.contains('open');
  var isOpen  = !wasOpen;
  drop.classList.toggle('open', isOpen);
  btn.classList.toggle('open', isOpen);

  if (isOpen) {
    // เปิด: โหลดข้อมูลแสดงเท่านั้น — ไม่ markSeen เพื่อข้อมูลไม่หาย
    if (!_bellDataLoaded) {
      loadNotifications(function() {
        _bellDataLoaded = true;
        // badge ยังคงแสดงอยู่จนกว่าจะกด "Đã xem tất cả"
      });
    }
  }
  // ปิด dropdown: ไม่ markSeen อัตโนมัติ — ให้ user กดปุ่มเอง
}

function toggleProfile(e) {
  e.stopPropagation();
  var wrap = document.getElementById('navUserWrap');
  // ปิด bell ก่อน
  var bellDrop = document.getElementById('navBellDrop');
  var bellBtn  = document.getElementById('navBellBtn');
  if (bellDrop) { bellDrop.classList.remove('open'); }
  if (bellBtn)  { bellBtn.classList.remove('open'); }
  // toggle profile
  wrap.classList.toggle('open');
}

// ปิด dropdown เมื่อคลิกที่อื่น
document.addEventListener('click', function() {
  var wrap = document.getElementById('navUserWrap');
  var bellDrop = document.getElementById('navBellDrop');
  var bellBtn  = document.getElementById('navBellBtn');
  if (wrap)     wrap.classList.remove('open');
  if (bellDrop) bellDrop.classList.remove('open');
  if (bellBtn)  bellBtn.classList.remove('open');
});

// ──────────────────────────────────────────────────────────────────
//  NOTIFICATION BELL — โหลดจาก API จริง + poll badge ทุก 30 วินาที
// ──────────────────────────────────────────────────────────────────
function loadNotifications(onDone) {
  var list        = document.getElementById('navBellList');
  var headerCount = document.getElementById('navBellHeaderCount');
  var footer      = document.getElementById('navBellFooter');
  if (!list) { if (onDone) onDone(); return; }

  var ctx = (window.StudyFlowConfig && window.StudyFlowConfig.contextPath) ? window.StudyFlowConfig.contextPath : '';
  list.innerHTML = '<div class="nbd-empty"><span class="nbd-empty-icon" style="font-size:26px;">⏳</span><span style="font-size:13px;color:#94a3b8">Đang tải thông báo...</span></div>';
  if (headerCount) headerCount.style.display = 'none';
  if (footer)      footer.style.display = 'none';

  fetch(ctx + '/api/notifications/count', { credentials: 'same-origin' })
      .then(function(r) { return r.ok ? r.json() : null; })
      .then(function(data) {
        if (!data) {
          list.innerHTML = '<div class="nbd-empty"><span class="nbd-empty-icon">\u26A0\uFE0F</span>Không thể tải thông báo</div>';
          if (onDone) onDone(); return;
        }
        var total = data.total || 0;
        _updateHomeBadge(total);

        if (headerCount) {
          if (total > 0) { headerCount.textContent = total + ' m\u1EDBi'; headerCount.style.display = ''; }
          else { headerCount.style.display = 'none'; }
        }

        var apiItems = data.items || [];
        if (apiItems.length === 0) {
          list.innerHTML = '<div class="nbd-empty"><span class="nbd-empty-icon">\uD83D\uDD14</span>Không có thông báo mới</div>';
          if (footer) footer.style.display = 'none';
        } else {
          list.innerHTML = apiItems.map(function(n) {
            var href = n.href || '#';
            if (href !== '#' && href.charAt(0) === '/') href = ctx + href;
            if (n.type === 'header') {
              return '<div class="nbd-section-header">'
                  + '<span class="nbd-section-title">' + n.text + '</span>'
                  + (n.badge ? '<span class="nbd-section-badge">' + n.badge + '</span>' : '')
                  + '</div>';
            }
            var icon = n.icon || '\uD83D\uDD14';
            var iconBg = 'background:#f0f5ff';
            if (icon==='\uD83C\uDFEB') iconBg='background:#eff6ff';
            else if (icon==='\uD83C\uDFAC') iconBg='background:#fdf4ff';
            else if (icon==='\uD83D\uDCCB') iconBg='background:#fefce8';
            else if (icon==='\uD83D\uDCDD') iconBg='background:#fff7ed';
            else if (icon==='\uD83C\uDF93') iconBg='background:#f0fdf4';
            else if (icon==='\u23F3') iconBg='background:#fffbeb';
            return '<a class="nbd-item unread" href="' + href + '" style="text-decoration:none;">'
                + '<div class="nbd-icon" style="' + iconBg + '">' + icon + '</div>'
                + '<div class="nbd-body">'
                + '<div class="nbd-text">' + (n.text || '') + '</div>'
                + (n.time ? '<div class="nbd-time"><span class="nbd-unread-dot"></span>' + n.time + '</div>' : '')
                + '</div>'
                + '</a>';
          }).join('');
          if (footer) footer.style.display = '';
        }
        if (onDone) onDone();
      })
      .catch(function() {
        list.innerHTML = '<div class="nbd-empty"><span class="nbd-empty-icon">\u26A0\uFE0F</span>Không thể tải thông báo</div>';
        if (onDone) onDone();
      });
}


function _updateHomeBadge(total) {
  var badge = document.getElementById('navBellBadge');
  if (!badge) return;
  var prev = parseInt(badge.getAttribute('data-count') || '0', 10);
  // ถ้าจำนวนใหม่มากกว่าเดิม ให้ reload dropdown ครั้งถัดไป
  if (total > prev) _bellDataLoaded = false;
  badge.setAttribute('data-count', total);
  if (total > 0) {
    badge.classList.add('has-notif');
    badge.textContent = total <= 99 ? total : '99+';
  } else {
    badge.classList.remove('has-notif');
    badge.textContent = '';
  }
}

// Poll badge ทุก 30 วินาที (แม้ dropdown ยังไม่เปิด)
(function _pollHomeBadge() {
  var ctx = (window.StudyFlowConfig && window.StudyFlowConfig.contextPath) ? window.StudyFlowConfig.contextPath : '';
  fetch(ctx + '/api/notifications/count', { credentials: 'same-origin' })
      .then(function(r) { return r.ok ? r.json() : null; })
      .then(function(data) { if (data) _updateHomeBadge(data.total || 0); })
      .catch(function() {});
  setTimeout(_pollHomeBadge, 30000);
})();