<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="com.example.demo.dao.UserDAO" %>
<%
    /* ถ้า login อยู่แล้ว → ออกไป dashboard */
    if (session.getAttribute("user") != null) {
        response.sendRedirect(request.getContextPath() + "/dashboard");
        return;
    }
    /* ดึงค่า repopulate จาก servlet */
    String pUsername   = request.getAttribute("p_username")   != null ? (String) request.getAttribute("p_username")   : "";
    String pFirstName  = request.getAttribute("p_firstName")  != null ? (String) request.getAttribute("p_firstName")  : "";
    String pLastName   = request.getAttribute("p_lastName")   != null ? (String) request.getAttribute("p_lastName")   : "";
    String pEmail      = request.getAttribute("p_email")      != null ? (String) request.getAttribute("p_email")      : "";
    String pStudentId  = request.getAttribute("p_studentId")  != null ? (String) request.getAttribute("p_studentId")  : "";
    String pDepartment = request.getAttribute("p_department") != null ? (String) request.getAttribute("p_department") : "";
    String pRole       = request.getAttribute("p_role")       != null ? (String) request.getAttribute("p_role")       : "STUDENT";
    String errorMsg    = request.getAttribute("error")        != null ? (String) request.getAttribute("error")        : null;
%>
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8"/>
<meta name="viewport" content="width=device-width,initial-scale=1"/>
<title>Đăng ký — StudyFlow Platform</title>
<link href="https://fonts.googleapis.com/css2?family=Be+Vietnam+Pro:wght@400;500;600;700;800&display=swap" rel="stylesheet"/>
<link rel="stylesheet" href="css/register.css">
</head>
<body>

<!-- ══ LEFT PANEL ═══════════════════════════════════════════════ -->
<div class="left-panel">
    <div class="panel-grid"></div>
    <div class="panel-top">
        <div class="brand">
            <div class="brand-logo">
                <img src="<%= request.getContextPath() %>/logo/StudyFlow.png" alt="StudyFlow Logo" style="height: 40px; width: auto; vertical-align: middle;">
            </div>
            <div class="brand-name">StudyFlow Platform</div>
        </div>
        <div class="panel-headline">
            Học không<br/>có <span>giới hạn</span>
        </div>
        <p class="panel-desc">Nền tảng học trực tuyến kết nối giảng viên và học viên. Truy cập các khóa học chất lượng mọi lúc, mọi nơi</p>
        <ul class="feature-list">
            <li><div class="feat-icon">📚</div>Hơn 100+ khóa học đa dạng</li>
            <li><div class="feat-icon">▶️</div>Video bài giảng sắc nét HD</li>
            <li><div class="feat-icon">📊</div>Theo dõi tiến độ theo thời gian thực</li>
            <li><div class="feat-icon">🏆</div>Nhận chứng chỉ khi hoàn thành</li>
        </ul>
    </div>
    <div class="panel-bottom">© 2025 StudyFlow Platform. Bảo lưu mọi quyền</div>
</div>

