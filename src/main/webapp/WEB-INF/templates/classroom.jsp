<%@ page contentType="text/html;charset=UTF-8" language="java"
         import="com.example.demo.entity.User, com.example.demo.dto.CourseDTO, com.example.demo.dto.VideoDTO, com.example.demo.dto.HomeworkDTO, com.example.demo.dto.TeacherReviewDTO, java.util.List, java.util.ArrayList" %>
<%
// ─── รับข้อมูลจาก ClassroomServlet ──────────────────────────────────────────
// ClassroomServlet ตรวจ session, สิทธิ์, และดึงข้อมูลทั้งหมดก่อน forward มาที่นี่

User   user         = (User)   request.getAttribute("user");
if (user == null) user = (User) session.getAttribute("user");

CourseDTO course    = (CourseDTO) request.getAttribute("course");

@SuppressWarnings("unchecked")
List<VideoDTO> videos  = (List<VideoDTO>) request.getAttribute("videos");
if (videos == null) videos = new ArrayList<VideoDTO>();

VideoDTO  currentVideo = (VideoDTO) request.getAttribute("currentVideo");
if (currentVideo == null && !videos.isEmpty()) currentVideo = videos.get(0);

boolean enrolled    = request.getAttribute("enrolled") != null ? (Boolean) request.getAttribute("enrolled") : false;
boolean isStaff     = request.getAttribute("isStaff") != null ? (Boolean) request.getAttribute("isStaff") : false;
boolean isOwner     = request.getAttribute("isOwner") != null ? (Boolean) request.getAttribute("isOwner") : false;

Integer enrollCountObj = (Integer) request.getAttribute("enrollCount");
int enrollCount = enrollCountObj != null ? enrollCountObj : 0;

@SuppressWarnings("unchecked")
List<HomeworkDTO> myHomeworks  = (List<HomeworkDTO>) request.getAttribute("myHomeworks");
if (myHomeworks  == null) myHomeworks  = new ArrayList<HomeworkDTO>();

@SuppressWarnings("unchecked")
List<HomeworkDTO> allHomeworks = (List<HomeworkDTO>) request.getAttribute("allHomeworks");
if (allHomeworks == null) allHomeworks = new ArrayList<HomeworkDTO>();

@SuppressWarnings("unchecked")
List<HomeworkDTO> teacherFiles = (List<HomeworkDTO>) request.getAttribute("teacherFiles");
if (teacherFiles == null) teacherFiles = new ArrayList<HomeworkDTO>();

String flashSuccess = (String) request.getAttribute("flashSuccess");
String flashError   = (String) request.getAttribute("flashError");

@SuppressWarnings("unchecked")
List<TeacherReviewDTO> courseReviews = (List<TeacherReviewDTO>) request.getAttribute("courseReviews");
if (courseReviews == null) courseReviews = new ArrayList<TeacherReviewDTO>();
double avgRating = request.getAttribute("avgRating") != null ? (Double) request.getAttribute("avgRating") : 0.0;
long reviewCount = request.getAttribute("reviewCount") != null ? (Long) request.getAttribute("reviewCount") : 0L;
boolean alreadyReviewed = request.getAttribute("alreadyReviewed") != null ? (Boolean) request.getAttribute("alreadyReviewed") : false;
String teacherPhoto = request.getAttribute("teacherPhoto") != null ? (String) request.getAttribute("teacherPhoto") : "";
Integer teacherIdForReview = request.getAttribute("teacherIdForReview") != null ? (Integer) request.getAttribute("teacherIdForReview") : 0;

// ── ถ้า Servlet ไม่ได้ forward มา (เข้าตรง) ให้ redirect ────────────────────
if (course == null || user == null) {
    response.sendRedirect(request.getContextPath() + "/dashboard?tab=courses");
    return;
}

int courseId = course.getId();
String role  = user.getRole().toLowerCase();

// ─── Helper: YouTube ID จาก URL ───────────────────────────────────────────
java.util.function.Function<String,String> getYtId = url -> {
    if (url == null || url.isEmpty()) return null;
    if (url.contains("youtu.be/")) {
        String[] p = url.split("youtu\\.be/");
        if (p.length > 1) return p[1].split("[?&]")[0];
    }
    if (url.contains("v=")) {
        String[] p = url.split("v=");
        if (p.length > 1) return p[1].split("[?&]")[0];
    }
    if (url.contains("/embed/")) {
        String[] p = url.split("/embed/");
        if (p.length > 1) return p[1].split("[?&/]")[0];
    }
    return null;
};

// thumbnail ของคอร์ส = thumbnail ของวิดีโอแรก
String courseThumbnail = null;
if (!videos.isEmpty()) {
    String ytId = getYtId.apply(videos.get(0).getFilePath());
    if (ytId != null && !ytId.isEmpty())
        courseThumbnail = "https://img.youtube.com/vi/" + ytId + "/mqdefault.jpg";
}

// embed URL ของวิดีโอปัจจุบัน
String embedUrl = "";
if (currentVideo != null && currentVideo.getFilePath() != null && !currentVideo.getFilePath().isEmpty()) {
    String fp    = currentVideo.getFilePath();
    String ytId  = getYtId.apply(fp);
    if (ytId != null && !ytId.isEmpty()) {
        embedUrl = "https://www.youtube.com/embed/" + ytId + "?rel=0&autoplay=1";
    } else if (fp.contains("drive.google.com/file/d/")) {
        String[] p = fp.split("/d/");
        if (p.length > 1) {
            String fid = p[1].split("/")[0];
            embedUrl = "https://drive.google.com/file/d/" + fid + "/preview";
        }
    } else if (fp.contains("vimeo.com")) {
        String[] p = fp.split("vimeo\\.com/");
        if (p.length > 1) embedUrl = "https://player.vimeo.com/video/" + p[1].split("[?/]")[0];
    } else {
        embedUrl = fp;
    }
}
%>
<!DOCTYPE html>
<html lang="th">
<head>
<meta charset="UTF-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1.0"/>
<title><%= course.getName() %> | StudyFlow</title>
<link rel="stylesheet" href="<%= request.getContextPath() %>/css/classroom.css">
</head>
<body>

<!-- NAVBAR -->
<nav class="navbar">
  <div class="nav-left">
    <a href="<%= request.getContextPath() %>/home" class="nav-brand">
      <div class="nav-logo">
        <img src="<%= request.getContextPath() %>/logo/StudyFlow.png" alt="StudyFlow Logo" style="height: 32px; width: auto; vertical-align: middle;">
      </div>
      <span class="nav-name">StudyFlow</span>
    </a>
  </div>
  <div class="nav-right">
    <a href="<%= request.getContextPath() %>/dashboard?tab=courses" class="btn-nav btn-nav-ghost">📚 Khóa học</a>
    <div class="nav-user">
      <div class="nav-avatar"><%= user.getUsername().substring(0,1).toUpperCase() %></div>
      <span><%= user.getUsername() %></span>
    </div>
    <a href="<%= request.getContextPath() %>/logout" class="btn-nav btn-nav-ghost">Đăng xuất</a>
  </div>
</nav>

<!-- HERO -->
<section class="hero">
  <div class="hero-inner">
    <div class="hero-body">
      <% if (isStaff) { %>
      <div style="display:inline-flex;align-items:center;gap:7px;background:rgba(255,255,255,0.15);border:1.5px solid rgba(255,255,255,0.35);border-radius:999px;padding:5px 14px;font-size:12px;font-weight:700;color:#fff;margin-bottom:12px;backdrop-filter:blur(6px);">
        <% if (role.equals("super_admin")) { %>
          👑 Super Admin — Chế độ quản lý
        <% } else if (role.equals("admin")) { %>
          🛡️ Admin — Chế độ quản lý
        <% } else { %>
          👨‍🏫 Giảng viên — Chế độ giảng dạy
        <% } %>
      </div>
      <% } %>
      <div class="hero-label">Phòng học</div>
      <div class="hero-title"><%= course.getName() %></div>
      <div class="hero-meta">
        <span class="hero-meta-item">👨‍🏫 <%= course.getTeacherName().isEmpty() ? "Giảng viên" : course.getTeacherName() %></span>
        <span class="hero-meta-item">🎬 <%= videos.size() %> bài học</span>
        <span class="hero-meta-item">👥 <%= enrollCount %> học viên</span>
        <% String _cat = course.getCategory();
           if (_cat != null && !_cat.isEmpty() && !_cat.equalsIgnoreCase("General")) { %>
        <span class="hero-meta-item">📂 <%= _cat %></span>
        <% } %>
      </div>
      <% String _desc = course.getDescription();
         if (_desc != null && _desc.trim().length() > 0) { %>
      <div style="font-size:14px;color:rgba(255,255,255,.75);margin-bottom:16px;line-height:1.7;max-width:520px;"><%= _desc.trim() %></div>
      <% } %>
      <div style="display:flex;align-items:center;gap:12px;flex-wrap:wrap;">
        <% if (enrolled) { %>
        <div class="enrolled-badge">✅ Đã đăng ký</div>
        <% } else if (isStaff) { %>
        <div class="enrolled-badge">🏫 <%= role.equals("teacher") ? "Giảng viên" : "Quản trị viên" %></div>
        <% } else { %>
        <a href="<%= request.getContextPath() %>/enroll?courseId=<%= courseId %>" class="btn-enroll">▶ Đăng ký học</a>
        <% } %>
        <a href="<%= request.getContextPath() %>/dashboard?tab=courses" class="btn-nav btn-nav-ghost" style="text-decoration:none;">← Quay lại</a>
      </div>
    </div>
    <div class="hero-thumb">
      <% if (courseThumbnail != null) { %>
      <img src="<%= courseThumbnail %>" alt="<%= course.getName() %>" onerror="this.style.display='none';this.parentElement.innerHTML='<div class=\'hero-thumb-noimg\'>🎓</div>'"/>
      <div class="hero-thumb-overlay">
        <div class="play-btn" onclick="document.querySelector('.tab-btn').click()">▶</div>
      </div>
      <% } else { %>
      <div class="hero-thumb-noimg">🎓</div>
      <% } %>
    </div>
  </div>
