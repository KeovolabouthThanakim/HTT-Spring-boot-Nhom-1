/* ── REVIEW MODAL ── */
function openReviewModal(hwId, studentName, hwTitle) {
  document.getElementById('reviewHwId').value              = hwId;
  document.getElementById('reviewStudentName').textContent = studentName || '—';
  document.getElementById('reviewHwTitle').textContent     = hwTitle     || '—';
  document.getElementById('reviewComment').value           = '';

  // reset ฟิลด์คะแนน
  var scoreEl = document.getElementById('reviewScore');
  var maxEl   = document.getElementById('reviewMaxScore');
  if (scoreEl)  scoreEl.value  = '';
  if (maxEl)    maxEl.value    = '100';
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
    bar.style.width     = '0%';
    label.textContent   = '—';
    bar.style.background = 'linear-gradient(90deg,#22c55e,#16a34a)';
    return;
  }

  score = Math.max(0, Math.min(score, max));
  var pct = Math.round((score / max) * 100);

  bar.style.width = pct + '%';
  label.textContent = score + ' / ' + max + '  (' + pct + '%)';

  // เปลี่ยนสีตามคะแนน
  if (pct >= 80)      bar.style.background = 'linear-gradient(90deg,#22c55e,#16a34a)';
  else if (pct >= 50) bar.style.background = 'linear-gradient(90deg,#f59e0b,#d97706)';
  else                bar.style.background = 'linear-gradient(90deg,#f87171,#ef4444)';
}