<!-- ══ RIGHT PANEL ══════════════════════════════════════════════ -->
<div class="right-panel">
<div class="form-card">

    <div class="row" style="display: flex; justify-content: space-between">
        <h1 class="form-title">Tạo tài khoản mới</h1>
        <a href="<%= request.getContextPath() %>/home" class="back-icon-btn" title="Quay về trang chủ">
            <svg width="25" height="25" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                <path d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"/>
            </svg>
        </a>
    </div>
    <p class="form-sub">Đã có tài khoản? <a href="<%= request.getContextPath() %>/login">Đăng nhập</a></p>

    <!-- Error -->
    <% if (errorMsg != null) { %>
    <div class="error-box">⚠️ <%= errorMsg %></div>
    <% } %>

    <form action="<%= request.getContextPath() %>/register" method="post" id="regForm" novalidate>

        <!-- ── ประเภทบัญชี ── -->
        <div class="sec-label">Tôi muốn đăng ký là</div>
        <div class="role-selector">

            <input type="radio" name="role" id="roleStudent" value="STUDENT" class="role-option"
                   <%= "STUDENT".equals(pRole) || pRole.isEmpty() ? "checked" : "" %>>
            <label for="roleStudent" class="role-label">
                <span class="role-icon">🎓</span>
                <span class="role-name">Học viên</span>
                <span class="role-desc">Tham gia khóa học<br/>trực tuyến</span>
            </label>

            <input type="radio" name="role" id="roleTeacher" value="TEACHER" class="role-option"
                   <%= "TEACHER".equals(pRole) ? "checked" : "" %>>
            <label for="roleTeacher" class="role-label">
                <span class="role-icon">👨‍🏫</span>
                <span class="role-name">Giảng viên</span>
                <span class="role-desc">Tạo và giảng dạy<br/>khóa học</span>
            </label>

        </div>

        <hr class="divider"/>

        <!-- ── Thông tin cá nhân ── -->
        <div class="sec-label">Thông tin cá nhân</div>

        <div class="row-2">
            <div class="field">
                <label for="firstName">Họ <span class="req">*</span></label>
                <input type="text" id="firstName" name="firstName"
                       placeholder="Họ của bạn" value="<%= pFirstName %>" required/>
            </div>
            <div class="field">
                <label for="lastName">Tên <span class="req">*</span></label>
                <input type="text" id="lastName" name="lastName"
                       placeholder="Tên của bạn" value="<%= pLastName %>" required/>
            </div>
        </div>

        <div class="field">
            <label for="email">Email <span class="req">*</span></label>
            <input type="email" id="email" name="email"
                   placeholder="example@email.com" value="<%= pEmail %>" required/>
        </div>

        <!-- Student-only fields -->
        <div id="studentSection" class="<%= "TEACHER".equals(pRole) ? "hidden" : "" %>">
            <div class="row-2">
                <div class="field">
                    <label for="studentId">Mã số sinh viên</label>
                    <input type="text" id="studentId" name="studentId"
                           placeholder="VD: 65010001" value="<%= pStudentId %>"/>
                </div>
                <div class="field">
                    <label for="department">Khoa / Ngành</label>
                    <input type="text" id="department" name="department"
                           placeholder="VD: Công nghệ thông tin" value="<%= pDepartment %>"/>
                </div>
            </div>
        </div>

        <hr class="divider"/>

        <!-- ── Thông tin tài khoản ── -->
        <div class="sec-label">Thông tin tài khoản</div>

        <div class="field">
            <label for="username">Tên đăng nhập <span class="req">*</span></label>
            <input type="text" id="username" name="username"
                   placeholder="Chữ a-z, 0-9, _ (4–50 ký tự)"
                   value="<%= pUsername %>" required minlength="4" maxlength="50"
                   pattern="[a-zA-Z0-9_]+"/>
        </div>

        <div class="field">
            <label for="password">Mật khẩu <span class="req">*</span></label>
            <div class="pw-wrap">
                <input type="password" id="password" name="password"
                       placeholder="Ít nhất 8 ký tự" required minlength="8"/>
                <button type="button" class="pw-toggle" onclick="togglePw('password',this)">👁️</button>
            </div>
            <div class="strength-bar" id="strengthBar">
                <div class="sb-seg" id="s1"></div>
                <div class="sb-seg" id="s2"></div>
                <div class="sb-seg" id="s3"></div>
                <div class="sb-seg" id="s4"></div>
            </div>
            <div class="strength-label" id="strengthLabel"></div>
        </div>

        <div class="field">
            <label for="confirmPassword">Xác nhận mật khẩu <span class="req">*</span></label>
            <div class="pw-wrap">
                <input type="password" id="confirmPassword" name="confirmPassword"
                       placeholder="Nhập lại mật khẩu" required/>
                <button type="button" class="pw-toggle" onclick="togglePw('confirmPassword',this)">👁️</button>
            </div>
        </div>

        <button type="submit" class="btn-submit">
            <span>✨</span> Tạo tài khoản
        </button>

    </form>

    <p class="terms">
        Khi đăng ký, bạn đồng ý với
        <a href="#">Điều khoản sử dụng</a> và
        <a href="#">Chính sách bảo mật</a>
    </p>