</section>

<!-- TABS -->
<div class="tabs-wrap">
  <div class="tabs-inner">
    <button class="tab-btn active" onclick="switchTab('video',this)">▶ Bài học</button>
    <button class="tab-btn" onclick="switchTab('detail',this)">Chi tiết</button>
    <button class="tab-btn" onclick="switchTab('instructor',this)">Giảng viên</button>
    <button class="tab-btn" onclick="switchTab('homework',this)">Bài tập</button>
    <button class="tab-btn" onclick="switchTab('review',this)">⭐ Đánh giá</button>
    <% if (isOwner) { %>
    <button class="tab-btn" style="color:#92400e;" onclick="switchTab('manage',this)">⚙️ Quản lý</button>
    <% } %>
  </div>
</div>

<!-- ── TOAST กลางหน้าจอ ── -->
<% if (flashSuccess != null) { %>
<div class="toast-overlay" id="toastOverlay">
  <div class="toast toast-success" id="toastEl">
    <span class="toast-ico">✅</span>
    <div class="toast-body">
      <div class="toast-title">Thành công!</div>
      <div class="toast-msg"><%= flashSuccess %></div>
    </div>
    <button class="toast-close" onclick="closeToast()">✕</button>
  </div>
</div>
<% } %>
<% if (flashError != null) { %>
<div class="toast-overlay" id="toastOverlay">
  <div class="toast toast-error" id="toastEl">
    <span class="toast-ico">❌</span>
    <div class="toast-body">
      <div class="toast-title">Đã xảy ra lỗi</div>
      <div class="toast-msg"><%= flashError %></div>
    </div>
    <button class="toast-close" onclick="closeToast()">✕</button>
  </div>
</div>
<% } %>

