function togglePw() {
    const input = document.getElementById('password');
    const btn = document.querySelector('.pw-toggle');
    const isHidden = input.type === 'password';
    input.type = isHidden ? 'text' : 'password';
    btn.textContent = isHidden ? '🙈' : '👁️';
}