</div>
</div>

<script>
/* ── Toggle password visibility ── */
function togglePw(id, btn) {
    const input = document.getElementById(id);
    const isText = input.type === 'text';
    input.type = isText ? 'password' : 'text';
    btn.textContent = isText ? '👁️' : '🙈';
}

/* ── Password strength ── */
document.getElementById('password').addEventListener('input', function () {
    const val = this.value;
    let score = 0;
    if (val.length >= 8)  score++;
    if (/[A-Z]/.test(val)) score++;
    if (/[0-9]/.test(val)) score++;
    if (/[^a-zA-Z0-9]/.test(val)) score++;

    const colors = ['', '#e03131', '#f59f00', '#0ca678', '#3b5bdb'];
    const labels = ['', 'Rất yếu', 'Trung bình', 'Tốt', 'Mạnh'];
    const segs = ['s1','s2','s3','s4'];

    segs.forEach((id, i) => {
        document.getElementById(id).style.background =
            i < score ? colors[score] : 'var(--line)';
    });
    document.getElementById('strengthLabel').textContent =
        val.length ? labels[score] : '';
    document.getElementById('strengthLabel').style.color = colors[score];
});

/* ── Student section toggle ── */
document.querySelectorAll('input[name="role"]').forEach(r => {
    r.addEventListener('change', function () {
        const sec = document.getElementById('studentSection');
        sec.classList.toggle('hidden', this.value === 'TEACHER');
    });
});

/* ── Client-side validation before submit ── */
document.getElementById('regForm').addEventListener('submit', function (e) {
    const pw  = document.getElementById('password').value;
    const cpw = document.getElementById('confirmPassword').value;
    if (pw !== cpw) {
        e.preventDefault();
        showAlertModal('🔐', 'Mật khẩu không khớp', 'Vui lòng kiểm tra và nhập mật khẩu giống nhau ở cả hai ô', function(){
            document.getElementById('confirmPassword').focus();
        });
    }
});

function showAlertModal(icon, title, message, onClose) {
    document.getElementById('alertIcon').textContent    = icon;
    document.getElementById('alertTitle').textContent   = title;
    document.getElementById('alertMessage').textContent = message;
    document._alertOnClose = onClose || null;
    document.getElementById('alertModal').style.display = 'flex';
}
function closeAlertModal() {
    document.getElementById('alertModal').style.display = 'none';
    if (document._alertOnClose) document._alertOnClose();
}
document.addEventListener('keydown', function(e){ if(e.key==='Escape') closeAlertModal(); });
</script>

<!-- ══ CUSTOM ALERT MODAL ══ -->
<div id="alertModal" style="display:none;position:fixed;inset:0;z-index:9999;align-items:center;justify-content:center;">
  <div onclick="closeAlertModal()" style="position:absolute;inset:0;background:rgba(15,23,42,.4);backdrop-filter:blur(4px);"></div>
  <div style="position:relative;background:#fff;border-radius:20px;padding:36px 32px 28px;width:340px;max-width:90vw;box-shadow:0 24px 60px rgba(0,0,0,.16);animation:alertIn .22s ease;text-align:center;">
    <div id="alertIcon"    style="font-size:50px;margin-bottom:12px;"></div>
    <div id="alertTitle"   style="font-size:18px;font-weight:700;color:#1a2332;margin-bottom:8px;"></div>
    <div id="alertMessage" style="font-size:14px;color:#64748b;line-height:1.6;margin-bottom:28px;"></div>
    <button onclick="closeAlertModal()"
      style="width:100%;padding:12px 0;border-radius:10px;border:none;background:linear-gradient(135deg,#6366f1,#4f46e5);color:#fff;font-size:14px;font-weight:700;cursor:pointer;transition:opacity .15s;"
      onmouseenter="this.style.opacity='.88'" onmouseleave="this.style.opacity='1'">
      Đồng ý
    </button>
  </div>
</div>
<style>
@keyframes alertIn {
  from { opacity:0; transform:translateY(16px) scale(.96); }
  to   { opacity:1; transform:translateY(0)    scale(1);   }
}
</style>

</body>
</html>
