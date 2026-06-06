<%@ page contentType="text/html;charset=UTF-8" %>
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8"/>
<meta name="viewport" content="width=device-width,initial-scale=1"/>
<title>Đăng nhập — StudyFlow Platform</title>
<link href="https://fonts.googleapis.com/css2?family=Be+Vietnam+Pro:wght@400;500;600;700;800&display=swap" rel="stylesheet"/>
<link rel="stylesheet" href="<%= request.getContextPath() %>/css/common.css">
<link rel="stylesheet" href="<%= request.getContextPath() %>/css/login.css">
</head>
<body>

<!-- ══ LEFT PANEL ════════════════════════════════════════════════ -->
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
            Chào mừng<br/>trở lại<span>!</span>
        </div>
        <p class="panel-desc">Đăng nhập để tiếp tục học hoặc khám phá các khóa học mới đang chờ bạn</p>
        <ul class="feature-list">
            <li><div class="feat-icon">📚</div>Hơn 100+ khóa học đa dạng</li>
            <li><div class="feat-icon">▶️</div>Video bài giảng sắc nét HD</li>
            <li><div class="feat-icon">📊</div>Theo dõi tiến độ theo thời gian thực</li>
            <li><div class="feat-icon">🏆</div>Nhận chứng chỉ khi hoàn thành khóa học</li>
        </ul>
    </div>
    <div class="panel-bottom">© 2025 StudyFlow Platform. Bảo lưu mọi quyền</div>
</div>

<!-- ══ RIGHT PANEL ════════════════════════════════════════════════ -->
<div class="right-panel">
<div class="form-card">

     <div class="row" style="display: flex; justify-content: space-between">
        <h1 class="form-title">Đăng nhập</h1>
        <a href="<%= request.getContextPath() %>/home" class="back-icon-btn" title="Quay về trang chủ">
            <svg width="25" height="25" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                <path d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"/>
            </svg>
        </a>
    </div>
    <p class="form-sub">Chưa có tài khoản? <a href="<%= request.getContextPath() %>/register" style="color:var(--accent);font-weight:600;text-decoration:none;">Đăng ký miễn phí</a></p>

    <%-- แสดง error จาก Model (Spring MVC) หรือ request param --%>
    <%
        String errorMsg = (String) request.getAttribute("error");
        // Spring Security ส่ง error ผ่าน session key นี้
        if (errorMsg == null && request.getParameter("error") != null) {
            Object springEx = session.getAttribute("SPRING_SECURITY_LAST_EXCEPTION");
            if (springEx != null) {
                String exMsg = springEx.toString();
                if (exMsg.contains("disabled") || exMsg.contains("Disabled")) {
                    errorMsg = "Tài khoản đang chờ phê duyệt hoặc bị vô hiệu hóa";
                } else if (exMsg.contains("locked") || exMsg.contains("Locked")) {
                    errorMsg = "Tài khoản đã bị từ chối";
                } else {
                    errorMsg = "Tên đăng nhập hoặc mật khẩu không đúng";
                }
            } else {
                errorMsg = "Tên đăng nhập hoặc mật khẩu không đúng";
            }
        }
    %>
    <% if (errorMsg != null) { %>
    <script>document.addEventListener('DOMContentLoaded',function(){ showToast('error','⚠️','Đăng nhập thất bại','<%= errorMsg.replace("'", "\\'") %>'); });</script>
    <% } %>

    <%-- สมัครสำเร็จ --%>
    <% if ("1".equals(request.getParameter("registered"))) { %>
    <script>document.addEventListener('DOMContentLoaded',function(){ showToast('success','✅','Đăng ký thành công!','Vui lòng đăng nhập bằng tài khoản đã tạo'); });</script>
    <% } %>

    <%-- ครูสมัครสำเร็จ รอการอนุมัติ --%>
    <% if ("2".equals(request.getParameter("registered"))) { %>
    <script>document.addEventListener('DOMContentLoaded',function(){ showToast('pending','⏳','Chờ phê duyệt','Đăng ký làm giảng viên thành công. Vui lòng đợi Admin kiểm tra và phê duyệt tài khoản của bạn trước khi có thể đăng nhập.'); });</script>
    <% } %>

    <%-- ตั้งค่า super admin สำเร็จ --%>
    <% if ("done".equals(request.getParameter("setup"))) { %>
    <script>document.addEventListener('DOMContentLoaded',function(){ showToast('success','👑','Thiết lập thành công!','Hệ thống Super Admin đã sẵn sàng sử dụng'); });</script>
    <% } %>

    <form action="<%= request.getContextPath() %>/login" method="post" novalidate>
      <%-- ส่ง redirect parameter ต่อ --%>
      <% String _redirect = request.getParameter("redirect"); %>
      <% if (_redirect != null && !_redirect.isEmpty()) { %>
      <input type="hidden" name="redirect" value="<%= _redirect %>"/>
      <% } %>

        <div class="field">
            <label for="username">Tên đăng nhập</label>
            <input type="text" id="username" name="username"
                   placeholder="Nhập tên đăng nhập" required autofocus/>
        </div>

        <div class="field">
            <label for="password">Mật khẩu</label>
            <div class="pw-wrap">
                <input type="password" id="password" name="password"
                       placeholder="Nhập mật khẩu" required/>
                <button type="button" class="pw-toggle" onclick="togglePw()">👁️</button>
            </div>
        </div>

        <div class="options-row">
            <label class="remember">
                <input type="checkbox" name="remember"/> Ghi nhớ đăng nhập
            </label>
            <a href="#" class="forgot-link">Quên mật khẩu?</a>
        </div>

        <button type="submit" class="btn-primary">
            🔑 Đăng nhập
        </button>

    </form>

    <div class="or-divider">hoặc</div>

    <a href="<%= request.getContextPath() %>/register" class="btn-secondary">
        ✨ Đăng ký tài khoản mới
    </a>

</div>
</div>

<!-- ══ TOAST MODAL ══ -->
<div id="toastModal" class="modal-overlay">
  <div onclick="closeToast()" class="modal-backdrop"></div>
  <div class="modal-card" style="animation: toastIn .25s cubic-bezier(.34,1.56,.64,1);">
    <div id="toastIcon"    style="font-size:54px;margin-bottom:14px;line-height:1;"></div>
    <div id="toastTitle"   style="font-size:20px;font-weight:800;color:#1a2332;margin-bottom:8px;"></div>
    <div id="toastMessage" style="font-size:14px;color:#64748b;line-height:1.65;margin-bottom:28px;"></div>
    <button onclick="closeToast()" id="toastBtn"
      style="width:100%;padding:13px 0;border-radius:12px;border:none;color:#fff;font-size:15px;font-weight:700;cursor:pointer;transition:opacity .15s;"
      onmouseenter="this.style.opacity='.88'" onmouseleave="this.style.opacity='1'">
      Đồng ý
    </button>
  </div>
</div>

<script src="<%= request.getContextPath() %>/js/common.js"></script>
<script src="<%= request.getContextPath() %>/js/login.js"></script>
</body>
</html>
