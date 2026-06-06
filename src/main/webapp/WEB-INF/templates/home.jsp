<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"
         import="com.example.demo.dto.CourseDTO, com.example.demo.entity.User, com.example.demo.dto.VideoDTO, com.example.demo.service.VideoService,
                 com.example.demo.dto.TeacherReviewDTO,
                 java.util.List, java.util.ArrayList, java.util.HashMap, java.util.Map" %>
<%
// ─── Session guard ────────────────────────────────────────────
User _sessionUser = (User) request.getAttribute("user");
if (_sessionUser == null) {
    _sessionUser = (User) session.getAttribute("user");
}

org.springframework.web.context.WebApplicationContext _wac = org.springframework.web.context.support.WebApplicationContextUtils.getWebApplicationContext(application);
VideoService _videoSvc = _wac.getBean(VideoService.class);
%>

<%
// ─── Load courses ส่งมาจาก HomeController ─────────────────────
@SuppressWarnings("unchecked")
List<CourseDTO> _allCourses = (List<CourseDTO>) request.getAttribute("allCourses");
if (_allCourses == null) _allCourses = new java.util.ArrayList<>();
Long _activeCourseCountLong = (Long) request.getAttribute("activeCourseCount");

// Build JSON array for JS catalog
StringBuilder _coursesJson = new StringBuilder("[");
String[] _catGrads = {
    "linear-gradient(135deg,#1e3a5f,#2563eb)",
    "linear-gradient(135deg,#4c1d95,#7c3aed)",
    "linear-gradient(135deg,#064e3b,#10b981)",
    "linear-gradient(135deg,#7c2d12,#ea580c)",
    "linear-gradient(135deg,#1e1b4b,#4f46e5)",
    "linear-gradient(135deg,#0c4a6e,#0284c7)",
    "linear-gradient(135deg,#1c1917,#78716c)",
    "linear-gradient(135deg,#042f2e,#0d9488)",
    "linear-gradient(135deg,#1e3a5f,#dc2626)"
};
Map<String,String> _catIcons = new HashMap<>();
_catIcons.put("Programming","💻"); _catIcons.put("Design","🎨");
_catIcons.put("Business","💼"); _catIcons.put("Language","🌐");
_catIcons.put("Math","📐"); _catIcons.put("Science","🔬");
_catIcons.put("General","📖"); _catIcons.put("Other","✨");
_catIcons.put("Lập trình","💻"); _catIcons.put("Thiết kế","🎨");
_catIcons.put("Kinh doanh","💼");

boolean _firstCourse = true;
for (int _ci = 0; _ci < _allCourses.size(); _ci++) {
    CourseDTO _c = _allCourses.get(_ci);
    if (!"ACTIVE".equalsIgnoreCase(_c.getStatus())) continue;
    if (!_firstCourse) _coursesJson.append(",");
    _firstCourse = false;
    String _grad = _catGrads[_ci % _catGrads.length];
    int _enrollCount = _c.getStudentCount();
    int _videoCount = _c.getVideoCount();
    String _teacherName = _c.getTeacherName().trim();
    String _desc = _c.getDescription() != null ? _c.getDescription().replace("\\","\\\\").replace("\"","\\\"").replace("\n"," ").replace("\r","") : "";
    String _name = _c.getName().replace("\\","\\\\").replace("\"","\\\"");
    String _cat = _c.getCategory() != null ? _c.getCategory() : "General";
    String _catIcon = _catIcons.getOrDefault(_cat, "📚");
    String _tName = _teacherName.isEmpty() ? "Giảng viên" : _teacherName.replace("\"","\\\"");
    // createdAt: check if within last 30 days
    boolean _isNew = false;
    if (_c.getCreatedAt() != null && !_c.getCreatedAt().isEmpty()) {
        try {
            java.text.SimpleDateFormat _sdf = new java.text.SimpleDateFormat("yyyy-MM-dd");
            java.util.Date _created = _sdf.parse(_c.getCreatedAt().substring(0,10));
            long _diffDays = (System.currentTimeMillis() - _created.getTime()) / (1000*60*60*24);
            _isNew = _diffDays <= 30;
        } catch(Exception _ignore){}
    }
    _coursesJson.append("{")
        .append("\"id\":").append(_c.getId()).append(",")
        .append("\"name\":\"").append(_name).append("\",")
        .append("\"inst\":\"").append(_tName).append("\",")
        .append("\"cat\":\"").append(_cat).append("\",")
        .append("\"catIcon\":\"").append(_catIcon).append("\",")
        .append("\"desc\":\"").append(_desc.length() > 100 ? _desc.substring(0,100)+"..." : _desc).append("\",")
        .append("\"students\":").append(_enrollCount).append(",")
        .append("\"videos\":").append(_videoCount).append(",")
        .append("\"grad\":\"").append(_grad).append("\",")
        .append("\"isNew\":").append(_isNew).append(",");
    // ── Thumbnail: YouTube ID จากวิดีโอแรกของคอร์ส ──────────────────
    String _thumb = "";
    java.util.List<com.example.demo.dto.VideoDTO> _vids2 = _videoSvc.getVideosByCourse(_c.getId());
    if (!_vids2.isEmpty()) {
        String _vurl = _vids2.get(0).getFilePath();
        if (_vurl != null && !_vurl.isEmpty()) {
            java.util.regex.Matcher _ytm = java.util.regex.Pattern
                .compile("(?:v=|youtu\\.be/|/embed/)([A-Za-z0-9_-]{11})")
                .matcher(_vurl);
            if (_ytm.find()) {
                _thumb = "https://img.youtube.com/vi/" + _ytm.group(1) + "/mqdefault.jpg";
            }
        }
    }
    String _tPhoto = _c.getTeacherPhoto() != null && !_c.getTeacherPhoto().trim().isEmpty()
        ? request.getContextPath() + "/uploads/" + _c.getTeacherPhoto().replace("\\","\\\\").replace("\"","\\\"") : "";
    _coursesJson.append("\"thumb\":\"").append(_thumb).append("\",")
        .append("\"teacherPhoto\":\"").append(_tPhoto).append("\"")
        .append("}");
}
_coursesJson.append("]");

// ── Dữ liệu hồ sơ học viên ──────────────────────────────────────────
@SuppressWarnings("unchecked")
List<CourseDTO> _enrolledCourses = (List<CourseDTO>) request.getAttribute("enrolledCourses");
if (_enrolledCourses == null) _enrolledCourses = new java.util.ArrayList<>();
Integer _enrolledCount = (Integer) request.getAttribute("enrolledCount");
if (_enrolledCount == null) _enrolledCount = 0;

@SuppressWarnings("unchecked")
List<TeacherReviewDTO> _myReviews = (List<TeacherReviewDTO>) request.getAttribute("myReviews");
if (_myReviews == null) _myReviews = new java.util.ArrayList<>();

// Count categories
Map<String,Integer> _catCounts = new HashMap<>();
for (CourseDTO _c : _allCourses) {
    if (!"ACTIVE".equalsIgnoreCase(_c.getStatus())) continue;
    String _cat = _c.getCategory() != null ? _c.getCategory() : "General";
    _catCounts.put(_cat, _catCounts.getOrDefault(_cat, 0) + 1);
}
int _totalActive = (int)(_activeCourseCountLong != null ? _activeCourseCountLong : 0);
// for (int v : _catCounts.values()) _totalActive += v; // replaced by controller
%>
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8"/>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
<meta name="viewport" content="width=device-width,initial-scale=1"/>
<title>StudyFlow — Nền Tảng Học Trực Tuyến</title>
<link href="https://fonts.googleapis.com/css2?family=Nunito:wght@400;600;700;800;900&family=Space+Mono:wght@700&display=swap" rel="stylesheet"/>
<link rel="stylesheet" href="<%= request.getContextPath() %>/css/home.css">
<style>
@keyframes notifyPop{from{opacity:0;transform:scale(.88)}to{opacity:1;transform:scale(1)}}
</style>
</head>

<body>

<!-- ═══ NAVBAR ═══ -->
<nav id="mainNav">
  <div class="nav-brand" onclick="showPage('home')">
    <div class="nav-logo">
      <img src="<%= request.getContextPath() %>/logo/StudyFlow.png" alt="StudyFlow Logo" style="height: 40px; width: auto; vertical-align: middle;">
    </div>
    <div class="nav-name">StudyFlow</div>
    <div class="nav-tag">MIỄN PHÍ</div>
  </div>
  <ul class="nav-links">
    <li><a id="nav-home" class="active" onclick="showPage('home')">Trang chủ</a></li>
    <li><a id="nav-tinh-nang" onclick="showPage('tinh-nang')">Tính năng</a></li>
    <li><a id="nav-khoa-hoc" onclick="showPage('khoa-hoc')">Khóa học</a></li>
    <li><a id="nav-hoc-phi" onclick="showPage('hoc-phi')">Học phí</a></li>
    <li><a id="nav-lien-he" onclick="showPage('lien-he')">Liên hệ</a></li>
    <% if (_sessionUser != null && "STUDENT".equalsIgnoreCase(_sessionUser.getRole())) { %>
    <li><a id="nav-ho-so" onclick="showPage('ho-so')">Hồ sơ</a></li>
    <% } %>
  </ul>
  <div class="nav-right">
    <% if (_sessionUser != null) { %>
    <!-- Notification Bell -->
    <div class="nav-bell-wrap" id="navBellWrap">
      <button class="nav-bell-btn" id="navBellBtn" onclick="toggleBell(event)" title="Thông báo">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/></svg>
        <span class="nav-bell-badge" id="navBellBadge"></span>
      </button>
      <div class="nav-bell-dropdown" id="navBellDrop">
        <div class="nbd-header">
          <div class="nbd-header-title">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" style="width:18px;height:18px;color:#3b5bdb"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/></svg>
            Thông báo
          </div>
          <span class="nbd-header-count" id="navBellHeaderCount" style="display:none"></span>
        </div>
        <div class="nbd-list" id="navBellList">
          <div class="nbd-empty">
            <span class="nbd-empty-icon">🔔</span>
            Không có thông báo mới
          </div>
        </div>
        <div class="nbd-footer" id="navBellFooter" style="display:none">
          <a href="javascript:void(0)" onclick="(function(){document.getElementById('navBellDrop').classList.remove('open');document.getElementById('navBellBtn').classList.remove('open');_doMarkSeen();})()">
            ✓ Đánh dấu đã đọc tất cả
          </a>
        </div>
      </div>
    </div>
    <div class="nav-user-wrap" id="navUserWrap" onclick="toggleProfile(event)">
      <%
        String _fn = _sessionUser.getFirstName();
        String _ln = _sessionUser.getLastName();
        String _initials = "";
        if (_fn != null && !_fn.isEmpty()) _initials += _fn.charAt(0);
        if (_ln != null && !_ln.isEmpty()) _initials += _ln.charAt(0);
        if (_initials.isEmpty()) _initials = _sessionUser.getUsername().substring(0,1).toUpperCase();
        String _displayName = "";
        if (_sessionUser.getFirstName() != null && !_sessionUser.getFirstName().isEmpty())
          _displayName = _sessionUser.getFirstName() + (_sessionUser.getLastName() != null ? " " + _sessionUser.getLastName() : "");
        else _displayName = _sessionUser.getUsername();
        String _email = _sessionUser.getEmail() != null ? _sessionUser.getEmail() : _sessionUser.getUsername();
        // ── รูปโปรไฟล์ ──
        String _navPhotoPath = _sessionUser.getProfilePhoto();
        String _navPhotoUrl  = (_navPhotoPath != null && !_navPhotoPath.trim().isEmpty())
            ? request.getContextPath() + "/uploads/" + _navPhotoPath
            : null;
        // ── ลิงก์ "Xem hồ sơ" — student ไปหน้า home tab ho-so, role อื่นไป dashboard ──
        boolean _isStudent = "STUDENT".equalsIgnoreCase(_sessionUser.getRole());
        String _profileLink = _isStudent ? "javascript:void(0)" : (request.getContextPath() + "/dashboard?tab=profile");
        String _profileOnClick = _isStudent ? "onclick=\"showPage('ho-so');document.getElementById('navUserWrap').classList.remove('open')\"" : "";
        String _manageLink = _isStudent ? "javascript:void(0)" : (request.getContextPath() + "/dashboard?tab=profile");
        String _manageOnClick = _isStudent ? "onclick=\"showPage('ho-so');document.getElementById('navUserWrap').classList.remove('open')\"" : "";
      %>
      <!-- Trigger: avatar circle หรือรูปโปรไฟล์ -->
      <% if (_navPhotoUrl != null) { %>
      <img src="<%= _navPhotoUrl %>" id="navAvatar" alt="Avatar"
           style="width:36px;height:36px;border-radius:50%;object-fit:cover;cursor:pointer;border:2px solid rgba(255,255,255,.5);">
      <% } else { %>
      <div class="nav-avatar" id="navAvatar"><%= _initials.toUpperCase() %></div>
      <% } %>

      <!-- Google-style dropdown -->
      <div class="nav-user-dropdown">
        <!-- Top: big avatar + name + email -->
        <div class="nud-top">
          <% if (_navPhotoUrl != null) { %>
          <img src="<%= _navPhotoUrl %>" alt="Avatar"
               style="width:64px;height:64px;border-radius:50%;object-fit:cover;border:3px solid #e2e8f0;box-shadow:0 2px 8px rgba(0,0,0,.12);">
          <% } else { %>
          <div class="nud-big-av"><%= _initials.toUpperCase() %></div>
          <% } %>
          <div class="nud-top-name"><%= _displayName %></div>
          <div class="nud-top-email"><%= _email %></div>
          <a href="<%= _manageLink %>" class="nud-profile-btn" <%= _manageOnClick %>>
            <%= _isStudent ? "Xem hồ sơ cá nhân" : "Quản lý tài khoản" %>
          </a>
        </div>

        <div class="nud-divider"></div>

        <!-- Menu items -->
        <div class="nud-section">
          <a href="<%= _profileLink %>" class="nud-item" <%= _profileOnClick %>>
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="8" r="4"/><path d="M4 20c0-4 3.6-7 8-7s8 3 8 7"/></svg>
            Xem hồ sơ cá nhân
          </a>
        </div>

        <div class="nud-divider"></div>

        <!-- Logout -->
        <div class="nud-section">
          <a href="<%= request.getContextPath() %>/logout" class="nud-logout">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/></svg>
            Đăng xuất
          </a>
        </div>
      </div>
    </div>
    <% } else { %>
      <a href="<%= request.getContextPath() %>/login" class="nav-login">Đăng nhập</a>
      <a href="<%= request.getContextPath() %>/register" class="nav-cta">🚀 Đăng ký miễn phí</a>
    <% } %>
    <button class="hamburger" id="menuBtn" onclick="toggleMobile()">
      <span></span><span></span><span></span>
    </button>
  </div>