<!-- PAGE CONTENT -->
<div class="page-content">
  <div class="content-main">

    <!-- ═══ TAB: บทเรียน ══════════════════════════════════════════════ -->
    <div class="section active" id="tab-video">
      <%-- Progress bar --%>
      <% if ((enrolled || isStaff) && !videos.isEmpty()) {
           int watchedCount = (currentVideo != null) ? videos.indexOf(currentVideo) + 1 : 0;
           int totalCount   = videos.size();
           int pct = totalCount > 0 ? (watchedCount * 100 / totalCount) : 0;
      %>
      <div class="progress-wrap">
        <div class="progress-label">
          <span>🎬 Tiến độ</span>
          <span><%= watchedCount %>/<%= totalCount %> bài (<%= pct %>%)</span>
        </div>
        <div class="progress-bar"><div class="progress-fill" style="width:<%= pct %>%;"></div></div>
      </div>
      <% } %>
      <%-- ══ Khóa nội dung: Học viên chưa đăng ký sẽ không thể xem bài học ══ --%>
      <% if (!enrolled && !isStaff) { %>
      <div class="lock-content-wall" style="text-align:center;padding:60px 20px;background:var(--card);border-radius:16px;border:2px dashed var(--border);margin-bottom:20px;">
        <div style="font-size:56px;margin-bottom:16px;">🔒</div>
        <div style="font-size:20px;font-weight:800;color:var(--text);margin-bottom:8px;">Nội dung bài học bị khóa</div>
        <div style="font-size:14px;color:var(--text3);margin-bottom:20px;max-width:360px;margin-left:auto;margin-right:auto;">Bạn cần đăng ký khóa học trước mới có thể xem bài học và video trong khóa học này</div>
        <a href="<%= request.getContextPath() %>/enroll?courseId=<%= courseId %>" class="btn btn-primary" style="padding:12px 28px;font-size:15px;font-weight:700;">▶ Đăng ký học ngay</a>
        <% if (!videos.isEmpty()) { %>
        <div style="margin-top:20px;font-size:12px;color:var(--text3);">Khóa học có tổng cộng <%= videos.size() %> bài học đang chờ bạn</div>
        <% } %>
      </div>
      <% } else if (currentVideo != null) { %>
      <div style="margin-bottom:14px;display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:8px;">
        <div>
          <div style="font-size:18px;font-weight:800;color:var(--text);">
            Bài <%= currentVideo.getOrderNo() > 0 ? currentVideo.getOrderNo() : (videos.indexOf(currentVideo)+1) %>: <%= currentVideo.getTitle() %>
          </div>
          <% if (!currentVideo.getDescription().isEmpty()) { %>
          <div style="font-size:13px;color:var(--text3);margin-top:3px;"><%= currentVideo.getDescription() %></div>
          <% } %>
        </div>
        <div style="display:flex;gap:8px;">
          <% int ci = videos.indexOf(currentVideo);
             if (ci > 0) { VideoDTO prev = videos.get(ci-1); %>
          <a href="<%= request.getContextPath() %>/classroom?courseId=<%= courseId %>&videoId=<%= prev.getId() %>" class="btn btn-ghost btn-sm">← Trước</a>
          <% } %>
          <% if (ci < videos.size()-1) { VideoDTO next = videos.get(ci+1); %>
          <a href="<%= request.getContextPath() %>/classroom?courseId=<%= courseId %>&videoId=<%= next.getId() %>" class="btn btn-primary btn-sm">Tiếp theo →</a>
          <% } %>
        </div>
      </div>

      <div class="player-wrap">
        <% if (!embedUrl.isEmpty()) { %>
        <iframe src="<%= embedUrl %>" allowfullscreen allow="autoplay; encrypted-media"></iframe>
        <% } else { %>
        <div class="player-placeholder">
          <div class="play-ico">🎬</div>
          <p>Chưa có URL video cho bài này</p>
        </div>
        <% } %>
      </div>

      <div style="font-size:15px;font-weight:700;margin-bottom:12px;">📋 Danh sách bài học (<%= videos.size() %> bài)</div>
      <div class="lesson-list">
        <% for (int i = 0; i < videos.size(); i++) {
             VideoDTO v = videos.get(i);
             boolean isCurrent = (currentVideo != null && v.getId() == currentVideo.getId());
             String ytIdV = null;
             String fp2 = v.getFilePath();
             if (fp2 != null) {
               if (fp2.contains("youtu.be/")) { String[] p = fp2.split("youtu\\.be/"); if (p.length>1) ytIdV = p[1].split("[?&]")[0]; }
               else if (fp2.contains("v=")) { String[] p = fp2.split("v="); if (p.length>1) ytIdV = p[1].split("[?&]")[0]; }
               else if (fp2.contains("/embed/")) { String[] p = fp2.split("/embed/"); if (p.length>1) ytIdV = p[1].split("[?&/]")[0]; }
             }
             String thumbV = ytIdV != null ? "https://img.youtube.com/vi/" + ytIdV + "/mqdefault.jpg" : null;
        %>
        <a class="lesson-card <%= isCurrent ? "current" : "" %>" href="<%= request.getContextPath() %>/classroom?courseId=<%= courseId %>&videoId=<%= v.getId() %>">
          <div class="lesson-num"><%= i+1 %></div>
          <% if (thumbV != null) { %>
          <div class="lesson-thumb"><img src="<%= thumbV %>" alt="" onerror="this.style.display='none'"/></div>
          <% } %>
          <div class="lesson-info">
            <div class="lesson-title"><%= v.getTitle() %></div>
            <% if (!v.getDescription().isEmpty()) { %>
            <div class="lesson-desc"><%= v.getDescription() %></div>
            <% } else if (!v.getDuration().isEmpty()) { %>
            <div class="lesson-desc">⏱ <%= v.getDuration() %></div>
            <% } %>
          </div>
          <% if (isCurrent) { %>
          <span class="lesson-badge playing">▶ Đang học</span>
          <% } else { %>
          <span class="lesson-badge">Bài <%= i+1 %></span>
          <% } %>
        </a>
        <% } %>
        <% if (videos.isEmpty()) { %>
        <div style="text-align:center;padding:40px;color:var(--text3);">
          <div style="font-size:40px;margin-bottom:10px;">📭</div>
          <div style="font-size:15px;font-weight:600;">Chưa có bài học nào trong khóa học này</div>
          <% if (isOwner) { %>
          <div style="font-size:13px;color:var(--text3);margin-top:6px;">Nhấn "Quản lý" để thêm bài học</div>
          <% } %>
        </div>
        <% } %>
      </div>
      <% } else { %>
      <div style="text-align:center;padding:60px 20px;color:var(--text3);">
        <div style="font-size:60px;margin-bottom:16px;">🎬</div>
        <div style="font-size:18px;font-weight:700;margin-bottom:8px;">Chưa có bài học</div>
        <p style="font-size:14px;">Khóa học này chưa có bài học<% if(isOwner){%> Nhấn "Quản lý" để thêm bài học đầu tiên<% } %></p>
      </div>
      <% } %>
    </div>

    <!-- ═══ TAB: รายละเอียด ══════════════════════════════════════════ -->
    <div class="section" id="tab-detail">
      <h2 class="section-title">Chi tiết khóa học</h2>
      <div class="highlight-box">
        <h3>Về khóa học này</h3>
        <p style="font-size:14px;color:var(--text2);line-height:1.8;">
          <% if (course.getDescription() != null && !course.getDescription().trim().isEmpty()) { %>
          <%= course.getDescription() %>
          <% } else { %>
          <span style="color:var(--text3);">Chưa có mô tả khóa học</span>
          <% } %>
        </p>
      </div>
      <div class="highlight-box">
        <h3>Thông tin khóa học</h3>
        <div style="display:grid;grid-template-columns:1fr 1fr;gap:12px;font-size:14px;color:var(--text2);">
          <div>📚 Số lượng bài học: <strong><%= videos.size() %> bài</strong></div>
          <div>👥 Học viên: <strong><%= enrollCount %> người</strong></div>
          <div>📂 Danh mục: <strong><%= course.getCategory() %></strong></div>
          <div>🔖 Trạng thái: <strong><%= course.getStatus() %></strong></div>
          <div>👨‍🏫 Giảng viên: <strong><%= course.getTeacherName().isEmpty() ? "-" : course.getTeacherName() %></strong></div>
          <% if (course.getCreatedAt() != null) { %>
          <div>📅 Ngày tạo: <strong><%= course.getCreatedAt().length() >= 10 ? course.getCreatedAt().substring(0,10) : course.getCreatedAt() %></strong></div>
          <% } %>
        </div>
      </div>
    </div>

    <!-- ═══ TAB: ผู้สอน ══════════════════════════════════════════════ -->
    <div class="section" id="tab-instructor">
      <h2 class="section-title">Giảng viên</h2>
      <div class="inst-card">
        <%
          String _tPhotoUrl = (teacherPhoto != null && !teacherPhoto.trim().isEmpty())
              ? request.getContextPath() + "/uploads/" + teacherPhoto : null;
          String _tInit = "";
          String _tFullName = course.getTeacherName().isEmpty() ? "Giảng viên" : course.getTeacherName();
          String[] _tWords = _tFullName.trim().split(" ");
          if (_tWords.length > 0 && !_tWords[0].isEmpty()) _tInit += _tWords[0].charAt(0);
          if (_tWords.length > 1 && !_tWords[_tWords.length-1].isEmpty()) _tInit += _tWords[_tWords.length-1].charAt(0);
          if (_tInit.isEmpty()) _tInit = "GV";
        %>
        <% if (_tPhotoUrl != null) { %>
        <div class="inst-avatar" style="padding:0;overflow:hidden;">
          <img src="<%= _tPhotoUrl %>" alt="<%= _tFullName %>"
               style="width:100%;height:100%;object-fit:cover;border-radius:50%;display:block;">
        </div>
        <% } else { %>
        <div class="inst-avatar" style="font-size:22px;font-weight:900;letter-spacing:-1px;"><%= _tInit.toUpperCase() %></div>
        <% } %>
        <div>
          <div class="inst-name"><%= course.getTeacherName().isEmpty() ? "Giảng viên" : course.getTeacherName() %></div>
          <div class="inst-tags">
            <span class="inst-tag">✓ Giảng viên đã xác minh</span>
            <span class="inst-tag">📚 <%= course.getCategory() %></span>
          </div>
          <div class="inst-bio">Giảng viên khóa học "<%= course.getName() %>"<br/>Có <%= enrollCount %> học viên đã đăng ký · <%= videos.size() %> bài học</div>
        </div>
      </div>
    </div>

    <!-- ═══ TAB: การบ้าน ════════════════════════════════════════════ -->
    <div class="section" id="tab-homework">
      <h2 class="section-title">Bài tập</h2>

      <%-- ══ ส่วนที่ 1: ไฟล์การบ้านจากครู/admin ══════════════════════════════ --%>
      <% if (isOwner) { %>
      <%-- เจ้าของคอร์ส: เห็นฟอร์มอัปโหลด + รายการไฟล์ + ปุ่มลบ --%>
      <div class="hw-card" style="margin-bottom:18px;">
        <div class="hw-title-row">
          <div class="hw-title">📂 Tệp bài tập từ giáo viên (<%= teacherFiles.size() %> tệp)</div>
          <button class="hw-open-btn" id="teacherHwBtn" onclick="toggleTeacherHwForm()">📤 Tải lên tệp</button>
        </div>
        <div class="hw-form-wrap" id="teacherHwForm">
          <form method="post" action="<%= request.getContextPath() %>/homework" enctype="multipart/form-data">
            <input type="hidden" name="courseId" value="<%= courseId %>"/>
            <input type="hidden" name="action" value="uploadTeacher"/>
            <div class="form-group">
              <label class="form-label">Tiêu đề tệp *</label>
              <input class="form-control" type="text" name="hwTitle" placeholder="Ví dụ: Bài tập bài 1, Câu hỏi thực hành..." required/>
            </div>
            <div class="form-group">
              <label class="form-label">Mô tả</label>
              <textarea class="form-control" name="hwDesc" rows="2" placeholder="Chi tiết thêm (nếu có)..."></textarea>
            </div>
            <div class="form-group">
              <label class="form-label">Đính kèm tệp (nếu có)</label>
              <input class="form-control" type="file" name="hwFile" accept=".pdf,.doc,.docx,.zip,.jpg,.jpeg,.png,.txt,.pptx,.xlsx"/>
            </div>
            <div style="display:flex;gap:8px;justify-content:flex-end;margin-top:10px;">
              <button type="button" class="btn btn-ghost" onclick="toggleTeacherHwForm()">Hủy</button>
              <button type="submit" class="btn btn-primary">📤 Tải lên</button>
            </div>
          </form>
        </div>
        <% if (!teacherFiles.isEmpty()) { %>
        <div style="margin-top:14px;display:flex;flex-direction:column;gap:10px;">
        <% for (HomeworkDTO tf : teacherFiles) { %>
        <div style="display:flex;align-items:center;gap:12px;padding:14px 16px;border:1px solid var(--border);border-radius:10px;background:var(--white);">
          <div style="width:40px;height:40px;border-radius:10px;background:#eff6ff;display:flex;align-items:center;justify-content:center;font-size:20px;flex-shrink:0;">📄</div>
          <div style="flex:1;min-width:0;">
            <div style="font-size:14px;font-weight:700;color:var(--text);"><%= tf.getTitle() %></div>
            <% if (tf.getDescription() != null && !tf.getDescription().isEmpty()) { %>
            <div style="font-size:12px;color:var(--text2);margin-top:2px;"><%= tf.getDescription() %></div>
            <% } %>
            <div style="font-size:11px;color:var(--text3);margin-top:4px;">🕐 <%= tf.getSubmittedAt() != null && tf.getSubmittedAt().length() >= 10 ? tf.getSubmittedAt().substring(0,10) : "" %></div>
          </div>
          <div style="display:flex;align-items:center;gap:8px;flex-shrink:0;">
            <% if (tf.getFilePath() != null && !tf.getFilePath().isEmpty()) { %>
            <a href="<%= request.getContextPath() %>/<%= tf.getFilePath() %>" target="_blank"
               style="display:inline-flex;align-items:center;gap:5px;font-size:12px;font-weight:700;color:#fff;background:#3b82f6;padding:6px 14px;border-radius:8px;text-decoration:none;">
              📥 <%= tf.getFileName() != null ? tf.getFileName() : "Tải xuống" %>
            </a>
            <% } else { %>
            <span style="font-size:12px;color:var(--text3);">Không có tệp</span>
            <% } %>
            <% String tfTitleEscaped = tf.getTitle() != null ? tf.getTitle().replace("'", "\\'") : ""; %>
            <button type="button" onclick="openDeleteHw(<%= tf.getId() %>,'<%= tfTitleEscaped %>')" class="btn btn-danger btn-sm" title="Xóa">🗑️</button>
          </div>
        </div>
        <% } %>
        </div>
        <% } else { %>
        <div style="margin-top:10px;padding:20px;text-align:center;color:var(--text3);font-size:13px;border:1px dashed var(--border);border-radius:8px;">
          Chưa có tệp bài tập — nhấn nút <strong>📤 Tải lên tệp</strong> ở trên để thêm
        </div>
        <% } %>
      </div>

      <%-- Học viênที่ enrolled (รวม isStaff ที่ไม่ใช่ owner): เห็นไฟล์ครูแบบ read-only --%>
      <% } else { %>
      <% if (!teacherFiles.isEmpty()) { %>
      <div class="hw-card" style="margin-bottom:18px;">
        <div class="hw-title-row">
          <div class="hw-title">📂 Tệp bài tập từ giáo viên (<%= teacherFiles.size() %> tệp)</div>
        </div>
        <div style="margin-top:14px;display:flex;flex-direction:column;gap:10px;">
        <% for (HomeworkDTO tf : teacherFiles) { %>
        <div style="display:flex;align-items:center;gap:12px;padding:14px 16px;border:1px solid var(--border);border-radius:10px;background:var(--white);">
          <div style="width:40px;height:40px;border-radius:10px;background:#eff6ff;display:flex;align-items:center;justify-content:center;font-size:20px;flex-shrink:0;">📄</div>
          <div style="flex:1;min-width:0;">
            <div style="font-size:14px;font-weight:700;color:var(--text);"><%= tf.getTitle() %></div>
            <% if (tf.getDescription() != null && !tf.getDescription().isEmpty()) { %>
            <div style="font-size:12px;color:var(--text2);margin-top:2px;"><%= tf.getDescription() %></div>
            <% } %>
            <div style="font-size:11px;color:var(--text3);margin-top:4px;">🕐 <%= tf.getSubmittedAt() != null && tf.getSubmittedAt().length() >= 10 ? tf.getSubmittedAt().substring(0,10) : "" %></div>
          </div>
          <% if (tf.getFilePath() != null && !tf.getFilePath().isEmpty()) { %>
          <a href="<%= request.getContextPath() %>/<%= tf.getFilePath() %>" target="_blank"
             style="display:inline-flex;align-items:center;gap:5px;font-size:12px;font-weight:700;color:#fff;background:#3b82f6;padding:6px 14px;border-radius:8px;text-decoration:none;flex-shrink:0;">
            📥 <%= tf.getFileName() != null ? tf.getFileName() : "Tải xuống" %>
          </a>
          <% } else { %>
          <span style="font-size:12px;color:var(--text3);flex-shrink:0;">Không có tệp</span>
          <% } %>
        </div>
        <% } %>
        </div>
      </div>
      <% } %>
      <% } %>

      <%-- ══ ส่วนที่ 2: Học viênส่งการบ้าน ══════════════════════════════════ --%>
      <% if (enrolled && !isStaff) { %>
      <div class="hw-card">
        <div class="hw-title-row">
          <div class="hw-title">📝 Nộp bài tập cho khóa học này</div>
          <button class="hw-open-btn" id="hwBtn" onclick="toggleHw()">✏️ Nộp bài tập</button>
        </div>
        <div class="hw-form-wrap" id="hwForm">
          <form method="post" action="<%= request.getContextPath() %>/homework" enctype="multipart/form-data">
            <input type="hidden" name="courseId" value="<%= courseId %>"/>
            <% if (currentVideo != null) { %><input type="hidden" name="videoId" value="<%= currentVideo.getId() %>"/><% } %>
            <input type="hidden" name="action" value="submit"/>
            <div class="form-group">
              <label class="form-label">Tiêu đề bài tập *</label>
              <input class="form-control" type="text" name="hwTitle" placeholder="Tên bài tập của bạn" required/>
            </div>
            <div class="form-group">
              <label class="form-label">Mô tả</label>
              <textarea class="form-control" name="hwDesc" rows="3" placeholder="Giải thích thêm hoặc liên kết bài làm..."></textarea>
            </div>
            <div class="form-group">
              <label class="form-label">Đính kèm tệp (nếu có)</label>
              <input class="form-control" type="file" name="hwFile" accept=".pdf,.doc,.docx,.zip,.jpg,.jpeg,.png,.txt"/>
            </div>
            <div style="display:flex;gap:8px;justify-content:flex-end;margin-top:10px;">
              <button type="button" class="btn btn-ghost" onclick="toggleHw()">Hủy</button>
              <button type="submit" class="btn btn-primary">📤 Nộp bài tập</button>
            </div>
          </form>
        </div>

        <% if (!myHomeworks.isEmpty()) { %>
        <div style="margin-top:18px;padding-top:14px;border-top:1px dashed var(--border);">
          <div style="font-size:13px;font-weight:700;color:var(--text2);margin-bottom:10px;">📋 Lịch sử nộp bài (<%= myHomeworks.size() %> lần)</div>
          <% for (HomeworkDTO hw : myHomeworks) { %>
          <div class="hw-item">
            <div class="hw-item-ico">📋</div>
            <div style="flex:1;min-width:0;">
              <div class="hw-item-title"><%= hw.getTitle() %></div>
              <div class="hw-item-meta">
                <span>🕐 <%= hw.getSubmittedAt() != null && hw.getSubmittedAt().length() >= 10 ? hw.getSubmittedAt().substring(0,10) : hw.getSubmittedAt() %></span>
                <span class="hw-status <%= "REVIEWED".equals(hw.getStatus()) ? "reviewed" : "pending" %>">
                  <%= "REVIEWED".equals(hw.getStatus()) ? "✓ Đã chấm" : "⏳ Chờ chấm" %>
                </span>
              </div>
              <% if (hw.getDescription() != null && !hw.getDescription().isEmpty()) { %>
              <div style="font-size:12px;color:var(--text2);margin-top:4px;"><%= hw.getDescription() %></div>
              <% } %>
              <% if (hw.getFileName() != null && !hw.getFileName().isEmpty()) { %>
              <a href="<%= request.getContextPath() %>/<%= hw.getFilePath() %>" target="_blank"
                 style="font-size:12px;color:#3b82f6;margin-top:4px;display:inline-block;">📎 <%= hw.getFileName() %></a>
              <% } %>
              <%-- ══ แสดงคะแนน + feedback (ฝั่งนักเรียน) ══ --%>
              <% if ("REVIEWED".equals(hw.getStatus())) { %>
              <div style="margin-top:8px;padding:10px 12px;background:#f0fdf4;border-left:3px solid #16a34a;border-radius:0 8px 8px 0;">
                <% if (hw.getScore() != null) {
                     int pct = (int)Math.round(hw.getScore() * 100.0 / (hw.getMaxScore() != null ? hw.getMaxScore() : 100));
                     String barColor = pct >= 80 ? "#16a34a" : pct >= 50 ? "#d97706" : "#ef4444"; %>
                <div style="display:flex;align-items:center;gap:8px;margin-bottom:8px;">
                  <span style="font-size:11px;font-weight:700;color:#15803d;">🏅 Điểm của bạn:</span>
                  <span style="font-size:20px;font-weight:800;color:#15803d;"><%= hw.getScore() %></span>
                  <span style="font-size:13px;color:#4ade80;">/ <%= hw.getMaxScore() != null ? hw.getMaxScore() : 100 %></span>
                  <div style="flex:1;background:#dcfce7;border-radius:99px;height:8px;overflow:hidden;min-width:60px;">
                    <div style="height:100%;background:<%= barColor %>;border-radius:99px;width:<%= pct %>%;"></div>
                  </div>
                  <span style="font-size:11px;color:#15803d;"><%= pct %>%</span>
                </div>
                <% } %>
                <% if (hw.getTeacherComment() != null && !hw.getTeacherComment().trim().isEmpty()) { %>
                <div style="font-size:11px;font-weight:700;color:#15803d;margin-bottom:3px;">💬 Nhận xét của giảng viên</div>
                <div style="font-size:13px;color:#166534;line-height:1.5;"><%= hw.getTeacherComment() %></div>
                <% } else if (hw.getScore() == null) { %>
                <div style="font-size:12px;color:#15803d;font-style:italic;">✓ Giảng viên đã chấm (không có nhận xét thêm)</div>
                <% } %>
              </div>
              <% } %>
            </div>
          </div>
          <% } %>
        </div>
        <% } else { %>
        <div style="margin-top:14px;padding-top:14px;border-top:1px dashed var(--border);text-align:center;color:var(--text3);font-size:13px;">Chưa có bài tập nào được nộp</div>
        <% } %>
      </div>
      <% } %>

      <%-- ══ ส่วนที่ 3: ครูเห็นการบ้านของHọc viên + ปุ่มลบ ══════════════════ --%>
      <% if (isOwner) { %>
      <div class="highlight-box" style="margin-top:18px;">
        <h3>📬 Bài tập học viên đã nộp (<%= allHomeworks.size() %> mục)</h3>
        <% if (!allHomeworks.isEmpty()) { %>
        <div style="overflow-x:auto;">
          <table class="hw-table">
            <thead><tr><th>Học viên</th><th>Tiêu đề</th><th>Nộp lúc</th><th>Trạng thái</th><th>Điểm</th><th>Tệp</th><th>Quản lý</th></tr></thead>
            <tbody>
              <% for (HomeworkDTO hw : allHomeworks) { %>
              <tr>
                <td><strong><%= hw.getStudentName() != null && !hw.getStudentName().isEmpty() ? hw.getStudentName() : "Học viên #"+hw.getStudentId() %></strong></td>
                <td>
                  <%= hw.getTitle() %>
                  <% if (hw.getDescription() != null && !hw.getDescription().isEmpty()) { %>
                  <div style="font-size:11px;color:var(--text3);"><%= hw.getDescription().length()>60 ? hw.getDescription().substring(0,60)+"..." : hw.getDescription() %></div>
                  <% } %>
                </td>
                <td style="white-space:nowrap;font-size:12px;color:var(--text3);">
                  <%= hw.getSubmittedAt() != null && hw.getSubmittedAt().length() >= 10 ? hw.getSubmittedAt().substring(0,10) : hw.getSubmittedAt() %>
                </td>
                <td>
                  <span class="hw-status <%= "REVIEWED".equals(hw.getStatus()) ? "reviewed" : "pending" %>">
                    <%= "REVIEWED".equals(hw.getStatus()) ? "✓ Đã chấm" : "⏳ Chờ chấm" %>
                  </span>
                </td>
                <td style="text-align:center;white-space:nowrap;">
                  <% if (hw.getScore() != null) { %>
                  <span style="font-weight:700;color:#15803d;font-size:15px;"><%= hw.getScore() %></span>
                  <span style="font-size:12px;color:#6b7280;">/<%= hw.getMaxScore() != null ? hw.getMaxScore() : 100 %></span>
                  <% } else { %>
                  <span style="font-size:12px;color:#d1d5db;">—</span>
                  <% } %>
                </td>
                <td>
                  <% if (hw.getFileName() != null && !hw.getFileName().isEmpty()) { %>
                  <a href="<%= request.getContextPath() %>/<%= hw.getFilePath() %>" target="_blank"
                     style="font-size:12px;color:#3b82f6;">📎 <%= hw.getFileName() %></a>
                  <% } else { %><span style="color:var(--text3);font-size:12px;">-</span><% } %>
                </td>
                <td style="white-space:nowrap;">
                  <div style="display:flex;gap:6px;align-items:center;flex-wrap:wrap;">
                  <% if (!"REVIEWED".equals(hw.getStatus())) { %>
                  <button class="btn btn-primary btn-sm"
                    onclick="openReviewModal(<%= hw.getId() %>,'<%= hw.getStudentName().replace("'","\'") %>','<%= hw.getTitle().replace("'","\'") %>')"
                    title="Chấm bài tập">✓ Chấm</button>
                  <% } else { %>
                  <span style="font-size:11px;color:#15803d;font-weight:700;white-space:nowrap;">✓ Đã chấm</span>
                  <% } %>
                  <% String hwTitleEscaped = hw.getTitle() != null ? hw.getTitle().replace("'", "\\'") : ""; %>
                  <button type="button" onclick="openDeleteHw(<%= hw.getId() %>,'<%= hwTitleEscaped %>')" class="btn btn-danger btn-sm" title="Xóa">🗑️</button>
                  </div>
                </td>
              </tr>
              <% } %>
            </tbody>
          </table>
        </div>
        <% } else { %>
        <div style="text-align:center;padding:20px;color:var(--text3);font-size:14px;">Chưa có học viên nào nộp bài tập trong khóa học này</div>
        <% } %>
      </div>
      <% } %>

      <% if (!enrolled && !isStaff) { %>
      <div style="text-align:center;padding:40px 20px;color:var(--text3);">
        <div style="font-size:40px;margin-bottom:10px;">🔒</div>
        <div style="font-size:15px;font-weight:600;margin-bottom:8px;">Cần phải đăng ký trước</div>
        <a href="<%= request.getContextPath() %>/enroll?courseId=<%= courseId %>" class="btn btn-primary">Đăng ký miễn phí</a>
      </div>
      <% } %>
    </div>

        <!-- ═══ TAB: Đánh giá giảng viên ══════════════════════════════════════════ -->
    <div class="section" id="tab-review">
      <h2 class="section-title">⭐ Đánh giá giảng viên</h2>

      <%-- Tổng hợp điểm đánh giá --%>
      <div class="highlight-box" style="margin-bottom:20px;">
        <div style="display:flex;align-items:center;gap:20px;flex-wrap:wrap;">
          <div style="text-align:center;min-width:100px;">
            <div style="font-size:48px;font-weight:900;color:#f59e0b;line-height:1;"><%= String.format("%.1f", avgRating) %></div>
            <div style="font-size:22px;color:#f59e0b;margin:4px 0;">
              <% for (int s=1;s<=5;s++) { %><%= s <= Math.round(avgRating) ? "★" : "☆" %><% } %>
            </div>
            <div style="font-size:12px;color:var(--text3);"><%= reviewCount %> đánh giá</div>
          </div>
          <div style="flex:1;min-width:180px;">
            <% int[] starCounts = new int[6];
               for (TeacherReviewDTO rv : courseReviews) { if (rv.getRating()>=1 && rv.getRating()<=5) starCounts[rv.getRating()]++; }
               for (int s=5;s>=1;s--) {
                 int cnt = starCounts[s];
                 int pct = courseReviews.isEmpty() ? 0 : (cnt*100/courseReviews.size()); %>
            <div style="display:flex;align-items:center;gap:8px;margin-bottom:4px;font-size:12px;">
              <span style="width:32px;color:var(--text2)"><%= s %>⭐</span>
              <div style="flex:1;height:8px;background:var(--border);border-radius:4px;overflow:hidden;">
                <div style="height:100%;background:#f59e0b;width:<%= pct %>%;border-radius:4px;transition:.3s;"></div>
              </div>
              <span style="width:28px;color:var(--text3);"><%= cnt %></span>
            </div>
            <% } %>
          </div>
        </div>
      </div>

      <%-- ฟอร์มรีวิว (เฉพาะHọc viênที่ลงทะเบียนแล้ว) --%>
      <% if (enrolled && !isStaff && teacherIdForReview > 0) { %>
      <div class="highlight-box" style="margin-bottom:20px;background:var(--white);">
        <% if (alreadyReviewed) { %>
        <div style="text-align:center;padding:16px;color:#15803d;">
          <div style="font-size:24px;margin-bottom:8px;">✅</div>
          <div style="font-weight:700;font-size:15px;">Bạn đã đánh giá giảng viên rồi</div>
          <div style="font-size:13px;color:var(--text3);margin-top:4px;">Cảm ơn phản hồi của bạn. Mỗi khóa học chỉ được đánh giá một lần</div>
        </div>
        <% } else { %>
        <h3 style="margin-bottom:14px;">✍️ Chia sẻ cảm nhận về giảng viên</h3>
        <form method="post" action="<%= request.getContextPath() %>/teacher-review">
          <input type="hidden" name="action"    value="submit"/>
          <input type="hidden" name="courseId"  value="<%= courseId %>"/>
          <input type="hidden" name="teacherId" value="<%= teacherIdForReview %>"/>
          <div class="form-group">
            <label class="form-label">Điểm đánh giá *</label>
            <div id="starRating" style="display:flex;gap:6px;font-size:28px;cursor:pointer;margin-bottom:4px;">
              <% for (int s=1;s<=5;s++) { %>
              <span class="star-btn" data-val="<%= s %>" onclick="setRating(<%= s %>)" style="color:#d1d5db;transition:.2s;" title="<%= s %> sao">★</span>
              <% } %>
            </div>
            <input type="hidden" name="rating" id="ratingInput" value="0"/>
            <div id="ratingLabel" style="font-size:12px;color:var(--text3);height:16px;"></div>
          </div>
          <div class="form-group" style="margin-top:10px;">
            <label class="form-label">Nhận xét (không bắt buộc)</label>
            <textarea class="form-control" name="comment" rows="3" placeholder="Chia sẻ trải nghiệm học tập của bạn..."></textarea>
          </div>
          <div style="display:flex;justify-content:flex-end;margin-top:10px;">
            <button type="submit" class="btn btn-primary" onclick="return document.getElementById('ratingInput').value>0||alert('Vui lòng chọn số sao trước')">⭐ Gửi đánh giá</button>
          </div>
        </form>
        <% } %>
      </div>
      <% } else if (!isStaff && !enrolled) { %>
      <div class="highlight-box" style="text-align:center;padding:24px;color:var(--text3);">
        <div style="font-size:32px;margin-bottom:8px;">🔒</div>
        <div style="font-size:14px;font-weight:600;">Bạn cần đăng ký học trước mới có thể đánh giá giảng viên</div>
        <a href="<%= request.getContextPath() %>/enroll?courseId=<%= courseId %>" class="btn btn-primary" style="margin-top:12px;display:inline-block;">▶ Đăng ký học</a>
      </div>
      <% } %>

      <%-- รายการรีวิวทั้งหมด --%>
      <% if (!courseReviews.isEmpty()) { %>
      <div style="display:flex;flex-direction:column;gap:12px;">
        <% for (TeacherReviewDTO rv : courseReviews) { %>
        <div style="padding:16px;border:1px solid var(--border);border-radius:12px;background:var(--white);position:relative;">
          <div style="display:flex;align-items:center;gap:10px;margin-bottom:8px;">
            <div style="width:38px;height:38px;border-radius:50%;background:#dbeafe;display:flex;align-items:center;justify-content:center;font-size:16px;font-weight:700;color:#1d4ed8;flex-shrink:0;">
              <%= rv.getStudentName().isEmpty() ? "?" : rv.getStudentName().substring(0,1).toUpperCase() %>
            </div>
            <div style="flex:1;">
              <div style="font-weight:700;font-size:14px;color:var(--text);"><%= rv.getStudentName().isEmpty() ? "Học viên" : rv.getStudentName() %></div>
              <div style="font-size:11px;color:var(--text3);">
                <%= rv.getCreatedAt().length() >= 10 ? rv.getCreatedAt().substring(0,10) : rv.getCreatedAt() %>
              </div>
            </div>
            <div style="font-size:18px;color:#f59e0b;">
              <% for (int s=1;s<=5;s++) { %><%= s <= rv.getRating() ? "★" : "☆" %><% } %>
            </div>
          </div>
          <% if (!rv.getComment().isEmpty()) { %>
          <div style="font-size:14px;color:var(--text2);line-height:1.6;padding:8px 12px;background:var(--bg);border-radius:8px;"><%= rv.getComment() %></div>
          <% } %>
          <%-- Xóa đánh giá của chính mình --%>
          <% if (!isStaff && user.getId() != null && user.getId().equals(rv.getStudentId())) { %>
          <button type="button" onclick="openDeleteReview(<%= rv.getId() %>)" style="background:none;border:none;cursor:pointer;font-size:14px;position:absolute;top:12px;right:12px;" title="Xóa đánh giá">🗑️</button>
          <% } %>
        </div>
        <% } %>
      </div>
      <% } else { %>
      <div style="text-align:center;padding:40px;color:var(--text3);">
        <div style="font-size:40px;margin-bottom:10px;">💬</div>
        <div style="font-size:14px;">Chưa có đánh giá nào trong khóa học này. Hãy là người đầu tiên!</div>
      </div>
      <% } %>
    </div>

        <!-- ═══ TAB: จัดการ (teacher/admin เท่านั้น) ══════════════════ -->
    <% if (isOwner) { %>
    <div class="section" id="tab-manage">
      <h2 class="section-title">⚙️ Quản lý lớp học</h2>

      <div class="manage-panel">
        <div class="manage-panel-title">➕ Thêm bài học mới</div>
        <form method="post" action="<%= request.getContextPath() %>/classroom">
          <input type="hidden" name="courseId" value="<%= courseId %>"/>
          <input type="hidden" name="videoAction" value="addVideo"/>
          <div class="form-group">
            <label class="form-label">Tên bài học *</label>
            <input class="form-control" type="text" name="videoTitle" placeholder="Ví dụ: Bài 1: Giới thiệu" required/>
          </div>
          <div class="form-group">
            <label class="form-label">Mô tả</label>
            <input class="form-control" type="text" name="videoDesc" placeholder="Ngắn gọn như: Nội dung giới thiệu và tổng quan khóa học"/>
          </div>
          <div class="form-group">
            <label class="form-label">URL Video * <span style="font-size:11px;font-weight:400;color:var(--text3);">(YouTube / Google Drive / Vimeo)</span></label>
            <input class="form-control" type="url" name="videoUrl" placeholder="https://www.youtube.com/watch?v=..." required/>
            <div style="font-size:11px;color:var(--text3);margin-top:4px;">Hỗ trợ: youtube.com, youtu.be, drive.google.com, vimeo.com</div>
          </div>
          <button type="submit" class="btn btn-primary">➕ Thêm bài học</button>
        </form>
      </div>

      <div class="highlight-box">
        <h3>📋 Danh sách bài học (<%= videos.size() %> bài)</h3>
        <% if (videos.isEmpty()) { %>
        <div style="text-align:center;padding:30px;color:var(--text3);font-size:14px;">Chưa có bài học — thêm từ biểu mẫu ở trên</div>
        <% } else { %>
        <div style="display:flex;flex-direction:column;gap:10px;margin-top:10px;">
          <% for (int i = 0; i < videos.size(); i++) { VideoDTO v = videos.get(i); %>
          <div style="display:flex;align-items:center;gap:12px;padding:12px 14px;border:1px solid var(--border);border-radius:8px;background:var(--white);">
            <div style="font-size:13px;font-weight:700;color:var(--text3);min-width:24px;">#<%= i+1 %></div>
            <div style="flex:1;min-width:0;">
              <div style="font-size:14px;font-weight:600;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;"><%= v.getTitle() %></div>
              <% if (!v.getDescription().isEmpty()) { %>
              <div style="font-size:12px;color:var(--text3);"><%= v.getDescription() %></div>
              <% } %>
              <div style="font-size:11px;color:var(--text3);margin-top:2px;">🔗 <%= v.getFilePath() != null ? v.getFilePath() : "-" %></div>
            </div>
            <div style="display:flex;gap:6px;flex-shrink:0;">
              <button class="btn btn-warning btn-sm"
                data-id="<%= v.getId() %>"
                data-course="<%= courseId %>"
                data-title="<%= v.getTitle().replace("\"", "&quot;").replace("<", "&lt;") %>"
                data-desc="<%= v.getDescription().replace("\"", "&quot;").replace("<", "&lt;") %>"
                data-url="<%= (v.getFilePath()!=null?v.getFilePath():"").replace("\"", "&quot;") %>"
                onclick="openEditVideo(this)">✏️ Sửa</button>
              <button class="btn btn-danger btn-sm" onclick="openDeleteVideo(<%= v.getId() %>,'<%= v.getTitle().replace("'","\\'") %>')">🗑️ Xóa</button>
            </div>
          </div>
          <% } %>
        </div>
        <% } %>
      </div>

      <div class="highlight-box">
        <h3>📊 Thống kê khóa học</h3>
        <div style="display:grid;grid-template-columns:1fr 1fr 1fr;gap:16px;text-align:center;">
          <div style="padding:16px;background:var(--green-light);border-radius:10px;">
            <div style="font-size:28px;font-weight:800;color:var(--green);"><%= videos.size() %></div>
            <div style="font-size:12px;color:var(--text2);margin-top:4px;">Bài học</div>
          </div>
          <div style="padding:16px;background:#e0f2fe;border-radius:10px;">
            <div style="font-size:28px;font-weight:800;color:#0369a1;"><%= enrollCount %></div>
            <div style="font-size:12px;color:var(--text2);margin-top:4px;">Học viên</div>
          </div>
          <div style="padding:16px;background:#fef9c3;border-radius:10px;">
            <div style="font-size:28px;font-weight:800;color:#92400e;"><%= allHomeworks.size() %></div>
            <div style="font-size:12px;color:var(--text2);margin-top:4px;">Bài tập đã nhận</div>
          </div>
        </div>
      </div>
    </div>
    <% } %>

  </div><!-- end .content-main -->

  <!-- SIDEBAR -->
  <div class="content-side">
    <div class="side-card">
      <div class="side-thumb">
        <% if (courseThumbnail != null) { %>
        <img src="<%= courseThumbnail %>" alt="<%= course.getName() %>" onerror="this.parentElement.innerHTML='<div class=&quot;side-thumb-empty&quot;>🎓</div>'"/>
        <% } else { %>
        <div class="side-thumb-empty">🎓</div>
        <% } %>
      </div>
      <div class="side-body">
        <div style="font-size:16px;font-weight:800;margin-bottom:12px;"><%= course.getName() %></div>
        <div class="side-stat"><span class="side-stat-ico">🎬</span> <span><%= videos.size() %> bài học</span></div>
        <div class="side-stat"><span class="side-stat-ico">👥</span> <span><%= enrollCount %> học viên</span></div>
        <div class="side-stat"><span class="side-stat-ico">📂</span> <span><%= course.getCategory() %></span></div>
        <% if (currentVideo != null) { %>
        <div class="side-stat" style="color:var(--green);font-weight:600;"><span class="side-stat-ico">▶</span>
          <span>Đang xem: <%= currentVideo.getTitle().length()>30 ? currentVideo.getTitle().substring(0,30)+"..." : currentVideo.getTitle() %></span>
        </div>
        <% } %>
        <% if (enrolled) { %>
        <div class="side-btn enrolled" style="cursor:default;">✅ Đã đăng ký</div>
        <% } else if (!isStaff) { %>
        <a href="<%= request.getContextPath() %>/enroll?courseId=<%= courseId %>" class="side-btn">▶ Đăng ký học miễn phí</a>
        <% } %>
        <a href="<%= request.getContextPath() %>/dashboard" class="side-btn" style="background:var(--surface2);color:var(--text);margin-top:8px;">← Quay lại Dashboard</a>
      </div>
    </div>
  </div>
