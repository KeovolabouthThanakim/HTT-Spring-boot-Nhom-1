<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="com.example.demo.dao.UserDAO" %>
<%
    /* ── GUARD: Nếu đã có super_admin → chuyển hướng ngay, không hiển thị trang ── */
    org.springframework.web.context.WebApplicationContext _wac = org.springframework.web.context.support.WebApplicationContextUtils.getWebApplicationContext(application);
    UserDAO dao = _wac.getBean(UserDAO.class);
    if (dao.superAdminExists()) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Thiết lập Super Admin – StudyFlow</title>
    <link rel="stylesheet" href="css/super-admin-setup.css">
</head>
<body>

<div class="setup-card">

    <div class="crown">👑</div>
    <h2>Thiết lập Super Admin</h2>
    <p class="subtitle">Tạo tài khoản quản trị viên cấp cao nhất của hệ thống</p>

    <!-- Cảnh báo: chỉ thực hiện được một lần -->
    <div class="warning-box">
        <span>⚠️</span>
        <span>
            Trang này chỉ sử dụng được <strong>một lần duy nhất</strong><br>
            Sau khi tạo Super Admin, bạn sẽ không thể tạo mới
            hoặc chỉnh sửa thông tin qua hệ thống web nữa
        </span>
    </div>

    <!-- Thông báo lỗi -->
    <% if (request.getAttribute("error") != null) { %>
        <div class="error-box">⚠️ <%= request.getAttribute("error") %></div>
    <% } %>

    <form action="super-admin-setup" method="post">

        <label for="username">Tên đăng nhập (Username)</label>
        <input type="text" id="username" name="username"
               placeholder="Nhập tên đăng nhập" required autofocus
               value="<%= request.getParameter("username") != null
                          ? request.getParameter("username") : "" %>">

        <label for="password">Mật khẩu (ít nhất 8 ký tự)</label>
        <input type="password" id="password" name="password"
               placeholder="Nhập mật khẩu" required minlength="8">

        <label for="confirmPassword">Xác nhận mật khẩu</label>
        <input type="password" id="confirmPassword" name="confirmPassword"
               placeholder="Nhập lại mật khẩu" required minlength="8">

        <button type="submit" class="btn-submit">👑 Tạo Super Admin</button>

    </form>

    <p class="lock-note">🔒 Sau khi tạo, trang này sẽ bị đóng vĩnh viễn</p>

</div>

</body>
</html>