</nav>

<!-- MOBILE MENU -->
<div class="mobile-menu" id="mobileMenu">
  <ul>
    <li><a id="mnav-home" class="active" onclick="showPage('home');closeMobile()">🏠 Trang chủ</a></li>
    <li><a id="mnav-tinh-nang" onclick="showPage('tinh-nang');closeMobile()">✨ Tính năng</a></li>
    <li><a id="mnav-khoa-hoc" onclick="showPage('khoa-hoc');closeMobile()">📚 Khóa học</a></li>
    <li><a id="mnav-hoc-phi" onclick="showPage('hoc-phi');closeMobile()">💰 Học phí</a></li>
    <li><a id="mnav-lien-he" onclick="showPage('lien-he');closeMobile()">📩 Liên hệ</a></li>
    <% if (_sessionUser != null && "STUDENT".equalsIgnoreCase(_sessionUser.getRole())) { %>
    <li><a id="mnav-ho-so" onclick="showPage('ho-so');closeMobile()">👤 Hồ sơ</a></li>
    <% } %>
  </ul>
  <div class="mobile-btns">
    <% if (_sessionUser != null) { %>
      <div class="m-user-info">👤 <%= _sessionUser.getFirstName() != null && !_sessionUser.getFirstName().isEmpty() ? _sessionUser.getFirstName() + " " + (_sessionUser.getLastName()!=null?_sessionUser.getLastName():"") : _sessionUser.getUsername() %></div>
      <a href="<%= request.getContextPath() %>/logout" class="m-logout">🚪 Đăng xuất</a>
    <% } else { %>
      <a href="<%= request.getContextPath() %>/login" class="m-login">Đăng nhập</a>
      <a href="<%= request.getContextPath() %>/register" class="m-cta">🚀 Đăng ký miễn phí</a>
    <% } %>
  </div>
</div>

<!-- ════ PAGE 1: TRANG CHỦ ════ -->
<div class="page active" id="page-home">

  <section class="hero">
    <div class="hero-bg"></div>
    <div class="hero-overlay"></div>
    <div class="hero-dots"></div>
    <div class="hero-content">
      <div class="hero-badge">🎓 StudyFlow Platform — Nền tảng học trực tuyến toàn diện</div>
      <h1 class="hero-title">Học · Dạy · Quản Lý<br/><span class="hl">Tất Cả Trong Một Nền Tảng</span></h1>
      <p class="hero-sub">StudyFlow là hệ thống học trực tuyến đầy đủ tính năng — học viên học theo lộ trình, giảng viên dạy chuyên nghiệp, admin giám sát toàn bộ. Hoàn toàn miễn phí.</p>
      <div class="hero-cards">
        <div class="hero-card"><div class="hc-icon">📚</div><div class="hc-title">Khóa học phong phú</div><div class="hc-desc">Video bài giảng, tài liệu, bài tập thực hành</div><div class="hc-tag">🔥 Học miễn phí</div></div>
        <div class="hero-card"><div class="hc-icon">👨‍🏫</div><div class="hc-title">Giảng viên xác minh</div><div class="hc-desc">Đội ngũ kinh nghiệm được Admin duyệt</div><div class="hc-tag">✅ Được xác minh</div></div>
        <div class="hero-card"><div class="hc-icon">📊</div><div class="hc-title">Dashboard theo dõi</div><div class="hc-desc">Theo dõi tiến độ học tập real-time</div><div class="hc-tag">📈 Real-time</div></div>
        <div class="hero-card"><div class="hc-icon">🛡️</div><div class="hc-title">Phân quyền 4 cấp</div><div class="hc-desc">Student · Teacher · Admin · Super Admin</div><div class="hc-tag">🔐 Bảo mật cao</div></div>
      </div>
      <div class="hero-btns">
        <a href="<%= request.getContextPath() %>/register" class="btn-main">🚀 Đăng ký miễn phí ngay</a>
        <a class="btn-ghost" onclick="showPage('tinh-nang')">🔍 Khám phá tính năng</a>
      </div>
      <div class="hero-trust">
        <span class="trust-item"><span class="trust-dot"></span>1,200+ học viên</span>
        <span class="trust-sep">·</span>
        <span class="trust-item"><span class="trust-dot"></span>4.9★ đánh giá</span>
        <span class="trust-sep">·</span>
        <span class="trust-item"><span class="trust-dot"></span>48h+ video</span>
        <span class="trust-sep">·</span>
        <span class="trust-item"><span class="trust-dot"></span>Hoàn toàn miễn phí</span>
      </div>
    </div>
  </section>

  <div class="marquee-sec">
    <div class="marquee-track">
      <span class="marquee-item"><span class="mq-dot"></span><strong>Java Core</strong> · 27 buổi học</span>
      <span class="marquee-item"><span class="mq-dot"></span><strong>OOP</strong> · Lập trình hướng đối tượng</span>
      <span class="marquee-item"><span class="mq-dot"></span><strong>Collections</strong> · Framework đầy đủ</span>
      <span class="marquee-item"><span class="mq-dot"></span><strong>Stream API</strong> · Lambda Expression</span>
      <span class="marquee-item"><span class="mq-dot"></span><strong>Spring Boot</strong> · Sắp ra mắt</span>
      <span class="marquee-item"><span class="mq-dot"></span><strong>MySQL</strong> · Database thực chiến</span>
      <span class="marquee-item"><span class="mq-dot"></span><strong>Java Core</strong> · 27 buổi học</span>
      <span class="marquee-item"><span class="mq-dot"></span><strong>OOP</strong> · Lập trình hướng đối tượng</span>
      <span class="marquee-item"><span class="mq-dot"></span><strong>Collections</strong> · Framework đầy đủ</span>
      <span class="marquee-item"><span class="mq-dot"></span><strong>Stream API</strong> · Lambda Expression</span>
      <span class="marquee-item"><span class="mq-dot"></span><strong>Spring Boot</strong> · Sắp ra mắt</span>
      <span class="marquee-item"><span class="mq-dot"></span><strong>MySQL</strong> · Database thực chiến</span>
    </div>
  </div>

  <div class="stats-sec">
    <div class="stats-grid">
      <div class="stat-item"><div class="stat-num">1,200+</div><div class="stat-lbl">Học viên đang học</div></div>
      <div class="stat-item"><div class="stat-num">48h+</div><div class="stat-lbl">Video bài giảng</div></div>
      <div class="stat-item"><div class="stat-num">4.9★</div><div class="stat-lbl">Đánh giá trung bình</div></div>
      <div class="stat-item"><div class="stat-num">100%</div><div class="stat-lbl">Hoàn toàn miễn phí</div></div>
    </div>
  </div>

  <section class="sec" style="background:#fff">
    <div style="text-align:center">
      <div class="sec-chip reveal">👥 Vai trò người dùng</div>
      <h2 class="sec-title reveal">Nền tảng dành cho tất cả mọi người</h2>
      <p class="sec-desc reveal" style="margin:0 auto 48px">Dù bạn là học viên, giảng viên hay quản trị viên — StudyFlow đều có đầy đủ công cụ phù hợp với vai trò của bạn.</p>
    </div>
    <div class="roles-grid">
      <div class="role-card role-student reveal">
        <div class="role-icon">🎓</div>
        <div class="role-name">Học viên (Student)</div>
        <ul class="role-list">
          <li><span class="role-bullet">✓</span>Duyệt và đăng ký khóa học miễn phí</li>
          <li><span class="role-bullet">✓</span>Xem video bài giảng trong phòng học trực tuyến</li>
          <li><span class="role-bullet">✓</span>Theo dõi tiến độ hoàn thành từng bài học</li>
          <li><span class="role-bullet">✓</span>Xem danh sách khóa học đã đăng ký</li>
          <li><span class="role-bullet">✓</span>Nhận chứng chỉ khi hoàn thành khóa học</li>
        </ul>
        <a href="<%= request.getContextPath() %>/register" class="role-cta-btn">Đăng ký học viên →</a>
      </div>
      <div class="role-card role-teacher reveal d1">
        <div class="role-icon">👨‍🏫</div>
        <div class="role-name">Giảng viên (Teacher)</div>
        <ul class="role-list">
          <li><span class="role-bullet">✓</span>Tạo và quản lý khóa học của mình</li>
          <li><span class="role-bullet">✓</span>Thêm bài giảng video và tài liệu học tập</li>
          <li><span class="role-bullet">✓</span>Xem thống kê số học viên đăng ký</li>
          <li><span class="role-bullet">✓</span>Quản lý danh sách học viên trong khóa</li>
          <li><span class="role-bullet">✓</span>Dashboard theo dõi hiệu quả giảng dạy</li>
        </ul>
        <a href="<%= request.getContextPath() %>/register" class="role-cta-btn">Đăng ký giảng dạy →</a>
      </div>
      <div class="role-card role-admin reveal d2">
        <div class="role-icon">⚙️</div>
        <div class="role-name">Quản trị (Admin)</div>
        <ul class="role-list">
          <li><span class="role-bullet">✓</span>Phê duyệt tài khoản giảng viên mới</li>
          <li><span class="role-bullet">✓</span>Quản lý toàn bộ người dùng hệ thống</li>
          <li><span class="role-bullet">✓</span>Phê duyệt hoặc từ chối khóa học mới</li>
          <li><span class="role-bullet">✓</span>Khóa / mở khóa tài khoản người dùng</li>
          <li><span class="role-bullet">✓</span>Dashboard thống kê toàn hệ thống</li>
        </ul>
        <a href="<%= request.getContextPath() %>/login" class="role-cta-btn">Đăng nhập quản trị →</a>
      </div>
    </div>
  </section>

  <div class="cta-banner">
    <div class="cta-inner">
      <div class="cta-badge">🎁 HOÀN TOÀN MIỄN PHÍ</div>
      <h2 class="cta-title">Sẵn sàng bắt đầu<br/>hành trình của bạn?</h2>
      <p class="cta-sub">Gia nhập cùng hơn 1,200 học viên đã thành công. Đăng ký miễn phí, học ngay hôm nay.</p>
      <div class="cta-btns">
        <a href="<%= request.getContextPath() %>/register" class="cta-btn-w">🚀 Đăng ký học miễn phí</a>
        <a class="cta-btn-o" onclick="showPage('khoa-hoc')">📚 Xem khóa học</a>
      </div>
    </div>
  </div>

  <footer class="site-footer">
    <div class="footer-top">
      <!-- Col 1: Brand + Socials -->
      <div class="ft-brand">
        <div class="f-logo-wrap">
          <div class="flogo">
            <img src="<%= request.getContextPath() %>/logo/StudyFlow.png" alt="StudyFlow Logo" style="height:32px;width:auto;vertical-align:middle;">
          </div>
          <div class="fname">StudyFlow</div>
          <div class="ftag">MIỄN PHÍ</div>
        </div>
        <div class="ft-tagline">Nền tảng học trực tuyến Java</div>
        <p class="ft-desc">Hệ thống học trực tuyến miễn phí dành cho học viên, giảng viên và quản trị viên — tất cả trong một nền tảng duy nhất.</p>
        <div class="ft-socials">
          <a href="https://facebook.com/StudyFlowPlatform" target="_blank" class="ft-soc fb" title="Facebook">
            <svg viewBox="0 0 24 24"><path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z"/></svg>
          </a>
          <a href="https://youtube.com/@StudyFlowPlatform" target="_blank" class="ft-soc yt" title="YouTube">
            <svg viewBox="0 0 24 24"><path d="M23.495 6.205a3.007 3.007 0 0 0-2.088-2.088c-1.87-.501-9.396-.501-9.396-.501s-7.507-.01-9.396.501A3.007 3.007 0 0 0 .527 6.205a31.247 31.247 0 0 0-.522 5.805 31.247 31.247 0 0 0 .522 5.783 3.007 3.007 0 0 0 2.088 2.088c1.868.502 9.396.502 9.396.502s7.506 0 9.396-.502a3.007 3.007 0 0 0 2.088-2.088 31.247 31.247 0 0 0 .5-5.783 31.247 31.247 0 0 0-.5-5.805zM9.609 15.601V8.408l6.264 3.602z"/></svg>
          </a>
          <a href="https://github.com/StudyFlowPlatform" target="_blank" class="ft-soc gh" title="GitHub">
            <svg viewBox="0 0 24 24"><path d="M12 .297c-6.63 0-12 5.373-12 12 0 5.303 3.438 9.8 8.205 11.385.6.113.82-.258.82-.577 0-.285-.01-1.04-.015-2.04-3.338.724-4.042-1.61-4.042-1.61C4.422 18.07 3.633 17.7 3.633 17.7c-1.087-.744.084-.729.084-.729 1.205.084 1.838 1.236 1.838 1.236 1.07 1.835 2.809 1.305 3.495.998.108-.776.417-1.305.76-1.605-2.665-.3-5.466-1.332-5.466-5.93 0-1.31.465-2.38 1.235-3.22-.135-.303-.54-1.523.105-3.176 0 0 1.005-.322 3.3 1.23.96-.267 1.98-.399 3-.405 1.02.006 2.04.138 3 .405 2.28-1.552 3.285-1.23 3.285-1.23.645 1.653.24 2.873.12 3.176.765.84 1.23 1.91 1.23 3.22 0 4.61-2.805 5.625-5.475 5.92.42.36.81 1.096.81 2.22 0 1.606-.015 2.896-.015 3.286 0 .315.21.69.825.57C20.565 22.092 24 17.592 24 12.297c0-6.627-5.373-12-12-12"/></svg>
          </a>
        </div>
      </div>
      <!-- Col 2: Khám phá -->
      <div class="ft-col">
        <h5>Khám phá</h5>
        <ul>
          <li><a onclick="showPage('home')"><span class="ft-li-dot"></span>Trang chủ</a></li>
          <li><a onclick="showPage('tinh-nang')"><span class="ft-li-dot"></span>Tính năng</a></li>
          <li><a onclick="showPage('khoa-hoc')"><span class="ft-li-dot"></span>Khóa học</a></li>
          <li><a onclick="showPage('hoc-phi')"><span class="ft-li-dot"></span>Học phí</a></li>
          <li><a onclick="showPage('lien-he')"><span class="ft-li-dot"></span>Liên hệ</a></li>
        </ul>
      </div>
      <!-- Col 3: Học tập -->
      <div class="ft-col">
        <h5>Học tập</h5>
        <ul>
          <li><a href="#"><span class="ft-li-dot"></span>Java Core</a></li>
          <li><a href="#"><span class="ft-li-dot"></span>Java Web MVC</a></li>
          <li><a href="#"><span class="ft-li-dot"></span>Bài tập &amp; Homework</a></li>
          <li><a href="#"><span class="ft-li-dot"></span>Mentoring 1-1</a></li>
          <li><a href="#"><span class="ft-li-dot"></span>Cộng đồng học viên</a></li>
        </ul>
      </div>
      <!-- Col 4: Liên hệ -->
      <div class="ft-contact">
        <h5>Liên hệ &amp; Hỗ trợ</h5>
        <div class="fc-items">
          <div class="fc-item"><div class="fc-icon">📞</div><div class="fc-text"><strong>0912.345.678</strong>T2–T6: 8:00 – 17:30</div></div>
          <div class="fc-item"><div class="fc-icon">✉️</div><div class="fc-text"><strong>support@studyflow.edu.vn</strong>Phản hồi trong 24 giờ</div></div>
          <div class="fc-item"><div class="fc-icon">📍</div><div class="fc-text"><strong>Số 1 Trường Thi</strong>TP Vinh, Nghệ An</div></div>
          <div class="fc-item"><div class="fc-icon">💬</div><div class="fc-text"><strong>Zalo / Discord</strong>@StudyFlowPlatform · 24/7</div></div>
        </div>
      </div>
    </div>
    <div class="footer-bottom">
      <div class="fb-copy">© 2025 StudyFlow Platform. All rights reserved.</div>
      <div class="fb-links">
        <a href="#">Chính sách bảo mật</a>
        <a href="#">Điều khoản sử dụng</a>
        <a onclick="showPage('lien-he')">Liên hệ</a>
      </div>
      <div class="fb-made">Made with <span>♥</span> tại Nghệ An</div>
    </div>
  </footer>
