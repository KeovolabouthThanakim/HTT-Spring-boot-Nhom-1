/* ── TOAST ── */
function closeToast() {
  var el = document.getElementById('toastEl');
  var ov = document.getElementById('toastOverlay');
  if (!el) return;
  el.classList.add('hiding');
  setTimeout(function(){ if (ov) ov.style.display='none'; }, 220);
}
(function(){
  var ov = document.getElementById('toastOverlay');
  if (!ov) return;
  setTimeout(closeToast, 4000);
  ov.addEventListener('click', function(e){ if(e.target===ov) closeToast(); });
})();

/* ── TABS ── */
function switchTab(name, btn) {
  document.querySelectorAll('.section').forEach(function(s){ s.classList.remove('active'); });
  document.querySelectorAll('.tab-btn').forEach(function(b){ b.classList.remove('active'); });
  document.getElementById('tab-'+name).classList.add('active');
  btn.classList.add('active');
  window.scrollTo({top: document.querySelector('.tabs-wrap').offsetTop - 64, behavior:'smooth'});
}

/* ── MODALS ── */
function openModal(id)  { document.getElementById(id).classList.add('open'); }
function closeModal(id) { document.getElementById(id).classList.remove('open'); }

function openEditVideo(btn) {
  document.getElementById('editVideoId').value    = btn.dataset.id;
  document.getElementById('editVideoTitle').value = btn.dataset.title;
  document.getElementById('editVideoDesc').value  = btn.dataset.desc;
  document.getElementById('editVideoUrl').value   = btn.dataset.url;
  openModal('mEditVideo');
}
function openDeleteVideo(id, title) {
  document.getElementById('deleteVideoId').value = id;
  document.getElementById('deleteVideoTitle').textContent = title;
  var el = document.getElementById('mDeleteVideo');
  if (el) el.style.display = 'flex';
}
function closeModal(id) {
  var el = document.getElementById(id);
  if (!el) return;
  if (el.classList.contains('open')) el.classList.remove('open');
  else el.style.display = 'none';
}

/* ── REVIEW MODAL ── */
function openReviewModal(hwId, studentName, hwTitle) {
  document.getElementById('reviewHwId').value              = hwId;
  document.getElementById('reviewStudentName').textContent = studentName || '—';
  document.getElementById('reviewHwTitle').textContent     = hwTitle     || '—';
  document.getElementById('reviewComment').value           = '';
  var scoreEl = document.getElementById('reviewScore');
  var maxEl   = document.getElementById('reviewMaxScore');
  if (scoreEl) scoreEl.value = '';
  if (maxEl)   maxEl.value   = '100';
  updateScoreBar();
  openModal('mReviewHw');
}

/* ── SCORE PROGRESS BAR (live preview) ── */
function updateScoreBar() {
  var scoreEl = document.getElementById('reviewScore');
  var maxEl   = document.getElementById('reviewMaxScore');
  var bar     = document.getElementById('reviewScoreBar');
  var label   = document.getElementById('reviewScoreLabel');
  if (!scoreEl || !bar || !label) return;

  var score = parseFloat(scoreEl.value);
  var max   = parseFloat(maxEl ? maxEl.value : 100) || 100;

  if (isNaN(score) || scoreEl.value.trim() === '') {
    bar.style.width      = '0%';
    label.textContent    = '—';
    bar.style.background = 'linear-gradient(90deg,#22c55e,#16a34a)';
    return;
  }
  score = Math.max(0, Math.min(score, max));
  var pct = Math.round((score / max) * 100);
  bar.style.width    = pct + '%';
  label.textContent  = score + ' / ' + max + '  (' + pct + '%)';
  if (pct >= 80)      bar.style.background = 'linear-gradient(90deg,#22c55e,#16a34a)';
  else if (pct >= 50) bar.style.background = 'linear-gradient(90deg,#f59e0b,#d97706)';
  else                bar.style.background = 'linear-gradient(90deg,#f87171,#ef4444)';
}

/* ── HOMEWORK FORMS ── */
function toggleTeacherHwForm() {
  var f   = document.getElementById('teacherHwForm');
  var btn = document.getElementById('teacherHwBtn');
  var open = f.classList.toggle('open');
  btn.textContent = open ? '✕ Đóng' : '📤 Tải lên tệp';
  if (open) setTimeout(function(){ f.scrollIntoView({behavior:'smooth',block:'nearest'}); }, 80);
}
function toggleHw() {
  var f   = document.getElementById('hwForm');
  var btn = document.getElementById('hwBtn');
  var open = f.classList.toggle('open');
  btn.textContent = open ? '✕ Đóng' : '✏️ Nộp bài tập';
  if (open) setTimeout(function(){ f.scrollIntoView({behavior:'smooth',block:'nearest'}); }, 80);
}