</div>

<!-- ══ CONTACT FOOTER ════════════════════════════════════════════════ -->
<footer class="cls-footer">
  <div class="cls-footer-inner">

    <!-- Brand + Socials -->
    <div class="cls-footer-brand">
      <div class="cls-footer-logo">
        <img src="<%= request.getContextPath() %>/logo/StudyFlow.png" alt="StudyFlow" onerror="this.style.display='none'"/>
        <span>StudyFlow</span>
      </div>
      <div class="cls-footer-tagline">StudyFlow Platform — Nền tảng học trực tuyến Java</div>
      <div class="cls-footer-desc">Hệ thống học trực tuyến miễn phí dành cho học viên, giảng viên và quản trị viên — tất cả trong một nền tảng duy nhất.</div>
      <div class="cls-footer-socials">
        <a href="https://facebook.com/StudyFlowPlatform" target="_blank" class="cls-footer-soc fb" title="Facebook">
          <svg viewBox="0 0 24 24"><path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z"/></svg>
        </a>
        <a href="https://youtube.com/@StudyFlowPlatform" target="_blank" class="cls-footer-soc yt" title="YouTube">
          <svg viewBox="0 0 24 24"><path d="M23.495 6.205a3.007 3.007 0 0 0-2.088-2.088c-1.87-.501-9.396-.501-9.396-.501s-7.507-.01-9.396.501A3.007 3.007 0 0 0 .527 6.205a31.247 31.247 0 0 0-.522 5.805 31.247 31.247 0 0 0 .522 5.783 3.007 3.007 0 0 0 2.088 2.088c1.868.502 9.396.502 9.396.502s7.506 0 9.396-.502a3.007 3.007 0 0 0 2.088-2.088 31.247 31.247 0 0 0 .5-5.783 31.247 31.247 0 0 0-.5-5.805zM9.609 15.601V8.408l6.264 3.602z"/></svg>
        </a>
        <a href="https://github.com/StudyFlowPlatform" target="_blank" class="cls-footer-soc gh" title="GitHub">
          <svg viewBox="0 0 24 24"><path d="M12 .297c-6.63 0-12 5.373-12 12 0 5.303 3.438 9.8 8.205 11.385.6.113.82-.258.82-.577 0-.285-.01-1.04-.015-2.04-3.338.724-4.042-1.61-4.042-1.61C4.422 18.07 3.633 17.7 3.633 17.7c-1.087-.744.084-.729.084-.729 1.205.084 1.838 1.236 1.838 1.236 1.07 1.835 2.809 1.305 3.495.998.108-.776.417-1.305.76-1.605-2.665-.3-5.466-1.332-5.466-5.93 0-1.31.465-2.38 1.235-3.22-.135-.303-.54-1.523.105-3.176 0 0 1.005-.322 3.3 1.23.96-.267 1.98-.399 3-.405 1.02.006 2.04.138 3 .405 2.28-1.552 3.285-1.23 3.285-1.23.645 1.653.24 2.873.12 3.176.765.84 1.23 1.91 1.23 3.22 0 4.61-2.805 5.625-5.475 5.92.42.36.81 1.096.81 2.22 0 1.606-.015 2.896-.015 3.286 0 .315.21.69.825.57C20.565 22.092 24 17.592 24 12.297c0-6.627-5.373-12-12-12"/></svg>
        </a>
      </div>
    </div>

    <!-- Contact -->
    <div class="cls-footer-contact">
      <div class="cls-footer-contact-title">Liên hệ &amp; Hỗ trợ</div>
      <div class="cls-footer-contact-list">
        <div class="cls-contact-row">
          <div class="cls-contact-ico">📞</div>
          <div>
            <div class="cls-contact-main">0912.345.678</div>
            <div class="cls-contact-sub">Thứ 2 – Thứ 6: 8:00 – 17:30</div>
          </div>
        </div>
        <div class="cls-contact-row">
          <div class="cls-contact-ico">✉️</div>
          <div>
            <div class="cls-contact-main">support@studyflow.edu.vn</div>
            <div class="cls-contact-sub">Phản hồi trong 24 giờ</div>
          </div>
        </div>
        <div class="cls-contact-row">
          <div class="cls-contact-ico">📍</div>
          <div>
            <div class="cls-contact-main">Số 1 Trường Thi, TP Vinh</div>
            <div class="cls-contact-sub">Nghệ An, Việt Nam</div>
          </div>
        </div>
        <div class="cls-contact-row">
          <div class="cls-contact-ico">💬</div>
          <div>
            <div class="cls-contact-main">Zalo / Discord</div>
            <div class="cls-contact-sub">@StudyFlowPlatform · 24/7</div>
          </div>
        </div>
      </div>
    </div>

    <!-- Quick Nav -->
    <div class="cls-footer-nav">
      <div class="cls-footer-nav-title">Khám phá</div>
      <ul>
        <li><a href="<%= request.getContextPath() %>/home"><span class="ft-dot"></span>Trang chủ</a></li>
        <li><a href="<%= request.getContextPath() %>/home"><span class="ft-dot"></span>Khóa học</a></li>
        <li><a href="<%= request.getContextPath() %>/dashboard"><span class="ft-dot"></span>Dashboard</a></li>
        <li><a href="<%= request.getContextPath() %>/dashboard?tab=contact"><span class="ft-dot"></span>Liên hệ</a></li>
        <li><a href="<%= request.getContextPath() %>/dashboard?tab=profile"><span class="ft-dot"></span>Hồ sơ</a></li>
      </ul>
    </div>

  </div>
  <div class="cls-footer-bottom">
    <span>© 2025 StudyFlow Platform. All rights reserved.</span>
    <div class="cls-footer-links">
      <a href="#">Chính sách bảo mật</a>
      <a href="#">Điều khoản sử dụng</a>
      <a href="<%= request.getContextPath() %>/dashboard?tab=contact">Liên hệ</a>
    </div>
    <div class="cls-footer-made">Made with <span>♥</span> tại Nghệ An</div>
  </div>