</div>

<!-- ════ PAGE 2: TÍNH NĂNG ════ -->
<div class="page" id="page-tinh-nang">
  <div class="feat-hero">
    <div class="feat-hero-c">
      <div class="sec-chip chip-light">✨ Tính năng</div>
      <h1>Đầy đủ tính năng · <em>Dễ sử dụng</em></h1>
      <p>Được thiết kế tối ưu cho mọi vai trò — StudyFlow cung cấp tất cả công cụ cần thiết để học, dạy và quản lý hiệu quả.</p>
    </div>
  </div>
  <div class="bento-wrap">
    <div class="bento">
      <div class="bc bc-blue bc-wide">
        <div class="bc-tag">CORE FEATURE</div>
        <div class="bc-icon bic-blue">🎬</div>
        <h3>Phòng học trực tuyến</h3>
        <p>Video HD, sidebar danh sách bài học, đánh dấu bài đã hoàn thành tự động, lưu tiến độ xem liên tục.</p>
        <div class="bc-visual">
          <div><div class="vs-num">HD</div><div class="vs-lbl">Chất lượng video</div></div>
          <div class="bv-div"></div>
          <div><div class="vs-num">Auto</div><div class="vs-lbl">Lưu tiến độ</div></div>
          <div class="bv-div"></div>
          <div><div class="vs-num">∞</div><div class="vs-lbl">Xem lại bất cứ lúc</div></div>
        </div>
      </div>
      <div class="bc bc-green">
        <div class="bc-icon bic-green">📈</div>
        <h3>Theo dõi tiến độ học tập</h3>
        <p>Hệ thống tự động ghi nhận bài đã xem, hiển thị % hoàn thành từng khóa và toàn bộ lộ trình của bạn.</p>
      </div>
    </div>
    <div class="bento">
      <div class="bc bc-dark">
        <div class="bc-icon bic-w">🛡️</div>
        <h3>Phân quyền 4 cấp độ</h3>
        <p>Kiểm soát truy cập rõ ràng, bảo vệ dữ liệu toàn diện theo từng vai trò.</p>
        <div class="bc-chips">
          <span class="bc-chip">Student</span><span class="bc-chip">Teacher</span><span class="bc-chip">Admin</span><span class="bc-chip">Super Admin</span>
        </div>
      </div>
      <div class="bc bc-amber">
        <div class="bc-icon bic-amber">✅</div>
        <h3>Quy trình phê duyệt giảng viên</h3>
        <p>Giảng viên đăng ký, Admin xét duyệt — đảm bảo chất lượng đội ngũ và nội dung toàn nền tảng.</p>
      </div>
      <div class="bc bc-teal">
        <div class="bc-icon bic-teal">🗂️</div>
        <h3>Quản lý khóa học toàn diện</h3>
        <p>Tạo, chỉnh sửa, xóa khóa học và bài giảng. Upload video, phân loại, quản lý trạng thái xuất bản.</p>
      </div>
    </div>
    <div class="bento">
      <div class="bc bc-purple bc-wide">
        <div class="bc-icon bic-purple">🔐</div>
        <h3>Bảo mật đa lớp</h3>
        <p>Session-based authentication, mã hóa mật khẩu, kiểm tra quyền truy cập từng trang và bảo vệ dữ liệu người dùng theo chuẩn bảo mật hiện đại.</p>
      </div>
      <div class="bc bc-red">
        <div class="bc-icon bic-red">🏆</div>
        <h3>Chứng chỉ hoàn thành</h3>
        <p>Nhận chứng chỉ khi hoàn thành 100% khóa học. Được cộng đồng IT Việt Nam công nhận.</p>
      </div>
    </div>
  </div>
  <div class="how-strip">
    <div class="how-inner">
      <div class="sec-chip reveal">🗺️ Cách hoạt động</div>
      <h2 class="sec-title reveal">Bắt đầu chỉ trong 4 bước</h2>
      <div class="how-steps">
        <div class="step reveal"><div class="step-num">1</div><h4>Đăng ký tài khoản</h4><p>Tạo tài khoản miễn phí với email, không cần thẻ tín dụng, hoàn tất trong vài phút.</p></div>
        <div class="step reveal d1"><div class="step-num">2</div><h4>Khám phá khóa học</h4><p>Duyệt danh sách, xem nội dung chi tiết từng module và chọn lộ trình phù hợp.</p></div>
        <div class="step reveal d2"><div class="step-num">3</div><h4>Bắt đầu học</h4><p>Vào phòng học trực tuyến, xem video HD và làm bài tập thực hành ngay hôm nay.</p></div>
        <div class="step reveal d3"><div class="step-num">4</div><h4>Nhận chứng chỉ</h4><p>Hoàn thành 100% để nhận chứng chỉ được cộng đồng IT Việt Nam công nhận.</p></div>
      </div>
    </div>
  </div>
  <footer class="site-footer">
    <div class="footer-top">
      <!-- Col 1: Brand + Socials -->
      <div class="ft-brand">
        <div class="f-logo-wrap">
          <div class="flogo">
            <img src="<%= request.getContextPath() %>/logo/StudyFlow.png" alt="StudyFlow Logo" style="height:32px;width:auto;vertical-align:middle;">
          </div>
          <div class="fname">StudyFlow</div>
          <div class="ftag">MIỄN PHÍ</div>
        </div>
        <div class="ft-tagline">Nền tảng học trực tuyến Java</div>
        <p class="ft-desc">Hệ thống học trực tuyến miễn phí dành cho học viên, giảng viên và quản trị viên — tất cả trong một nền tảng duy nhất.</p>
        <div class="ft-socials">
          <a href="https://facebook.com/StudyFlowPlatform" target="_blank" class="ft-soc fb" title="Facebook">
            <svg viewBox="0 0 24 24"><path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z"/></svg>
          </a>
          <a href="https://youtube.com/@StudyFlowPlatform" target="_blank" class="ft-soc yt" title="YouTube">
            <svg viewBox="0 0 24 24"><path d="M23.495 6.205a3.007 3.007 0 0 0-2.088-2.088c-1.87-.501-9.396-.501-9.396-.501s-7.507-.01-9.396.501A3.007 3.007 0 0 0 .527 6.205a31.247 31.247 0 0 0-.522 5.805 31.247 31.247 0 0 0 .522 5.783 3.007 3.007 0 0 0 2.088 2.088c1.868.502 9.396.502 9.396.502s7.506 0 9.396-.502a3.007 3.007 0 0 0 2.088-2.088 31.247 31.247 0 0 0 .5-5.783 31.247 31.247 0 0 0-.5-5.805zM9.609 15.601V8.408l6.264 3.602z"/></svg>
          </a>
          <a href="https://github.com/StudyFlowPlatform" target="_blank" class="ft-soc gh" title="GitHub">
            <svg viewBox="0 0 24 24"><path d="M12 .297c-6.63 0-12 5.373-12 12 0 5.303 3.438 9.8 8.205 11.385.6.113.82-.258.82-.577 0-.285-.01-1.04-.015-2.04-3.338.724-4.042-1.61-4.042-1.61C4.422 18.07 3.633 17.7 3.633 17.7c-1.087-.744.084-.729.084-.729 1.205.084 1.838 1.236 1.838 1.236 1.07 1.835 2.809 1.305 3.495.998.108-.776.417-1.305.76-1.605-2.665-.3-5.466-1.332-5.466-5.93 0-1.31.465-2.38 1.235-3.22-.135-.303-.54-1.523.105-3.176 0 0 1.005-.322 3.3 1.23.96-.267 1.98-.399 3-.405 1.02.006 2.04.138 3 .405 2.28-1.552 3.285-1.23 3.285-1.23.645 1.653.24 2.873.12 3.176.765.84 1.23 1.91 1.23 3.22 0 4.61-2.805 5.625-5.475 5.92.42.36.81 1.096.81 2.22 0 1.606-.015 2.896-.015 3.286 0 .315.21.69.825.57C20.565 22.092 24 17.592 24 12.297c0-6.627-5.373-12-12-12"/></svg>
          </a>
        </div>
      </div>
      <!-- Col 2: Khám phá -->
      <div class="ft-col">
        <h5>Khám phá</h5>
        <ul>
          <li><a onclick="showPage('home')"><span class="ft-li-dot"></span>Trang chủ</a></li>
          <li><a onclick="showPage('tinh-nang')"><span class="ft-li-dot"></span>Tính năng</a></li>
          <li><a onclick="showPage('khoa-hoc')"><span class="ft-li-dot"></span>Khóa học</a></li>
          <li><a onclick="showPage('hoc-phi')"><span class="ft-li-dot"></span>Học phí</a></li>
          <li><a onclick="showPage('lien-he')"><span class="ft-li-dot"></span>Liên hệ</a></li>
        </ul>
      </div>
      <!-- Col 3: Học tập -->
      <div class="ft-col">
        <h5>Học tập</h5>
        <ul>
          <li><a href="#"><span class="ft-li-dot"></span>Java Core</a></li>
          <li><a href="#"><span class="ft-li-dot"></span>Java Web MVC</a></li>
          <li><a href="#"><span class="ft-li-dot"></span>Bài tập &amp; Homework</a></li>
          <li><a href="#"><span class="ft-li-dot"></span>Mentoring 1-1</a></li>
          <li><a href="#"><span class="ft-li-dot"></span>Cộng đồng học viên</a></li>
        </ul>
      </div>
      <!-- Col 4: Liên hệ -->
      <div class="ft-contact">
        <h5>Liên hệ &amp; Hỗ trợ</h5>
        <div class="fc-items">
          <div class="fc-item"><div class="fc-icon">📞</div><div class="fc-text"><strong>0912.345.678</strong>T2–T6: 8:00 – 17:30</div></div>
          <div class="fc-item"><div class="fc-icon">✉️</div><div class="fc-text"><strong>support@studyflow.edu.vn</strong>Phản hồi trong 24 giờ</div></div>
          <div class="fc-item"><div class="fc-icon">📍</div><div class="fc-text"><strong>Số 1 Trường Thi</strong>TP Vinh, Nghệ An</div></div>
          <div class="fc-item"><div class="fc-icon">💬</div><div class="fc-text"><strong>Zalo / Discord</strong>@StudyFlowPlatform · 24/7</div></div>
        </div>
      </div>
    </div>
    <div class="footer-bottom">
      <div class="fb-copy">© 2025 StudyFlow Platform. All rights reserved.</div>
      <div class="fb-links">
        <a href="#">Chính sách bảo mật</a>
        <a href="#">Điều khoản sử dụng</a>
        <a onclick="showPage('lien-he')">Liên hệ</a>
      </div>
      <div class="fb-made">Made with <span>♥</span> tại Nghệ An</div>
    </div>
  </footer>
</div>

