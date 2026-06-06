var _toastColors = {
  success: 'linear-gradient(135deg,#10b981,#059669)',
  error:   'linear-gradient(135deg,#ef4444,#dc2626)',
  pending: 'linear-gradient(135deg,#f59e0b,#d97706)'
};

function showToast(type, icon, title, message) {
  var iconEl = document.getElementById('toastIcon');
  var titleEl = document.getElementById('toastTitle');
  var msgEl = document.getElementById('toastMessage');
  var btnEl = document.getElementById('toastBtn');
  var modalEl = document.getElementById('toastModal');

  if (iconEl) iconEl.textContent = icon;
  if (titleEl) titleEl.textContent = title;
  if (msgEl) msgEl.textContent = message;
  if (btnEl) btnEl.style.background = _toastColors[type] || _toastColors.success;
  if (modalEl) modalEl.style.display = 'flex';
}

function closeToast() {
  var modalEl = document.getElementById('toastModal');
  if (modalEl) modalEl.style.display = 'none';
}

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
  var modalEl = document.getElementById('notifyModal');
  if (modalEl) modalEl.style.display = 'none';
}

// Global escape key listener for modals
document.addEventListener('keydown', function(e) {
  if (e.key === 'Escape') {
    closeToast();
    closeNotifyModal();
    if (typeof closeApprovalModal === 'function') closeApprovalModal();
    if (typeof closeConfirmModal === 'function') {
      closeConfirmModal('confirmEditModal');
      closeConfirmModal('confirmDeleteModal');
    }
  }
});