</footer>

<!-- MODAL: แก้ไขวิดีโอ -->
<div class="overlay" id="mEditVideo">
  <div class="modal" style="max-width:520px;">
    <div class="modal-head">
      <div class="modal-ico">✏️</div>
      <div class="modal-title">Sửa bài học</div>
    </div>
    <form method="post" action="<%= request.getContextPath() %>/classroom">
      <input type="hidden" name="courseId" value="<%= courseId %>"/>
      <input type="hidden" name="videoAction" value="editVideo"/>
      <input type="hidden" name="videoId" id="editVideoId"/>
      <div class="form-group">
        <label class="form-label">Tên bài học *</label>
        <input class="form-control" type="text" name="videoTitle" id="editVideoTitle" required/>
      </div>
      <div class="form-group">
        <label class="form-label">Mô tả</label>
        <input class="form-control" type="text" name="videoDesc" id="editVideoDesc"/>
      </div>
      <div class="form-group">
        <label class="form-label">URL Video *</label>
        <input class="form-control" type="url" name="videoUrl" id="editVideoUrl" required/>
      </div>
      <div class="modal-foot">
        <button type="button" class="btn btn-ghost" onclick="closeModal('mEditVideo')">Hủy</button>
        <button type="submit" class="btn btn-primary">💾 Lưu</button>
      </div>
    </form>
  </div>