<!-- ════ PAGE 3: KHÓA HỌC ════ -->
<div class="page" id="page-khoa-hoc">
<div class="cat-page">

  <!-- ══ COURSE LIST VIEW ══ -->
  <div id="courseListView">
    <!-- SEARCH + SORT BAR -->
    <div class="cat-topbar">
      <div class="cat-topbar-inner">
        <div class="cat-search-wrap">
          <span class="cat-search-ico">🔍</span>
          <input type="text" id="catSearchInput" placeholder="Tìm khóa học, giảng viên..." oninput="catSearch()"/>
        </div>
        <select class="cat-sort-sel" id="catSort" onchange="catRender()">
          <option value="popular">Phổ biến nhất</option>
          <option value="new">Mới nhất</option>
          <option value="videos">Nhiều bài học</option>
          <option value="alpha">Tên A-Z</option>
        </select>
      </div>
    </div>

    <!-- SECTION HEADER -->
    <div class="cat-section-header">
      <h2 class="cat-section-title">Tất cả khóa học miễn phí</h2>
      <p class="cat-section-sub">Học mọi lúc mọi nơi — Hoàn toàn miễn phí 100%</p>
    </div>

    <!-- COUNT TOOLBAR -->
    <div class="cat-toolbar">
      <div class="cat-count"><strong id="catCount"><%= _totalActive %></strong> khóa học</div>
    </div>

    <!-- COURSE GRID -->
    <div class="cat-content">
      <div class="cat-grid" id="catGrid"></div>
      <div class="cat-empty" id="catEmpty" style="display:none">
        <div class="cat-empty-ico">📭</div>
        <div class="cat-empty-msg">Không tìm thấy khóa học</div>
        <div class="cat-empty-sub">Hãy thử từ khóa khác hoặc chọn danh mục khác</div>
      </div>
    </div>

    <!-- ══ CONTACT SECTION ══ -->
    <div style="background:#fff;border-top:2px solid #e8ecf0;padding:64px 48px 0">
      <!-- Contact Banner -->
      <div class="kh-contact-strip">
        <div class="kh-cs-left">
          <h3>📩 Cần tư vấn về khóa học?</h3>
          <p>Đội ngũ StudyFlow sẵn sàng hỗ trợ bạn chọn khóa học phù hợp, giải đáp thắc mắc và đồng hành trong suốt hành trình học tập.</p>
          <div class="kh-cs-items">
            <div class="kh-cs-item">📞 <span>0912.345.678</span> Thứ 2 – Thứ 6: 8:00 – 17:30</div>
            <div class="kh-cs-item">✉️ <span>support@studyflow.edu.vn</span> Phản hồi trong 24h</div>
            <div class="kh-cs-item">💬 <span>@StudyFlowPlatform</span> Zalo &amp; Discord 24/7</div>
          </div>
        </div>
        <div class="kh-cs-right">
          <a class="kh-cs-btn primary" onclick="showPage('lien-he')">📩 Liên hệ ngay</a>
          <a class="kh-cs-btn secondary" href="tel:0912345678">📞 Gọi Hotline</a>
        </div>
      </div>

      <!-- Contact Info Cards -->
      <div style="max-width:1280px;margin:0 auto;padding:0 20px 32px">
        <div style="text-align:center;margin-bottom:32px">
          <div class="sec-chip" style="margin-bottom:12px">📬 Thông tin liên hệ</div>
          <h2 style="font-size:24px;font-weight:900;color:var(--ink);margin-bottom:8px">Chúng tôi luôn sẵn sàng hỗ trợ bạn</h2>
          <p style="font-size:14px;color:var(--muted)">Liên hệ qua nhiều kênh — phản hồi nhanh trong 24 giờ làm việc</p>
        </div>
        <div style="display:grid;grid-template-columns:repeat(4,1fr);gap:16px;margin-bottom:40px">
          <div class="cir-card">
            <div class="cir-icon c-blue">📞</div>
            <div>
              <div class="cir-label">Hotline</div>
              <div class="cir-val">0912.345.678</div>
              <div class="cir-sub">T2–T6: 8:00–17:30</div>
            </div>
          </div>
          <div class="cir-card">
            <div class="cir-icon c-green">✉️</div>
            <div>
              <div class="cir-label">Email</div>
              <div class="cir-val">support@studyflow.edu.vn</div>
              <div class="cir-sub">Phản hồi trong 24h</div>
            </div>
          </div>
          <div class="cir-card">
            <div class="cir-icon c-purple">📍</div>
            <div>
              <div class="cir-label">Địa chỉ</div>
              <div class="cir-val">Số 1 Trường Thi</div>
              <div class="cir-sub">TP Vinh, Nghệ An</div>
            </div>
          </div>
          <div class="cir-card">
            <div class="cir-icon c-orange">💬</div>
            <div>
              <div class="cir-label">Zalo / Discord</div>
              <div class="cir-val">@StudyFlowPlatform</div>
              <div class="cir-sub">Hỗ trợ 24/7</div>
            </div>
          </div>
        </div>

        <!-- Quick Contact Form -->
        <div style="background:linear-gradient(135deg,#f8faff,#eef1ff);border:1.5px solid #c5d0fa;border-radius:20px;padding:40px;max-width:700px;margin:0 auto 48px">
          <h3 style="font-size:20px;font-weight:900;color:var(--ink);margin-bottom:6px;text-align:center">✍️ Gửi tin nhắn nhanh</h3>
          <p style="font-size:13.5px;color:var(--muted);text-align:center;margin-bottom:24px">Điền form — chúng tôi sẽ phản hồi trong 24 giờ làm việc</p>

          <% if ("sent".equals(request.getParameter("success")) && "khoa-hoc".equals(request.getParameter("tab"))) { %>
          <div id="kh-formOk" style="text-align:center;padding:30px 0">
            <div style="font-size:48px;margin-bottom:12px">🎉</div>
            <div style="font-size:20px;font-weight:900;color:var(--ink);margin-bottom:8px">Gửi thành công!</div>
            <p style="font-size:14px;color:var(--muted)">Cảm ơn bạn. Chúng tôi sẽ phản hồi qua email trong 24 giờ làm việc.</p>
          </div>
          <% } else { %>
          <div id="kh-formWrap">
            <form method="post" action="<%= request.getContextPath() %>/contact">
              <input type="hidden" name="redirect" value="/home?tab=khoa-hoc"/>
              <input type="hidden" name="subject" value="Quick Consultation"/>
              <div style="display:grid;grid-template-columns:1fr 1fr;gap:14px;margin-bottom:14px">
                <div class="f-field"><label>Họ và tên *</label><input name="name" type="text" class="f-field input" placeholder="Nguyễn Văn A" style="width:100%;padding:11px 14px;border:2px solid #e5e7eb;border-radius:10px;font-size:13.5px;font-family:'Nunito',sans-serif;color:var(--ink);outline:none;" required/></div>
                <div class="f-field"><label>Email *</label><input name="email" type="email" class="f-field input" placeholder="name@example.com" style="width:100%;padding:11px 14px;border:2px solid #e5e7eb;border-radius:10px;font-size:13.5px;font-family:'Nunito',sans-serif;color:var(--ink);outline:none;" required/></div>
              </div>
              <div style="margin-bottom:14px">
                <div class="f-field"><label>Lời nhắn</label><textarea name="message" rows="3" placeholder="Câu hỏi hoặc nội dung cần hỗ trợ..." style="width:100%;padding:11px 14px;border:2px solid #e5e7eb;border-radius:10px;font-size:13.5px;font-family:'Nunito',sans-serif;color:var(--ink);outline:none;resize:vertical;" required></textarea></div>
              </div>
              <button type="submit" style="width:100%;padding:13px;background:linear-gradient(135deg,var(--accent),var(--accent3));color:#fff;font-family:'Nunito',sans-serif;font-size:15px;font-weight:800;border:none;border-radius:12px;cursor:pointer;box-shadow:0 6px 20px rgba(59,91,219,.3);">📩 Gửi tin nhắn</button>
            </form>
          </div>
          <% } %>
        </div>
      </div>
    </div>

    <!-- Footer for khoa-hoc page -->
    <footer class="site-footer">
    <div class="footer-top">
      <!-- Col 1: Brand + Socials -->
      <div class="ft-brand">
        <div class="f-logo-wrap">
          <div class="flogo">
            <img src="<%= request.getContextPath() %>/logo/StudyFlow.png" alt="StudyFlow Logo" style="height:32px;width:auto;vertical-align:middle;">
          </div>
          <div class="fname">StudyFlow</div>
          <div class="ftag">MIỄN PHÍ</div>
        </div>
        <div class="ft-tagline">Nền tảng học trực tuyến Java</div>
        <p class="ft-desc">Hệ thống học trực tuyến miễn phí dành cho học viên, giảng viên và quản trị viên — tất cả trong một nền tảng duy nhất.</p>
        <div class="ft-socials">
          <a href="https://facebook.com/StudyFlowPlatform" target="_blank" class="ft-soc fb" title="Facebook">
            <svg viewBox="0 0 24 24"><path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z"/></svg>
          </a>
          <a href="https://youtube.com/@StudyFlowPlatform" target="_blank" class="ft-soc yt" title="YouTube">
            <svg viewBox="0 0 24 24"><path d="M23.495 6.205a3.007 3.007 0 0 0-2.088-2.088c-1.87-.501-9.396-.501-9.396-.501s-7.507-.01-9.396.501A3.007 3.007 0 0 0 .527 6.205a31.247 31.247 0 0 0-.522 5.805 31.247 31.247 0 0 0 .522 5.783 3.007 3.007 0 0 0 2.088 2.088c1.868.502 9.396.502 9.396.502s7.506 0 9.396-.502a3.007 3.007 0 0 0 2.088-2.088 31.247 31.247 0 0 0 .5-5.783 31.247 31.247 0 0 0-.5-5.805zM9.609 15.601V8.408l6.264 3.602z"/></svg>
          </a>
          <a href="https://github.com/StudyFlowPlatform" target="_blank" class="ft-soc gh" title="GitHub">
            <svg viewBox="0 0 24 24"><path d="M12 .297c-6.63 0-12 5.373-12 12 0 5.303 3.438 9.8 8.205 11.385.6.113.82-.258.82-.577 0-.285-.01-1.04-.015-2.04-3.338.724-4.042-1.61-4.042-1.61C4.422 18.07 3.633 17.7 3.633 17.7c-1.087-.744.084-.729.084-.729 1.205.084 1.838 1.236 1.838 1.236 1.07 1.835 2.809 1.305 3.495.998.108-.776.417-1.305.76-1.605-2.665-.3-5.466-1.332-5.466-5.93 0-1.31.465-2.38 1.235-3.22-.135-.303-.54-1.523.105-3.176 0 0 1.005-.322 3.3 1.23.96-.267 1.98-.399 3-.405 1.02.006 2.04.138 3 .405 2.28-1.552 3.285-1.23 3.285-1.23.645 1.653.24 2.873.12 3.176.765.84 1.23 1.91 1.23 3.22 0 4.61-2.805 5.625-5.475 5.92.42.36.81 1.096.81 2.22 0 1.606-.015 2.896-.015 3.286 0 .315.21.69.825.57C20.565 22.092 24 17.592 24 12.297c0-6.627-5.373-12-12-12"/></svg>
          </a>
        </div>
      </div>
      <!-- Col 2: Khám phá -->
      <div class="ft-col">
        <h5>Khám phá</h5>
        <ul>
          <li><a onclick="showPage('home')"><span class="ft-li-dot"></span>Trang chủ</a></li>
          <li><a onclick="showPage('tinh-nang')"><span class="ft-li-dot"></span>Tính năng</a></li>
          <li><a onclick="showPage('khoa-hoc')"><span class="ft-li-dot"></span>Khóa học</a></li>
          <li><a onclick="showPage('hoc-phi')"><span class="ft-li-dot"></span>Học phí</a></li>
          <li><a onclick="showPage('lien-he')"><span class="ft-li-dot"></span>Liên hệ</a></li>
        </ul>
      </div>
      <!-- Col 3: Học tập -->
      <div class="ft-col">
        <h5>Học tập</h5>
        <ul>
          <li><a href="#"><span class="ft-li-dot"></span>Java Core</a></li>
          <li><a href="#"><span class="ft-li-dot"></span>Java Web MVC</a></li>
          <li><a href="#"><span class="ft-li-dot"></span>Bài tập &amp; Homework</a></li>
          <li><a href="#"><span class="ft-li-dot"></span>Mentoring 1-1</a></li>
          <li><a href="#"><span class="ft-li-dot"></span>Cộng đồng học viên</a></li>
        </ul>
      </div>
      <!-- Col 4: Liên hệ -->
      <div class="ft-contact">
        <h5>Liên hệ &amp; Hỗ trợ</h5>
        <div class="fc-items">
          <div class="fc-item"><div class="fc-icon">📞</div><div class="fc-text"><strong>0912.345.678</strong>T2–T6: 8:00 – 17:30</div></div>
          <div class="fc-item"><div class="fc-icon">✉️</div><div class="fc-text"><strong>support@studyflow.edu.vn</strong>Phản hồi trong 24 giờ</div></div>
          <div class="fc-item"><div class="fc-icon">📍</div><div class="fc-text"><strong>Số 1 Trường Thi</strong>TP Vinh, Nghệ An</div></div>
          <div class="fc-item"><div class="fc-icon">💬</div><div class="fc-text"><strong>Zalo / Discord</strong>@StudyFlowPlatform · 24/7</div></div>
        </div>
      </div>
    </div>
    <div class="footer-bottom">
      <div class="fb-copy">© 2025 StudyFlow Platform. All rights reserved.</div>
      <div class="fb-links">
        <a href="#">Chính sách bảo mật</a>
        <a href="#">Điều khoản sử dụng</a>
        <a onclick="showPage('lien-he')">Liên hệ</a>
      </div>
      <div class="fb-made">Made with <span>♥</span> tại Nghệ An</div>
    </div>
  </footer>
  </div><!-- end #courseListView -->

  <!-- ══ CLASSROOM VIEW (embedded panel) ══ -->
  <div id="classroomView" style="display:none">
    <!-- Back bar -->
    <div style="background:#1354a8;padding:12px 28px;display:flex;align-items:center;gap:14px;position:sticky;top:66px;z-index:150;box-shadow:0 2px 8px rgba(0,0,0,.2)">
      <button onclick="closeClassroom()" style="background:rgba(255,255,255,.15);border:1px solid rgba(255,255,255,.3);color:#fff;padding:8px 18px;border-radius:8px;font-size:13px;font-weight:700;cursor:pointer;font-family:'Nunito',sans-serif;display:flex;align-items:center;gap:6px">
        ← Quay lại danh sách
      </button>
      <span id="classroomBreadcrumb" style="color:rgba(255,255,255,.7);font-size:13px;font-weight:600"></span>
    </div>
    <!-- Classroom iframe -->
    <iframe id="classroomIframe" src="" style="width:100%;border:none;min-height:calc(100vh - 130px);display:block;" onload="resizeClassroomIframe(this)"></iframe>
  </div>