/* ── VIDEO URL VALIDATION ── */
(function(){
  document.querySelectorAll('form').forEach(function(form){
    var u = form.querySelector('input[name="videoUrl"]');
    if (!u) return;
    form.addEventListener('submit', function(e){
      var val = u.value.trim();
      if (!val) return;
      var ok = /^https?:\/\/(www\.)?(youtube\.com\/(watch|embed)|youtu\.be\/|drive\.google\.com\/)/.test(val);
      if (!ok) {
        e.preventDefault();
        u.style.border = '2px solid #ef4444';
        var msg = form.querySelector('.url-err');
        if (!msg) { msg = document.createElement('div'); msg.className='url-err'; msg.style.cssText='color:#ef4444;font-size:12px;margin-top:4px;'; u.parentNode.appendChild(msg); }
        msg.textContent = '⚠️ URL phải là YouTube hoặc Google Drive';
        u.focus();
      }
    });
    u.addEventListener('input', function(){
      u.style.border='';
      var msg = form.querySelector('.url-err');
      if (msg) msg.textContent='';
    });
  });
})();

/* ── OVERLAY CLICK / ESC ── */
document.querySelectorAll('.overlay').forEach(function(el){
  el.addEventListener('click', function(e){ if(e.target===el) el.classList.remove('open'); });
});
document.addEventListener('keydown', function(e){
  if (e.key==='Escape') document.querySelectorAll('.overlay.open').forEach(function(el){ el.classList.remove('open'); });
});

/* ── AUTO TAB + SCROLL FROM URL ── */
(function(){
  var params = new URLSearchParams(window.location.search);
  var tab = params.get('tab');
  if (!tab) return;
  var btn = document.querySelector('.tab-btn[onclick*="'+tab+'"]');
  if (btn) {
    btn.click();
    setTimeout(function(){
      var sec = document.getElementById('tab-'+tab);
      if (sec) sec.scrollIntoView({behavior:'smooth', block:'start'});
    }, 150);
  }
})();
/* ── STAR RATING ── */
var _ratingLabels = ['','Rất tệ','Không tốt','Bình thường','Tốt','Xuất sắc'];
function setRating(val) {
  document.getElementById('ratingInput').value = val;
  document.querySelectorAll('.star-btn').forEach(function(s){
    var sv = parseInt(s.getAttribute('data-val'));
    s.style.color = sv <= val ? '#f59e0b' : '#d1d5db';
  });
  var lbl = document.getElementById('ratingLabel');
  if (lbl) lbl.textContent = val + '  sao — ' + (_ratingLabels[val] || '');
}
(function(){
  document.querySelectorAll('.star-btn').forEach(function(s){
    s.addEventListener('mouseover', function(){
      var v = parseInt(s.getAttribute('data-val'));
      document.querySelectorAll('.star-btn').forEach(function(x){
        x.style.color = parseInt(x.getAttribute('data-val')) <= v ? '#fbbf24' : '#d1d5db';
      });
    });
    s.addEventListener('mouseout', function(){
      var cur = parseInt(document.getElementById('ratingInput').value);
      document.querySelectorAll('.star-btn').forEach(function(x){
        x.style.color = parseInt(x.getAttribute('data-val')) <= cur ? '#f59e0b' : '#d1d5db';
      });
    });
  });
})();
// Delete Homework Modal
function openDeleteHw(id, title) {
  var m = document.getElementById('mDeleteHw');
  var txt = document.getElementById('mDeleteHw-text');
  var btn = document.getElementById('mDeleteHw-btn');
  document.getElementById('fDeleteHw-id').value = id;
  if (txt) txt.textContent = 'Bạn có chắc muốn xóa "' + (title || 'bài tập này') + '"?';
  btn.onclick = function() { document.getElementById('fDeleteHw').submit(); };
  m.style.display = 'flex';
}
function closeDeleteHw() {
  document.getElementById('mDeleteHw').style.display = 'none';
}

// Delete Review Modal
function openDeleteReview(id) {
  var m = document.getElementById('mDeleteReview');
  var btn = document.getElementById('mDeleteReview-btn');
  document.getElementById('fDeleteReview-id').value = id;
  btn.onclick = function() { document.getElementById('fDeleteReview').submit(); };
  m.style.display = 'flex';
}
function closeDeleteReview() {
  document.getElementById('mDeleteReview').style.display = 'none';
}