</div>

<!-- MODAL: ลบวิดีโอ -->
<div id="mDeleteVideo" style="display:none;position:fixed;inset:0;z-index:9999;align-items:center;justify-content:center;">
  <div onclick="closeModal('mDeleteVideo')" style="position:absolute;inset:0;background:rgba(15,23,42,.4);backdrop-filter:blur(4px);"></div>
  <div style="position:relative;background:#fff;border-radius:20px;padding:36px 32px 28px;width:360px;max-width:90vw;box-shadow:0 24px 60px rgba(0,0,0,.18);animation:toastIn .22s ease;text-align:center;">
    <div style="font-size:50px;margin-bottom:12px;">🗑️</div>
    <div style="font-size:18px;font-weight:700;color:#1a2332;margin-bottom:8px;">Xác nhận xóa</div>
    <div style="font-size:14px;color:#64748b;margin-bottom:28px;line-height:1.6;">
      Bạn có chắc muốn xóa "<strong id="deleteVideoTitle"></strong>"?<br/>Hành động này không thể hoàn tác
    </div>
    <form method="post" action="<%= request.getContextPath() %>/classroom">
      <input type="hidden" name="courseId" value="<%= courseId %>"/>
      <input type="hidden" name="videoAction" value="deleteVideo"/>
      <input type="hidden" name="videoId" id="deleteVideoId"/>
      <div style="display:flex;gap:10px;">
        <button type="button" onclick="closeModal('mDeleteVideo')"
          style="flex:1;padding:11px 0;border-radius:10px;border:1.5px solid #e2e8f0;background:#f8fafc;color:#475569;font-size:14px;font-weight:600;cursor:pointer;"
          onmouseenter="this.style.background='#f1f5f9'" onmouseleave="this.style.background='#f8fafc'">
          Hủy
        </button>
        <button type="submit"
          style="flex:1;padding:11px 0;border-radius:10px;border:none;background:linear-gradient(135deg,#ef4444,#dc2626);color:#fff;font-size:14px;font-weight:700;cursor:pointer;transition:opacity .15s;"
          onmouseenter="this.style.opacity='.88'" onmouseleave="this.style.opacity='1'">
          🗑️ Xóa
        </button>
      </div>
    </form>
  </div>