</div>
</div>

<!-- ════ PAGE 4: HỌC PHÍ ════ -->
<div class="page" id="page-hoc-phi">
  <div class="price-hero">
    <div class="price-hero-c">
      <div class="sec-chip chip-light">💰 Học phí</div>
      <h1>Miễn phí <em>hoàn toàn</em><br/>cho học viên</h1>
      <p>Chúng tôi tin rằng giáo dục chất lượng phải dành cho tất cả mọi người.</p>
    </div>
  </div>
  <div class="price-wrap">
    <div class="free-spot">
      <div class="fs-left">
        <div class="fs-badge">🎉 HOÀN TOÀN MIỄN PHÍ</div>
        <div class="fs-price">0đ</div>
        <div class="fs-sub">Miễn phí mãi mãi · Không cần thẻ tín dụng · Không điều khoản ẩn</div>
        <a href="<%= request.getContextPath() %>/register" class="fs-btn">🚀 Bắt đầu học miễn phí ngay</a>
      </div>
      <div class="fs-right">
        <h3>✅ Bao gồm tất cả tính năng:</h3>
        <ul class="feat-list">
          <li><span class="chk">✓</span>Truy cập toàn bộ 27 buổi học &amp; 48h+ video</li>
          <li><span class="chk">✓</span>Phòng học trực tuyến video player chất lượng cao</li>
          <li><span class="chk">✓</span>Dashboard theo dõi tiến độ học tập cá nhân</li>
          <li><span class="chk">✓</span>Tài liệu học tập PDF đầy đủ</li>
          <li><span class="chk">✓</span>Tham gia cộng đồng Discord &amp; Zalo</li>
          <li><span class="chk">✓</span>Chứng chỉ hoàn thành khóa học</li>
          <li><span class="chk">✓</span>Cập nhật nội dung liên tục</li>
        </ul>
      </div>
    </div>
    <div class="up-label">Muốn được hỗ trợ thêm? Chọn gói nâng cao ↓</div>
    <div class="up-grid">
      <div class="up-card"><div class="up-icon">🎯</div><div class="up-name">Mentoring 1-1</div><div class="up-desc">Review code cá nhân, tư vấn nghề nghiệp và mock interview hàng tuần cùng mentor kinh nghiệm.</div><div class="up-price">500.000 <span>VNĐ/tháng</span></div><a href="<%= request.getContextPath() %>/register" class="up-btn">Đăng ký thêm</a></div>
      <div class="up-card"><div class="up-icon">💼</div><div class="up-name">Hỗ trợ tìm việc</div><div class="up-desc">Review CV chuyên sâu, mock interview thực tế, kết nối trực tiếp nhà tuyển dụng đối tác.</div><div class="up-price">300.000 <span>VNĐ/lần</span></div><a href="<%= request.getContextPath() %>/register" class="up-btn">Đăng ký thêm</a></div>
    </div>
    <div style="text-align:center;margin-bottom:16px"><div class="sec-chip reveal">💬 Học viên nói gì</div></div>
    <div class="testi-price">
      <div class="testi-card"><div class="t-stars">★★★★★</div><p class="t-text">Miễn phí mà chất lượng không kém trả phí! Sau 3 tháng pass phỏng vấn Java Developer.</p><div class="t-author"><div class="t-av">T</div><div><div class="t-name">Trần Minh Tuấn</div><div class="t-role">Junior Developer · FPT</div></div></div></div>
      <div class="testi-card"><div class="t-stars">★★★★★</div><p class="t-text">Video mượt mà, sidebar tiện lợi. Hoàn toàn miễn phí mà chuyên nghiệp bậc nhất!</p><div class="t-author"><div class="t-av">L</div><div><div class="t-name">Lê Thị Hoa</div><div class="t-role">Backend Intern · VNG</div></div></div></div>
      <div class="testi-card"><div class="t-stars">★★★★★</div><p class="t-text">Quy trình phê duyệt giảng viên rất chuyên nghiệp. Học viên phản hồi rất tốt về StudyFlow!</p><div class="t-author"><div class="t-av">P</div><div><div class="t-name">Phạm Quốc Huy</div><div class="t-role">Giảng viên · Grab</div></div></div></div>
    </div>
  </div>
<!-- Contact strip on Khoa hoc page -->
  <div class="kh-contact-strip">
    <div class="kh-cs-left">
      <h3>📩 Cần tư vấn về khóa học?</h3>
      <p>Đội ngũ StudyFlow sẵn sàng hỗ trợ bạn chọn khóa học phù hợp, giải đáp thắc mắc và đồng hành trong suốt hành trình học tập.</p>
      <div class="kh-cs-items">
        <div class="kh-cs-item">📞 <span>0912.345.678</span> Thứ 2 – Thứ 6: 8:00 – 17:30</div>
        <div class="kh-cs-item">✉️ <span>support@studyflow.edu.vn</span> Phản hồi trong 24h</div>
        <div class="kh-cs-item">💬 <span>@StudyFlowPlatform</span> Zalo & Discord 24/7</div>
      </div>
    </div>
    <div class="kh-cs-right">
      <a class="kh-cs-btn primary" onclick="showPage('lien-he')">📩 Liên hệ ngay</a>
      <a class="kh-cs-btn secondary" href="tel:0912345678">📞 Gọi Hotline</a>
    </div>
  </div>

  <footer class="site-footer">
    <div class="footer-top">
      <!-- Col 1: Brand + Socials -->
      <div class="ft-brand">
        <div class="f-logo-wrap">
          <div class="flogo">
            <img src="<%= request.getContextPath() %>/logo/StudyFlow.png" alt="StudyFlow Logo" style="height:32px;width:auto;vertical-align:middle;">
          </div>
          <div class="fname">StudyFlow</div>
          <div class="ftag">MIỄN PHÍ</div>
        </div>
        <div class="ft-tagline">Nền tảng học trực tuyến Java</div>
        <p class="ft-desc">Hệ thống học trực tuyến miễn phí dành cho học viên, giảng viên và quản trị viên — tất cả trong một nền tảng duy nhất.</p>
        <div class="ft-socials">
          <a href="https://facebook.com/StudyFlowPlatform" target="_blank" class="ft-soc fb" title="Facebook">
            <svg viewBox="0 0 24 24"><path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z"/></svg>
          </a>
          <a href="https://youtube.com/@StudyFlowPlatform" target="_blank" class="ft-soc yt" title="YouTube">
            <svg viewBox="0 0 24 24"><path d="M23.495 6.205a3.007 3.007 0 0 0-2.088-2.088c-1.87-.501-9.396-.501-9.396-.501s-7.507-.01-9.396.501A3.007 3.007 0 0 0 .527 6.205a31.247 31.247 0 0 0-.522 5.805 31.247 31.247 0 0 0 .522 5.783 3.007 3.007 0 0 0 2.088 2.088c1.868.502 9.396.502 9.396.502s7.506 0 9.396-.502a3.007 3.007 0 0 0 2.088-2.088 31.247 31.247 0 0 0 .5-5.783 31.247 31.247 0 0 0-.5-5.805zM9.609 15.601V8.408l6.264 3.602z"/></svg>
          </a>
          <a href="https://github.com/StudyFlowPlatform" target="_blank" class="ft-soc gh" title="GitHub">
            <svg viewBox="0 0 24 24"><path d="M12 .297c-6.63 0-12 5.373-12 12 0 5.303 3.438 9.8 8.205 11.385.6.113.82-.258.82-.577 0-.285-.01-1.04-.015-2.04-3.338.724-4.042-1.61-4.042-1.61C4.422 18.07 3.633 17.7 3.633 17.7c-1.087-.744.084-.729.084-.729 1.205.084 1.838 1.236 1.838 1.236 1.07 1.835 2.809 1.305 3.495.998.108-.776.417-1.305.76-1.605-2.665-.3-5.466-1.332-5.466-5.93 0-1.31.465-2.38 1.235-3.22-.135-.303-.54-1.523.105-3.176 0 0 1.005-.322 3.3 1.23.96-.267 1.98-.399 3-.405 1.02.006 2.04.138 3 .405 2.28-1.552 3.285-1.23 3.285-1.23.645 1.653.24 2.873.12 3.176.765.84 1.23 1.91 1.23 3.22 0 4.61-2.805 5.625-5.475 5.92.42.36.81 1.096.81 2.22 0 1.606-.015 2.896-.015 3.286 0 .315.21.69.825.57C20.565 22.092 24 17.592 24 12.297c0-6.627-5.373-12-12-12"/></svg>
          </a>
        </div>
      </div>
      <!-- Col 2: Khám phá -->
      <div class="ft-col">
        <h5>Khám phá</h5>
        <ul>
          <li><a onclick="showPage('home')"><span class="ft-li-dot"></span>Trang chủ</a></li>
          <li><a onclick="showPage('tinh-nang')"><span class="ft-li-dot"></span>Tính năng</a></li>
          <li><a onclick="showPage('khoa-hoc')"><span class="ft-li-dot"></span>Khóa học</a></li>
          <li><a onclick="showPage('hoc-phi')"><span class="ft-li-dot"></span>Học phí</a></li>
          <li><a onclick="showPage('lien-he')"><span class="ft-li-dot"></span>Liên hệ</a></li>
        </ul>
      </div>
      <!-- Col 3: Học tập -->
      <div class="ft-col">
        <h5>Học tập</h5>
        <ul>
          <li><a href="#"><span class="ft-li-dot"></span>Java Core</a></li>
          <li><a href="#"><span class="ft-li-dot"></span>Java Web MVC</a></li>
          <li><a href="#"><span class="ft-li-dot"></span>Bài tập &amp; Homework</a></li>
          <li><a href="#"><span class="ft-li-dot"></span>Mentoring 1-1</a></li>
          <li><a href="#"><span class="ft-li-dot"></span>Cộng đồng học viên</a></li>
        </ul>
      </div>
      <!-- Col 4: Liên hệ -->
      <div class="ft-contact">
        <h5>Liên hệ &amp; Hỗ trợ</h5>
        <div class="fc-items">
          <div class="fc-item"><div class="fc-icon">📞</div><div class="fc-text"><strong>0912.345.678</strong>T2–T6: 8:00 – 17:30</div></div>
          <div class="fc-item"><div class="fc-icon">✉️</div><div class="fc-text"><strong>support@studyflow.edu.vn</strong>Phản hồi trong 24 giờ</div></div>
          <div class="fc-item"><div class="fc-icon">📍</div><div class="fc-text"><strong>Số 1 Trường Thi</strong>TP Vinh, Nghệ An</div></div>
          <div class="fc-item"><div class="fc-icon">💬</div><div class="fc-text"><strong>Zalo / Discord</strong>@StudyFlowPlatform · 24/7</div></div>
        </div>
      </div>
    </div>
    <div class="footer-bottom">
      <div class="fb-copy">© 2025 StudyFlow Platform. All rights reserved.</div>
      <div class="fb-links">
        <a href="#">Chính sách bảo mật</a>
        <a href="#">Điều khoản sử dụng</a>
        <a onclick="showPage('lien-he')">Liên hệ</a>
      </div>
      <div class="fb-made">Made with <span>♥</span> tại Nghệ An</div>
    </div>
  </footer>