</div>

<script src="<%= request.getContextPath() %>/js/classroom.js"></script>

<!-- MODAL: ตรวจการบ้าน -->
<div class="overlay" id="mReviewHw">
  <div class="modal" style="max-width:520px;">
    <div class="modal-head">
      <div class="modal-ico">📋</div>
      <div class="modal-title">Chấm bài tập &amp; Cho điểm</div>
    </div>
    <div class="review-hw-info">
      <div class="review-hw-name" id="reviewHwTitle">—</div>
      <div style="font-size:12px;color:var(--text3);margin-top:3px;">Học viên: <span id="reviewStudentName">—</span></div>
    </div>
    <form method="post" action="<%= request.getContextPath() %>/homework">
      <input type="hidden" name="action"   value="markReviewed"/>
      <input type="hidden" name="courseId" value="<%= courseId %>"/>
      <input type="hidden" name="hwId"     id="reviewHwId"/>

      <%-- ── ช่องคะแนน ── --%>
      <div class="form-group">
        <label class="form-label">🏅 Điểm <span style="font-weight:400;color:var(--text3);">(Không bắt buộc)</span></label>
        <div style="display:flex;align-items:center;gap:8px;">
          <input type="number" class="form-control" name="score" id="reviewScore"
                 min="0" max="100" placeholder="VD: 85"
                 style="width:90px;text-align:center;font-size:18px;font-weight:700;"
                 oninput="updateScoreBar()"/>
          <span style="font-size:16px;color:var(--text3);">/</span>
          <input type="number" class="form-control" name="maxScore" id="reviewMaxScore"
                 min="1" value="100"
                 style="width:75px;text-align:center;"
                 oninput="updateScoreBar()"/>
          <span style="font-size:13px;color:var(--text3);">điểm</span>
        </div>
        <div style="margin-top:8px;background:#f1f5f9;border-radius:99px;height:10px;overflow:hidden;">
          <div id="reviewScoreBar" style="height:100%;background:linear-gradient(90deg,#22c55e,#16a34a);border-radius:99px;width:0%;transition:width .3s;"></div>
        </div>
        <div id="reviewScoreLabel" style="font-size:12px;color:var(--text3);margin-top:3px;text-align:right;">—</div>
      </div>

      <%-- ── Feedback ── --%>
      <div class="form-group">
        <label class="form-label">💬 Feedback từ giáo viên <span style="font-weight:400;color:var(--text3);">(Không bắt buộc)</span></label>
        <textarea class="form-control" name="teacherComment" id="reviewComment" rows="3"
          placeholder="Ví dụ: Làm tốt lắm! / Cần sửa chỗ này... / Đã đạt yêu cầu ✓"></textarea>
      </div>

      <div class="modal-foot">
        <button type="button" class="btn btn-ghost" onclick="closeModal('mReviewHw')">Hủy</button>
        <button type="submit" class="btn btn-primary">✓ Đã chấm xong</button>
      </div>
    </form>
  </div>