</div>
<div class="page" id="page-lien-he">
  <div class="contact-page-wrap">
    <!-- HERO -->
    <div class="contact-hero">
      <div class="ch-badge">📩 Liên hệ & Hỗ trợ</div>
      <h1 class="ch-title">Chúng tôi luôn sẵn sàng<br/><span>hỗ trợ bạn</span></h1>
      <p class="ch-sub">Đội ngũ StudyFlow phản hồi trong vòng 24 giờ làm việc — qua hotline, email hoặc Zalo.</p>
    </div>

    <!-- INFO CARDS -->
    <div class="contact-info-row">
      <div class="cir-card">
        <div class="cir-icon c-blue">📞</div>
        <div>
          <div class="cir-label">Hotline</div>
          <div class="cir-val">0912.345.678</div>
          <div class="cir-sub">T2–T6: 8:00–17:30</div>
        </div>
      </div>
      <div class="cir-card">
        <div class="cir-icon c-green">✉️</div>
        <div>
          <div class="cir-label">Email</div>
          <div class="cir-val">support@studyflow.edu.vn</div>
          <div class="cir-sub">Phản hồi trong 24h</div>
        </div>
      </div>
      <div class="cir-card">
        <div class="cir-icon c-purple">📍</div>
        <div>
          <div class="cir-label">Địa chỉ</div>
          <div class="cir-val">Số 1 Trường Thi</div>
          <div class="cir-sub">TP Vinh, Nghệ An</div>
        </div>
      </div>
      <div class="cir-card">
        <div class="cir-icon c-orange">💬</div>
        <div>
          <div class="cir-label">Zalo / Discord</div>
          <div class="cir-val">@StudyFlowPlatform</div>
          <div class="cir-sub">Hỗ trợ 24/7</div>
        </div>
      </div>
    </div>

    <!-- BODY: FORM + SIDE -->
    <div class="contact-body">
      <!-- FORM -->
      <div class="cf-card">
        <% if ("sent".equals(request.getParameter("success")) && "lien-he".equals(request.getParameter("tab"))) { %>
        <div class="form-success" style="display:block">
          <div class="success-icon">🎉</div>
          <div class="success-title">Gửi thành công!</div>
          <p class="success-msg">Cảm ơn bạn đã liên hệ. Chúng tôi sẽ phản hồi qua email hoặc điện thoại trong 24 giờ làm việc.</p>
        </div>
        <% } else { %>
        <div id="formWrap">
          <div class="cf-card-title">✍️ Gửi thông tin cho chúng tôi</div>
          <p class="cf-card-sub">Điền form bên dưới — chúng tôi sẽ phản hồi trong 24 giờ làm việc.</p>
          <form method="post" action="<%= request.getContextPath() %>/contact">
            <input type="hidden" name="redirect" value="/home?tab=lien-he"/>
            <div class="f-row">
              <div class="f-field"><label>Họ và tên *</label><input name="name" type="text" placeholder="Nguyễn Văn A" required/></div>
              <div class="f-field"><label>Email *</label><input name="email" type="email" placeholder="name@example.com" required/></div>
            </div>
            <div class="f-field"><label>Số điện thoại</label><input name="phone" type="tel" placeholder="09xxxxxxxx"/></div>
            <div class="f-field">
              <label>Chủ đề hỗ trợ</label>
              <select name="subject" required>
                <option value="" disabled selected>Chọn chủ đề...</option>
                <option value="Register">Đăng ký tài khoản</option>
                <option value="Course">Thông tin về khóa học</option>
                <option value="Mentoring">Gói Mentoring 1-1</option>
                <option value="Technical">Hỗ trợ kỹ thuật / Lỗi hệ thống</option>
                <option value="Other">Hợp tác và đề xuất khác</option>
              </select>
            </div>
            <div class="f-field"><label>Lời nhắn</label><textarea name="message" required placeholder="Mô tả chi tiết câu hỏi hoặc vấn đề bạn cần hỗ trợ..."></textarea></div>
            <button type="submit" class="btn-submit">📩 Gửi tin nhắn</button>
          </form>
        </div>
        <% } %>
      </div>

      <!-- SIDE PANEL -->
      <div class="contact-side">
        <!-- Map -->
        <div class="cs-map">
          <iframe src="https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d3794.8!2d105.6666!3d18.6802!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x3139cda53d14fe71%3A0x99e37cb4bed3f2f0!2zVHLGsOG7nW5nIFRoaSwgVlAgVmluaCwgTmdo4buHIEFu!5e0!3m2!1svi!2s!4v1620000000000" allowfullscreen="" loading="lazy" referrerpolicy="no-referrer-when-downgrade"></iframe>
        </div>
        <!-- Hours -->
        <div class="cs-hours">
          <div class="cs-hours-title">🕐 Giờ làm việc</div>
          <div class="cs-hour-row">
            <span class="cs-hour-day">Thứ 2 – Thứ 6</span>
            <span class="cs-hour-time">8:00 – 17:30 <span class="cs-badge-open">Mở cửa</span></span>
          </div>
          <div class="cs-hour-row">
            <span class="cs-hour-day">Email (T2–T6)</span>
            <span class="cs-hour-time">8:00 – 20:00</span>
          </div>
          <div class="cs-hour-row">
            <span class="cs-hour-day">Email Cuối tuần</span>
            <span class="cs-hour-time">9:00 – 17:00</span>
          </div>
          <div class="cs-hour-row">
            <span class="cs-hour-day">Zalo / Discord</span>
            <span class="cs-hour-time">24/7 ⚡</span>
          </div>
        </div>
        <!-- Social -->
        <div class="cs-social">
          <div class="cs-social-ico">💬</div>
          <div class="cs-social-text">
            <div class="cs-social-name">Zalo & Discord</div>
            <div class="cs-social-sub">@StudyFlowPlatform — cộng đồng học viên & hỗ trợ 24/7</div>
          </div>
        </div>
      </div>
    </div>
  </div>

  <footer class="site-footer">
    <div class="footer-top">
      <!-- Col 1: Brand + Socials -->
      <div class="ft-brand">
        <div class="f-logo-wrap">
          <div class="flogo">
            <img src="<%= request.getContextPath() %>/logo/StudyFlow.png" alt="StudyFlow Logo" style="height:32px;width:auto;vertical-align:middle;">
          </div>
          <div class="fname">StudyFlow</div>
          <div class="ftag">MIỄN PHÍ</div>
        </div>
        <div class="ft-tagline">Nền tảng học trực tuyến Java</div>
        <p class="ft-desc">Hệ thống học trực tuyến miễn phí dành cho học viên, giảng viên và quản trị viên — tất cả trong một nền tảng duy nhất.</p>
        <div class="ft-socials">
          <a href="https://facebook.com/StudyFlowPlatform" target="_blank" class="ft-soc fb" title="Facebook">
            <svg viewBox="0 0 24 24"><path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z"/></svg>
          </a>
          <a href="https://youtube.com/@StudyFlowPlatform" target="_blank" class="ft-soc yt" title="YouTube">
            <svg viewBox="0 0 24 24"><path d="M23.495 6.205a3.007 3.007 0 0 0-2.088-2.088c-1.87-.501-9.396-.501-9.396-.501s-7.507-.01-9.396.501A3.007 3.007 0 0 0 .527 6.205a31.247 31.247 0 0 0-.522 5.805 31.247 31.247 0 0 0 .522 5.783 3.007 3.007 0 0 0 2.088 2.088c1.868.502 9.396.502 9.396.502s7.506 0 9.396-.502a3.007 3.007 0 0 0 2.088-2.088 31.247 31.247 0 0 0 .5-5.783 31.247 31.247 0 0 0-.5-5.805zM9.609 15.601V8.408l6.264 3.602z"/></svg>
          </a>
          <a href="https://github.com/StudyFlowPlatform" target="_blank" class="ft-soc gh" title="GitHub">
            <svg viewBox="0 0 24 24"><path d="M12 .297c-6.63 0-12 5.373-12 12 0 5.303 3.438 9.8 8.205 11.385.6.113.82-.258.82-.577 0-.285-.01-1.04-.015-2.04-3.338.724-4.042-1.61-4.042-1.61C4.422 18.07 3.633 17.7 3.633 17.7c-1.087-.744.084-.729.084-.729 1.205.084 1.838 1.236 1.838 1.236 1.07 1.835 2.809 1.305 3.495.998.108-.776.417-1.305.76-1.605-2.665-.3-5.466-1.332-5.466-5.93 0-1.31.465-2.38 1.235-3.22-.135-.303-.54-1.523.105-3.176 0 0 1.005-.322 3.3 1.23.96-.267 1.98-.399 3-.405 1.02.006 2.04.138 3 .405 2.28-1.552 3.285-1.23 3.285-1.23.645 1.653.24 2.873.12 3.176.765.84 1.23 1.91 1.23 3.22 0 4.61-2.805 5.625-5.475 5.92.42.36.81 1.096.81 2.22 0 1.606-.015 2.896-.015 3.286 0 .315.21.69.825.57C20.565 22.092 24 17.592 24 12.297c0-6.627-5.373-12-12-12"/></svg>
          </a>
        </div>
      </div>
      <!-- Col 2: Khám phá -->
      <div class="ft-col">
        <h5>Khám phá</h5>
        <ul>
          <li><a onclick="showPage('home')"><span class="ft-li-dot"></span>Trang chủ</a></li>
          <li><a onclick="showPage('tinh-nang')"><span class="ft-li-dot"></span>Tính năng</a></li>
          <li><a onclick="showPage('khoa-hoc')"><span class="ft-li-dot"></span>Khóa học</a></li>
          <li><a onclick="showPage('hoc-phi')"><span class="ft-li-dot"></span>Học phí</a></li>
          <li><a onclick="showPage('lien-he')"><span class="ft-li-dot"></span>Liên hệ</a></li>
        </ul>
      </div>
      <!-- Col 3: Học tập -->
      <div class="ft-col">
        <h5>Học tập</h5>
        <ul>
          <li><a href="#"><span class="ft-li-dot"></span>Java Core</a></li>
          <li><a href="#"><span class="ft-li-dot"></span>Java Web MVC</a></li>
          <li><a href="#"><span class="ft-li-dot"></span>Bài tập &amp; Homework</a></li>
          <li><a href="#"><span class="ft-li-dot"></span>Mentoring 1-1</a></li>
          <li><a href="#"><span class="ft-li-dot"></span>Cộng đồng học viên</a></li>
        </ul>
      </div>
      <!-- Col 4: Liên hệ -->
      <div class="ft-contact">
        <h5>Liên hệ &amp; Hỗ trợ</h5>
        <div class="fc-items">
          <div class="fc-item"><div class="fc-icon">📞</div><div class="fc-text"><strong>0912.345.678</strong>T2–T6: 8:00 – 17:30</div></div>
          <div class="fc-item"><div class="fc-icon">✉️</div><div class="fc-text"><strong>support@studyflow.edu.vn</strong>Phản hồi trong 24 giờ</div></div>
          <div class="fc-item"><div class="fc-icon">📍</div><div class="fc-text"><strong>Số 1 Trường Thi</strong>TP Vinh, Nghệ An</div></div>
          <div class="fc-item"><div class="fc-icon">💬</div><div class="fc-text"><strong>Zalo / Discord</strong>@StudyFlowPlatform · 24/7</div></div>
        </div>
      </div>
    </div>
    <div class="footer-bottom">
      <div class="fb-copy">© 2025 StudyFlow Platform. All rights reserved.</div>
      <div class="fb-links">
        <a href="#">Chính sách bảo mật</a>
        <a href="#">Điều khoản sử dụng</a>
        <a onclick="showPage('lien-he')">Liên hệ</a>
      </div>
      <div class="fb-made">Made with <span>♥</span> tại Nghệ An</div>
    </div>
  </footer>
</div>


<!-- ════ PAGE: HỒ SƠ CÁ NHÂN (chỉ học viên) ════ -->
<% if (_sessionUser != null && "STUDENT".equalsIgnoreCase(_sessionUser.getRole())) { %>
<style>
/* ── Profile Page Reset & Base ── */
#page-ho-so { min-height: 100vh; background: #f0f4ff; font-family: 'Nunito', sans-serif; }

/* ── Hero Banner ── */
.hs-hero {
  background: linear-gradient(135deg, #0d1b4b 0%, #1a3a8f 45%, #2563eb 100%);
  padding: 48px 0 110px;
  position: relative;
  overflow: hidden;
}
.hs-hero::before {
  content: '';
  position: absolute;
  top: -80px; right: -80px;
  width: 320px; height: 320px;
  background: radial-gradient(circle, rgba(99,179,237,.18) 0%, transparent 70%);
  border-radius: 50%;
}
.hs-hero::after {
  content: '';
  position: absolute;
  bottom: -40px; left: 5%;
  width: 200px; height: 200px;
  background: radial-gradient(circle, rgba(255,255,255,.06) 0%, transparent 70%);
  border-radius: 50%;
}
.hs-hero-inner {
  max-width: 1080px;
  margin: 0 auto;
  padding: 0 28px;
  display: flex;
  align-items: center;
  gap: 18px;
  position: relative;
  z-index: 1;
}
.hs-hero-icon {
  width: 52px; height: 52px;
  background: rgba(255,255,255,.15);
  border-radius: 16px;
  display: flex; align-items: center; justify-content: center;
  font-size: 26px;
  border: 1.5px solid rgba(255,255,255,.2);
  backdrop-filter: blur(8px);
  flex-shrink: 0;
}
.hs-hero-title { font-size: 28px; font-weight: 900; color: #fff; letter-spacing: -.4px; line-height: 1.2; }
.hs-hero-sub { font-size: 14px; color: rgba(255,255,255,.65); margin-top: 4px; }

/* ── Main wrap ── */
.hs-wrap {
  max-width: 1080px;
  margin: -78px auto 0;
  padding: 0 28px 80px;
  position: relative;
  z-index: 2;
}

/* ── Profile Card (top big card) ── */
.hs-profile-card {
  background: #fff;
  border-radius: 24px;
  border: 1.5px solid #e2e8f0;
  box-shadow: 0 8px 40px rgba(19,58,143,.13);
  overflow: visible;
  margin-bottom: 24px;
  padding: 36px 36px 32px;
  display: flex;
  align-items: flex-start;
  gap: 32px;
}

/* ── Avatar Block ── */
.hs-avatar-block {
  display: flex;
  flex-direction: column;
  align-items: center;
  flex-shrink: 0;
  width: 150px;
}
.hs-avatar-ring {
  width: 120px;
  height: 120px;
  border-radius: 50%;
  padding: 4px;
  background: linear-gradient(135deg, #2563eb, #7c3aed, #06b6d4);
  box-shadow: 0 8px 32px rgba(37,99,235,.3);
  flex-shrink: 0;
  position: relative;
}
.hs-avatar-inner {
  width: 100%;
  height: 100%;
  border-radius: 50%;
  overflow: hidden;
  background: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
}
.hs-avatar-inner img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  display: block;
}
.hs-avatar-initials {
  width: 100%;
  height: 100%;
  border-radius: 50%;
  background: linear-gradient(135deg, #1354a8, #2563eb);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 36px;
  font-weight: 900;
  color: #fff;
  letter-spacing: -1px;
}
.hs-avatar-edit-btn {
  margin-top: 14px;
  background: #eef2ff;
  border: 1.5px dashed #818cf8;
  color: #4f46e5;
  padding: 8px 16px;
  border-radius: 10px;
  font-size: 12px;
  font-weight: 700;
  cursor: pointer;
  font-family: 'Nunito', sans-serif;
  transition: all .2s;
  display: flex;
  align-items: center;
  gap: 5px;
  white-space: nowrap;
}
.hs-avatar-edit-btn:hover { background: #e0e7ff; border-color: #6366f1; }
.hs-avatar-hint { font-size: 10px; color: #94a3b8; margin-top: 6px; text-align: center; }

/* ── Profile Info (right of avatar) ── */
.hs-profile-info { flex: 1; min-width: 0; }
.hs-user-name { font-size: 26px; font-weight: 900; color: #0f2744; letter-spacing: -.4px; line-height: 1.2; }
.hs-user-username { font-size: 14px; color: #64748b; margin-top: 4px; }
.hs-badge {
  display: inline-flex; align-items: center; gap: 5px;
  background: linear-gradient(135deg, #dbeafe, #ede9fe);
  color: #3730a3;
  border: 1.5px solid #c7d2fe;
  border-radius: 20px;
  padding: 4px 14px;
  font-size: 12px;
  font-weight: 800;
  margin-top: 10px;
  letter-spacing: .2px;
}
.hs-stats-row {
  display: flex;
  gap: 20px;
  margin-top: 22px;
  flex-wrap: wrap;
}
.hs-stat-pill {
  display: flex;
  align-items: center;
  gap: 10px;
  background: #f8fafc;
  border: 1.5px solid #e2e8f0;
  border-radius: 14px;
  padding: 12px 18px;
}
.hs-stat-pill-icon {
  width: 36px; height: 36px;
  border-radius: 10px;
  display: flex; align-items: center; justify-content: center;
  font-size: 18px;
  flex-shrink: 0;
}
.hs-stat-num { font-size: 22px; font-weight: 900; color: #0f2744; line-height: 1; }
.hs-stat-lbl { font-size: 11px; color: #94a3b8; font-weight: 600; margin-top: 2px; }

/* ── Two-column grid below ── */
.hs-grid2 { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; }

/* ── Cards ── */
.hs-card {
  background: #fff;
  border-radius: 20px;
  border: 1.5px solid #e2e8f0;
  padding: 24px 26px;
  box-shadow: 0 2px 14px rgba(0,0,0,.06);
}
.hs-card.full { grid-column: 1 / -1; }
.hs-card-head {
  display: flex; align-items: center; gap: 12px;
  margin-bottom: 20px;
  padding-bottom: 14px;
  border-bottom: 1.5px solid #f1f5f9;
}
.hs-card-icon {
  width: 38px; height: 38px;
  border-radius: 11px;
  display: flex; align-items: center; justify-content: center;
  font-size: 18px;
  flex-shrink: 0;
}
.hs-card-title { font-size: 15px; font-weight: 800; color: #0f2744; }
.hs-card-badge {
  margin-left: auto;
  border-radius: 20px;
  padding: 3px 12px;
  font-size: 12px;
  font-weight: 700;
}

/* ── Info Grid ── */
.hs-info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
.hs-info-label { font-size: 10px; color: #94a3b8; font-weight: 700; text-transform: uppercase; letter-spacing: .6px; margin-bottom: 4px; }
.hs-info-val {
  font-size: 13px; font-weight: 600; color: #1e293b;
  background: #f8fafc; border-radius: 10px;
  padding: 9px 13px;
  border: 1.5px solid #e8edf3;
  overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
}

/* ── Edit Form ── */
.hs-field { margin-bottom: 14px; }
.hs-field label { font-size: 11px; font-weight: 700; color: #475569; display: block; margin-bottom: 5px; text-transform: uppercase; letter-spacing: .4px; }
.hs-field input {
  width: 100%; padding: 10px 14px;
  border: 1.5px solid #e2e8f0; border-radius: 10px;
  font-size: 14px; font-family: 'Nunito', sans-serif;
  outline: none; box-sizing: border-box;
  color: #1e293b;
  transition: border-color .2s, box-shadow .2s;
}
.hs-field input:focus { border-color: #3b82f6; box-shadow: 0 0 0 3px rgba(59,130,246,.12); }
.hs-field-row { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; margin-bottom: 0; }
.hs-save-btn {
  background: linear-gradient(135deg, #1354a8, #2563eb);
  color: #fff; border: none;
  padding: 12px 28px; border-radius: 11px;
  font-size: 14px; font-weight: 800;
  cursor: pointer; font-family: 'Nunito', sans-serif;
  transition: transform .15s, box-shadow .15s;
  display: inline-flex; align-items: center; gap: 7px;
  margin-top: 6px;
  box-shadow: 0 4px 16px rgba(19,84,168,.3);
}
.hs-save-btn:hover { transform: translateY(-1px); box-shadow: 0 8px 24px rgba(19,84,168,.4); }
.hs-save-btn:active { transform: translateY(0); }

/* ── Course Items ── */
.hs-course-list { display: flex; flex-direction: column; gap: 10px; }
.hs-course-item {
  display: flex; align-items: center; gap: 14px;
  padding: 13px 16px;
  background: linear-gradient(135deg, #f8fafc, #f0f4ff);
  border-radius: 14px;
  border: 1.5px solid #dde8f5;
  transition: transform .15s, box-shadow .15s;
}
.hs-course-item:hover { transform: translateX(3px); box-shadow: 0 4px 16px rgba(19,84,168,.1); }
.hs-course-icon {
  width: 44px; height: 44px;
  background: linear-gradient(135deg, #1354a8, #3b82f6);
  border-radius: 12px;
  display: flex; align-items: center; justify-content: center;
  font-size: 22px;
  flex-shrink: 0;
  box-shadow: 0 4px 12px rgba(19,84,168,.25);
}
.hs-course-name { font-size: 14px; font-weight: 700; color: #0f2744; }
.hs-course-teacher { font-size: 12px; color: #64748b; margin-top: 2px; }
.hs-enter-btn {
  background: linear-gradient(135deg, #1354a8, #2563eb);
  color: #fff; padding: 8px 18px;
  border-radius: 10px; font-size: 12px; font-weight: 800;
  text-decoration: none; white-space: nowrap; flex-shrink: 0;
  transition: opacity .15s;
  box-shadow: 0 2px 8px rgba(19,84,168,.25);
}
.hs-enter-btn:hover { opacity: .88; }

/* ── Review Items ── */
.hs-review-item {
  padding: 16px 18px;
  background: linear-gradient(135deg, #fffbeb, #fefce8);
  border-radius: 14px;
  border: 1.5px solid #fde68a;
  margin-bottom: 10px;
}
.hs-review-item:last-child { margin-bottom: 0; }
.hs-review-quote {
  font-size: 13px; color: #374151;
  background: rgba(255,255,255,.7);
  border-radius: 8px; padding: 9px 13px;
  border-left: 3px solid #fbbf24;
  font-style: italic; margin-top: 10px;
  line-height: 1.6;
}

/* ── Empty State ── */
.hs-empty { text-align: center; padding: 32px 0; color: #94a3b8; }
.hs-empty-icon { font-size: 40px; margin-bottom: 8px; }
.hs-empty-text { font-size: 14px; margin-bottom: 14px; }
.hs-empty-cta {
  display: inline-block;
  background: linear-gradient(135deg, #1354a8, #2563eb);
  color: #fff; padding: 9px 22px;
  border-radius: 10px; font-size: 13px; font-weight: 700;
  cursor: pointer; text-decoration: none;
  box-shadow: 0 4px 14px rgba(19,84,168,.3);
}

@media (max-width: 900px) {
  .hs-profile-card { flex-direction: column; align-items: center; text-align: center; padding: 28px 20px; }
  .hs-avatar-block { width: auto; }
  .hs-stats-row { justify-content: center; }
  .hs-grid2 { grid-template-columns: 1fr; }
  .hs-info-grid { grid-template-columns: 1fr; }
  .hs-field-row { grid-template-columns: 1fr; }
  .hs-wrap { padding: 0 16px 60px; }
}
@media (max-width: 600px) {
  .hs-hero { padding: 36px 0 100px; }
  .hs-hero-title { font-size: 22px; }
  .hs-wrap { margin-top: -68px; }
}
</style>
<%
  String _hsSuccess = request.getParameter("success");
  String _hsErr     = request.getParameter("err");
  String _photoPath2 = _sessionUser.getProfilePhoto();
  String _photoUrl2  = (_photoPath2 != null && !_photoPath2.trim().isEmpty())
      ? request.getContextPath() + "/uploads/" + _photoPath2 : null;
  String _fn2 = _sessionUser.getFirstName();
  String _ln2 = _sessionUser.getLastName();
  String _init2 = "";
  if (_fn2 != null && !_fn2.isEmpty()) _init2 += _fn2.charAt(0);
  if (_ln2 != null && !_ln2.isEmpty()) _init2 += _ln2.charAt(0);
  if (_init2.isEmpty()) _init2 = _sessionUser.getUsername().substring(0,1).toUpperCase();
%>

<div class="page" id="page-ho-so">

  <!-- ── Hero Banner ── -->
  <div class="hs-hero">
    <div class="hs-hero-inner">
      <div class="hs-hero-icon">👤</div>
      <div>
        <div class="hs-hero-title">Hồ sơ cá nhân</div>
        <div class="hs-hero-sub">Quản lý thông tin và theo dõi hoạt động học tập</div>
      </div>
    </div>
  </div>

  <div class="hs-wrap">

    <!-- Toast / Error -->
    <% if ("profileUpdated".equals(_hsSuccess) || "photoUpdated".equals(_hsSuccess)) { %>
    <div id="hsToast" style="position:fixed;bottom:28px;right:28px;z-index:9999;background:linear-gradient(135deg,#0f2744,#1354a8);color:#fff;padding:14px 22px;border-radius:16px;font-size:14px;font-weight:700;box-shadow:0 8px 36px rgba(0,0,0,.25);display:flex;align-items:center;gap:10px;animation:notifyPop .3s ease;">
      <span style="font-size:22px;"><%= "photoUpdated".equals(_hsSuccess) ? "🖼️" : "✅" %></span>
      <%= "photoUpdated".equals(_hsSuccess) ? "Cập nhật ảnh đại diện thành công!" : "Lưu thông tin thành công!" %>
    </div>
    <script>setTimeout(function(){ var t=document.getElementById('hsToast'); if(t){ t.style.transition='opacity .5s'; t.style.opacity='0'; setTimeout(function(){ t.style.display='none'; },500); } }, 3000);</script>
    <% } %>
    <% if (_hsErr != null && !_hsErr.isEmpty()) { %>
    <div style="background:#fee2e2;border:1.5px solid #fca5a5;color:#991b1b;padding:13px 20px;border-radius:14px;margin-bottom:20px;font-size:14px;font-weight:600;display:flex;align-items:center;gap:10px;">
      ❌ <% if ("fileTooLarge".equals(_hsErr)) { %>Ảnh quá lớn, vui lòng chọn ảnh dưới 2MB.
         <% } else if ("invalidFile".equals(_hsErr)) { %>Định dạng file không hợp lệ, chỉ chấp nhận ảnh.
         <% } else if ("emptyFields".equals(_hsErr)) { %>Vui lòng điền đầy đủ họ và tên.
         <% } else if ("emailTaken".equals(_hsErr)) { %>Email này đã được sử dụng bởi tài khoản khác.
         <% } else { %>Đã xảy ra lỗi, vui lòng thử lại.<% } %>
    </div>
    <% } %>

    <!-- ── Profile Summary Card ── -->
    <div class="hs-profile-card">

      <!-- Avatar -->
      <div class="hs-avatar-block">
        <div class="hs-avatar-ring">
          <div class="hs-avatar-inner">
            <% if (_photoUrl2 != null) { %>
            <img src="<%= _photoUrl2 %>" alt="Avatar">
            <% } else { %>
            <div class="hs-avatar-initials"><%= _init2.toUpperCase() %></div>
            <% } %>
          </div>
        </div>
        <button class="hs-avatar-edit-btn" onclick="document.getElementById('hs-photo-input').click()">
          📷 Đổi ảnh
        </button>
        <form id="hs-photo-form" action="<%= request.getContextPath() %>/profile/photo" method="post" enctype="multipart/form-data" style="display:none;">
          <input type="hidden" name="redirectTo" value="/home?tab=ho-so">
          <input type="file" id="hs-photo-input" name="photo" accept="image/*" onchange="document.getElementById('hs-photo-form').submit()">
        </form>
        <div class="hs-avatar-hint">JPG · PNG · Tối đa 2MB</div>
      </div>

      <!-- Info -->
      <div class="hs-profile-info">
        <div class="hs-user-name"><%= _sessionUser.getFullName() %></div>
        <div class="hs-user-username">@<%= _sessionUser.getUsername() %></div>
        <div class="hs-badge">🎓 Học viên</div>
        <div class="hs-stats-row">
          <div class="hs-stat-pill">
            <div class="hs-stat-pill-icon" style="background:#dbeafe;">📚</div>
            <div>
              <div class="hs-stat-num"><%= _enrolledCount %></div>
              <div class="hs-stat-lbl">Khóa học</div>
            </div>
          </div>
          <div class="hs-stat-pill">
            <div class="hs-stat-pill-icon" style="background:#fef3c7;">⭐</div>
            <div>
              <div class="hs-stat-num"><%= _myReviews.size() %></div>
              <div class="hs-stat-lbl">Đánh giá</div>
            </div>
          </div>
          <div class="hs-stat-pill">
            <div class="hs-stat-pill-icon" style="background:#dcfce7;">✉️</div>
            <div>
              <div class="hs-stat-num" style="font-size:13px;font-weight:700;margin-top:2px;"><%= _sessionUser.getEmail() != null && !_sessionUser.getEmail().isEmpty() ? _sessionUser.getEmail() : "Chưa cập nhật" %></div>
              <div class="hs-stat-lbl">Email</div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- ── 2-column grid ── -->
    <div class="hs-grid2">

      <!-- Thông tin tài khoản -->
      <div class="hs-card">
        <div class="hs-card-head">
          <div class="hs-card-icon" style="background:#eef2ff;">📋</div>
          <span class="hs-card-title">Thông tin tài khoản</span>
        </div>
        <div class="hs-info-grid">
          <div>
            <div class="hs-info-label">Tên đăng nhập</div>
            <div class="hs-info-val">👤 <%= _sessionUser.getUsername() %></div>
          </div>
          <div>
            <div class="hs-info-label">Email</div>
            <div class="hs-info-val">📧 <%= _sessionUser.getEmail() != null && !_sessionUser.getEmail().isEmpty() ? _sessionUser.getEmail() : "Chưa cập nhật" %></div>
          </div>
          <div>
            <div class="hs-info-label">Họ</div>
            <div class="hs-info-val"><%= _sessionUser.getFirstName() != null ? _sessionUser.getFirstName() : "Chưa cập nhật" %></div>
          </div>
          <div>
            <div class="hs-info-label">Tên</div>
            <div class="hs-info-val"><%= _sessionUser.getLastName() != null ? _sessionUser.getLastName() : "Chưa cập nhật" %></div>
          </div>
          <% if (_sessionUser.getStudentId() != null && !_sessionUser.getStudentId().isEmpty()) { %>
          <div>
            <div class="hs-info-label">Mã sinh viên</div>
            <div class="hs-info-val">🎫 <%= _sessionUser.getStudentId() %></div>
          </div>
          <% } %>
          <% if (_sessionUser.getDepartment() != null && !_sessionUser.getDepartment().isEmpty()) { %>
          <div>
            <div class="hs-info-label">Khoa / Bộ môn</div>
            <div class="hs-info-val">🏛️ <%= _sessionUser.getDepartment() %></div>
          </div>
          <% } %>
        </div>
      </div>

      <!-- Chỉnh sửa thông tin -->
      <div class="hs-card">
        <div class="hs-card-head">
          <div class="hs-card-icon" style="background:#f0fdf4;">✏️</div>
          <span class="hs-card-title">Chỉnh sửa thông tin</span>
        </div>
        <form id="hs-edit-form" action="<%= request.getContextPath() %>/profile" method="post">
          <input type="hidden" name="redirectTo" value="/home?tab=ho-so">
          <div class="hs-field-row">
            <div class="hs-field">
              <label>Họ *</label>
              <input type="text" name="firstName" value="<%= _sessionUser.getFirstName() != null ? _sessionUser.getFirstName() : "" %>" required>
            </div>
            <div class="hs-field">
              <label>Tên *</label>
              <input type="text" name="lastName" value="<%= _sessionUser.getLastName() != null ? _sessionUser.getLastName() : "" %>" required>
            </div>
          </div>
          <div class="hs-field" style="margin-top:14px;">
            <label>Email</label>
            <input type="email" name="email" value="<%= _sessionUser.getEmail() != null ? _sessionUser.getEmail() : "" %>">
          </div>
          <button type="button" class="hs-save-btn" onclick="document.getElementById('hsConfirmModal').style.display='flex'">
            💾 Lưu thay đổi
          </button>
        </form>
      </div>

      <!-- Khóa học đã đăng ký -->
      <div class="hs-card full">
        <div class="hs-card-head">
          <div class="hs-card-icon" style="background:#dbeafe;">📚</div>
          <span class="hs-card-title">Khóa học đã đăng ký</span>
          <span class="hs-card-badge" style="background:#dbeafe;color:#1d4ed8;"><%= _enrolledCount %></span>
        </div>
        <% if (_enrolledCourses.isEmpty()) { %>
        <div class="hs-empty">
          <div class="hs-empty-icon">📭</div>
          <div class="hs-empty-text">Bạn chưa đăng ký khóa học nào.</div>
          <a onclick="showPage('khoa-hoc')" class="hs-empty-cta">📚 Khám phá khóa học</a>
        </div>
        <% } else { %>
        <div class="hs-course-list">
          <% for (CourseDTO _ec : _enrolledCourses) { %>
          <div class="hs-course-item">
            <div class="hs-course-icon">📖</div>
            <div style="flex:1;min-width:0;">
              <div class="hs-course-name"><%= _ec.getName() %></div>
              <div class="hs-course-teacher">Giảng viên: <%= _ec.getTeacherName() != null ? _ec.getTeacherName() : "—" %></div>
            </div>
            <a href="<%= request.getContextPath() %>/classroom?courseId=<%= _ec.getId() %>" class="hs-enter-btn">▶ Vào học</a>
          </div>
          <% } %>
        </div>
        <% } %>
      </div>

      <!-- Đánh giá giảng viên -->
      <div class="hs-card full">
        <div class="hs-card-head">
          <div class="hs-card-icon" style="background:#fef3c7;">⭐</div>
          <span class="hs-card-title">Đánh giá giảng viên của tôi</span>
          <span class="hs-card-badge" style="background:#fef3c7;color:#d97706;"><%= _myReviews.size() %></span>
        </div>
        <% if (_myReviews.isEmpty()) { %>
        <div class="hs-empty">
          <div class="hs-empty-icon">📝</div>
          <div class="hs-empty-text">Bạn chưa gửi đánh giá giảng viên nào.<br><span style="font-size:12px;">Vào phòng học để đánh giá giảng viên.</span></div>
        </div>
        <% } else { %>
        <div>
          <% for (TeacherReviewDTO _rv : _myReviews) { %>
          <div class="hs-review-item">
            <div style="display:flex;align-items:center;justify-content:space-between;">
              <div>
                <div style="font-size:14px;font-weight:700;color:#0f2744;">👨‍🏫 <%= _rv.getTeacherName() %></div>
                <div style="font-size:12px;color:#64748b;margin-top:2px;">📚 <%= _rv.getCourseName() %></div>
              </div>
              <div style="text-align:right;">
                <div style="font-size:17px;color:#f59e0b;line-height:1;">
                  <% int _sr = _rv.getRating() != null ? _rv.getRating() : 0; for (int _s=1;_s<=5;_s++){out.print(_s<=_sr?"★":"☆");} %>
                </div>
                <div style="font-size:11px;color:#94a3b8;margin-top:3px;"><%= _rv.getCreatedAt().length()>10?_rv.getCreatedAt().substring(0,10):_rv.getCreatedAt() %></div>
              </div>
            </div>
            <% if (_rv.getComment() != null && !_rv.getComment().isEmpty()) { %>
            <div class="hs-review-quote">"<%= _rv.getComment() %>"</div>
            <% } %>
          </div>
          <% } %>
        </div>
        <% } %>
      </div>

      <!-- ═══ Card: Đổi mật khẩu ═══ -->
      <div class="hs-card full">
        <div class="hs-card-head">
          <div class="hs-card-icon" style="background:#fce7f3;">🔐</div>
          <span class="hs-card-title">Đổi mật khẩu</span>
        </div>
        <% String _pwErr = request.getParameter("err"); String _pwOk = request.getParameter("success"); %>
        <% if ("passwordChanged".equals(_pwOk)) { %>
        <div style="padding:10px 16px;background:#f0fdf4;border-radius:10px;color:#15803d;font-size:13px;font-weight:600;margin-bottom:14px;">✅ Đổi mật khẩu thành công!</div>
        <% } else if ("passwordTooShort".equals(_pwErr)) { %>
        <div style="padding:10px 16px;background:#fef2f2;border-radius:10px;color:#dc2626;font-size:13px;font-weight:600;margin-bottom:14px;">⚠️ Mật khẩu mới phải có ít nhất 8 ký tự</div>
        <% } else if ("passwordMismatch".equals(_pwErr)) { %>
        <div style="padding:10px 16px;background:#fef2f2;border-radius:10px;color:#dc2626;font-size:13px;font-weight:600;margin-bottom:14px;">⚠️ Mật khẩu xác nhận không khớp</div>
        <% } else if ("wrongOldPassword".equals(_pwErr)) { %>
        <div style="padding:10px 16px;background:#fef2f2;border-radius:10px;color:#dc2626;font-size:13px;font-weight:600;margin-bottom:14px;">⚠️ Mật khẩu hiện tại không đúng</div>
        <% } %>
        <form method="post" action="<%= request.getContextPath() %>/security" style="display:grid;grid-template-columns:1fr 1fr 1fr;gap:14px;align-items:end;">
          <div>
            <label style="font-size:11px;font-weight:700;color:#64748b;text-transform:uppercase;letter-spacing:.5px;display:block;margin-bottom:6px;">Mật khẩu hiện tại</label>
            <div style="position:relative;">
              <input type="password" name="oldPassword" id="hs_oldPass" placeholder="Nhập mật khẩu hiện tại" required
                style="width:100%;box-sizing:border-box;padding:10px 40px 10px 14px;border:1.5px solid #e2e8f0;border-radius:10px;font-size:13px;outline:none;background:#f8fafc;"
                onfocus="this.style.borderColor='#ec4899'" onblur="this.style.borderColor='#e2e8f0'"/>
              <span onclick="var i=document.getElementById('hs_oldPass');i.type=i.type==='password'?'text':'password'" style="position:absolute;right:12px;top:50%;transform:translateY(-50%);cursor:pointer;font-size:14px;opacity:.5;">👁</span>
            </div>
          </div>
          <div>
            <label style="font-size:11px;font-weight:700;color:#64748b;text-transform:uppercase;letter-spacing:.5px;display:block;margin-bottom:6px;">Mật khẩu mới</label>
            <div style="position:relative;">
              <input type="password" name="newPassword" id="hs_newPass" placeholder="Tối thiểu 8 ký tự" required minlength="8"
                style="width:100%;box-sizing:border-box;padding:10px 40px 10px 14px;border:1.5px solid #e2e8f0;border-radius:10px;font-size:13px;outline:none;background:#f8fafc;"
                onfocus="this.style.borderColor='#ec4899'" onblur="this.style.borderColor='#e2e8f0'"/>
              <span onclick="var i=document.getElementById('hs_newPass');i.type=i.type==='password'?'text':'password'" style="position:absolute;right:12px;top:50%;transform:translateY(-50%);cursor:pointer;font-size:14px;opacity:.5;">👁</span>
            </div>
          </div>
          <div>
            <label style="font-size:11px;font-weight:700;color:#64748b;text-transform:uppercase;letter-spacing:.5px;display:block;margin-bottom:6px;">Xác nhận mật khẩu mới</label>
            <div style="position:relative;">
              <input type="password" name="confirmPassword" id="hs_confirmPass" placeholder="Nhập lại mật khẩu mới" required
                style="width:100%;box-sizing:border-box;padding:10px 40px 10px 14px;border:1.5px solid #e2e8f0;border-radius:10px;font-size:13px;outline:none;background:#f8fafc;"
                onfocus="this.style.borderColor='#ec4899'" onblur="this.style.borderColor='#e2e8f0'"/>
              <span onclick="var i=document.getElementById('hs_confirmPass');i.type=i.type==='password'?'text':'password'" style="position:absolute;right:12px;top:50%;transform:translateY(-50%);cursor:pointer;font-size:14px;opacity:.5;">👁</span>
            </div>
          </div>
          <div style="grid-column:1/-1;display:flex;justify-content:flex-end;margin-top:4px;">
            <button type="submit"
              style="padding:11px 32px;background:linear-gradient(135deg,#ec4899,#db2777);color:#fff;border:none;border-radius:11px;font-size:13px;font-weight:700;cursor:pointer;box-shadow:0 3px 10px rgba(236,72,153,.3);transition:opacity .15s;"
              onmouseenter="this.style.opacity='.88'" onmouseleave="this.style.opacity='1'">
              🔐 Cập nhật mật khẩu
            </button>
          </div>
        </form>
      </div>

    </div><!-- end hs-grid2 -->
  </div><!-- end hs-wrap -->
</div>

<!-- Confirm Save Modal -->
<div id="hsConfirmModal" style="display:none;position:fixed;inset:0;z-index:9999;align-items:center;justify-content:center;">
  <div onclick="document.getElementById('hsConfirmModal').style.display='none'" style="position:absolute;inset:0;background:rgba(15,23,42,.5);backdrop-filter:blur(6px);"></div>
  <div style="position:relative;background:#fff;border-radius:24px;padding:40px 36px 32px;width:400px;max-width:92vw;box-shadow:0 32px 80px rgba(0,0,0,.25);animation:notifyPop .28s cubic-bezier(.34,1.56,.64,1);text-align:center;z-index:1;">
    <div style="position:absolute;top:0;left:0;right:0;height:5px;border-radius:24px 24px 0 0;background:linear-gradient(90deg,#3b82f6,#1354a8);"></div>
    <div style="font-size:50px;margin-bottom:14px;line-height:1;">💾</div>
    <div style="font-size:19px;font-weight:800;color:#1a2332;margin-bottom:10px;">Xác nhận lưu thay đổi</div>
    <div style="font-size:14px;color:#64748b;line-height:1.7;margin-bottom:28px;">Bạn có chắc muốn cập nhật thông tin cá nhân không?</div>
    <div style="display:flex;gap:12px;">
      <button type="button" onclick="document.getElementById('hsConfirmModal').style.display='none'"
        style="flex:1;padding:13px 0;border-radius:12px;border:1.5px solid #e2e8f0;background:#fff;color:#64748b;font-size:14px;font-weight:700;cursor:pointer;font-family:'Nunito',sans-serif;">
        Hủy
      </button>
      <button type="button" onclick="document.getElementById('hsConfirmModal').style.display='none';document.getElementById('hs-edit-form').submit()"
        style="flex:1;padding:13px 0;border-radius:12px;border:none;background:linear-gradient(135deg,#1354a8,#2563eb);color:#fff;font-size:14px;font-weight:700;cursor:pointer;font-family:'Nunito',sans-serif;">
        ✓ Xác nhận
      </button>
    </div>
  </div>
</div>

<% } %>

<!-- TOAST -->
<div class="toast" id="toast">
  <div class="t-ico" id="t-ico">✅</div>
  <div><div class="t-ttl" id="t-ttl"></div><div class="t-msg" id="t-msg"></div></div>
</div>

<script>
  window.StudyFlowConfig = {
    contextPath: '<%= request.getContextPath() %>',
    courses: <%= _coursesJson.toString() %>,
    isLoggedIn: <%= (_sessionUser != null) ? "true" : "false" %>,
    userRole: '<%= (_sessionUser != null && _sessionUser.getRole() != null) ? _sessionUser.getRole().toLowerCase() : "guest" %>'
  };
</script>
<script src="<%= request.getContextPath() %>/js/home.js"></script>
<script>
  // Tự động chuyển tab từ URL param — chạy SAU home.js load
  (function(){
    function _switchTab() {
      var p = new URLSearchParams(window.location.search);
      var t = p.get('tab');
      if (t && typeof showPage === 'function') { showPage(t); }
    }
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', _switchTab);
    } else {
      _switchTab();
    }
  })();
</script>
</body>
</html>