</div>


<!-- Modal: Delete Homework -->
<div id="mDeleteHw" style="display:none;position:fixed;inset:0;z-index:9999;align-items:center;justify-content:center;">
  <div onclick="closeDeleteHw()" style="position:absolute;inset:0;background:rgba(15,23,42,.4);backdrop-filter:blur(4px);"></div>
  <div style="position:relative;background:#fff;border-radius:20px;padding:36px 32px 28px;width:360px;text-align:center;box-shadow:0 20px 60px rgba(0,0,0,.18);">
    <div style="font-size:50px;margin-bottom:12px;">🗑️</div>
    <div style="font-weight:700;font-size:18px;color:#1a2332;margin-bottom:8px;">Xác nhận xóa</div>
    <div id="mDeleteHw-text" style="font-size:14px;color:#64748b;margin-bottom:28px;">Bạn có chắc muốn xóa bài tập này?</div>
    <div style="display:flex;gap:12px;justify-content:center;">
      <button type="button" onclick="closeDeleteHw()"
        style="flex:1;max-width:130px;padding:11px 0;border-radius:12px;border:none;background:#f1f5f9;color:#475569;font-weight:600;font-size:14px;cursor:pointer;">Hủy</button>
      <button type="button" id="mDeleteHw-btn"
        style="flex:1;max-width:130px;padding:11px 0;border-radius:12px;border:none;background:linear-gradient(135deg,#ef4444,#dc2626);color:#fff;font-weight:600;font-size:14px;cursor:pointer;">Xóa</button>
    </div>
  </div>
</div>
<form id="fDeleteHw" method="post" action="<%= request.getContextPath() %>/homework" style="display:none;">
  <input type="hidden" name="action" value="deleteHomework"/>
  <input type="hidden" name="courseId" value="<%= courseId %>"/>
  <input type="hidden" id="fDeleteHw-id" name="hwId" value=""/>
</form>

<!-- Modal: Delete Review -->
<div id="mDeleteReview" style="display:none;position:fixed;inset:0;z-index:9999;align-items:center;justify-content:center;">
  <div onclick="closeDeleteReview()" style="position:absolute;inset:0;background:rgba(15,23,42,.4);backdrop-filter:blur(4px);"></div>
  <div style="position:relative;background:#fff;border-radius:20px;padding:36px 32px 28px;width:360px;text-align:center;box-shadow:0 20px 60px rgba(0,0,0,.18);">
    <div style="font-size:50px;margin-bottom:12px;">🗑️</div>
    <div style="font-weight:700;font-size:18px;color:#1a2332;margin-bottom:8px;">Xác nhận xóa</div>
    <div style="font-size:14px;color:#64748b;margin-bottom:28px;">Bạn có chắc muốn xóa đánh giá này?</div>
    <div style="display:flex;gap:12px;justify-content:center;">
      <button type="button" onclick="closeDeleteReview()"
        style="flex:1;max-width:130px;padding:11px 0;border-radius:12px;border:none;background:#f1f5f9;color:#475569;font-weight:600;font-size:14px;cursor:pointer;">Hủy</button>
      <button type="button" id="mDeleteReview-btn"
        style="flex:1;max-width:130px;padding:11px 0;border-radius:12px;border:none;background:linear-gradient(135deg,#ef4444,#dc2626);color:#fff;font-weight:600;font-size:14px;cursor:pointer;">Xóa</button>
    </div>
  </div>
</div>
<form id="fDeleteReview" method="post" action="<%= request.getContextPath() %>/teacher-review" style="display:none;">
  <input type="hidden" name="action" value="delete"/>
  <input type="hidden" name="courseId" value="<%= courseId %>"/>
  <input type="hidden" id="fDeleteReview-id" name="reviewId" value=""/>
</form>

</body>
</html>