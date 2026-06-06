<%@ page import="com.example.demo.entity.User, com.example.demo.dao.UserDAO, com.example.demo.dto.UserDTO, com.example.demo.dto.CourseDTO, com.example.demo.dto.VideoDTO, com.example.demo.dto.HomeworkDTO, com.example.demo.dto.DashboardDTO, com.example.demo.dto.TeacherReviewDTO, com.example.demo.service.UserService, com.example.demo.service.CourseService, com.example.demo.service.VideoService, com.example.demo.service.HomeworkService, com.example.demo.service.EnrollmentService, com.example.demo.service.DashboardService, java.util.*, java.text.SimpleDateFormat" %>
<%-- AdminManagement actions handled inline --%>
<%@ page contentType="text/html;charset=UTF-8" %>
<%
    org.springframework.web.context.WebApplicationContext _wac = org.springframework.web.context.support.WebApplicationContextUtils.getWebApplicationContext(application);
    DashboardService _dashSvc = _wac.getBean(DashboardService.class);
    UserService userSvc = _wac.getBean(UserService.class);
    UserDAO userDAO = _wac.getBean(UserDAO.class);
    CourseService _courseSvc = _wac.getBean(CourseService.class);
    VideoService _videoSvc = _wac.getBean(VideoService.class);
    HomeworkService _hwSvc = _wac.getBean(HomeworkService.class);
    EnrollmentService _enrollSvc = _wac.getBean(EnrollmentService.class);

    User user = (User) session.getAttribute("user");
    if (user == null) { response.sendRedirect("login"); return; }

    String role = user.getRole() != null ? user.getRole().toLowerCase() : "";

    // STUDENT ไม่มีสิทธิ์เข้า Dashboard → redirect ไปหน้าเว็บไซต์
    if ("student".equals(role)) {
        response.sendRedirect(request.getContextPath() + "/home");
        return;
    }

    // ── Handle Admin Management POST actions (SUPER_ADMIN only) ──────────
    String adminAction = request.getParameter("adminAction");
    String adminMsg    = null;
    String adminErr    = null;

    if (adminAction != null && role.equals("super_admin")) {
        String redirectUrl = request.getContextPath() + "/dashboard";

        if ("create".equals(adminAction)) {
            String uname  = request.getParameter("username");
            String pass   = request.getParameter("password");
            String fname  = request.getParameter("firstName");
            String lname  = request.getParameter("lastName");
            String email  = request.getParameter("email");
            String saRole = request.getParameter("saRole"); // "ADMIN" hoặc "SUPER_ADMIN"
            boolean valid = uname != null && !uname.trim().isEmpty()
                         && pass  != null && pass.length() >= 8
                         && fname != null && !fname.trim().isEmpty()
                         && lname != null && !lname.trim().isEmpty()
                         && email != null && !email.trim().isEmpty();
            if (!valid) {
                adminErr = "Vui lòng điền đầy đủ thông tin (mật khẩu tối thiểu 8 ký tự)";
            } else if (userDAO.usernameExists(uname.trim())) {
                adminErr = "Tên người dùng này đã tồn tại";
            } else if (userDAO.emailExists(email.trim())) {
                adminErr = "Email này đã được sử dụng";
            } else {
                boolean ok;
                if ("SUPER_ADMIN".equals(saRole)) {
                    ok = userDAO.createSuperAdmin(uname.trim(), pass, fname.trim(), lname.trim(), email.trim());
                } else {
                    ok = userDAO.registerFullUser(uname.trim(), pass, fname.trim(), lname.trim(), email.trim(), null, null, "ADMIN");
                }
                if (ok) adminMsg = ("SUPER_ADMIN".equals(saRole) ? "Tạo Super Admin" : "Tạo Admin") + " thành công!";
                else    adminErr = "Không thể tạo tài khoản";
            }

        } else {
            int targetId = 0;
            try { targetId = Integer.parseInt(request.getParameter("userId")); }
            catch (NumberFormatException e) { adminErr = "ID không hợp lệ"; }

            if (adminErr == null && targetId > 0) {
                if ("delete".equals(adminAction)) {
                    adminMsg = userDAO.deleteAdminById(targetId) ? "Xóa Admin thành công!" : null;
                    adminErr = adminMsg == null ? "Không thể xóa Admin" : null;
                } else if ("toggle".equals(adminAction)) {
                    adminMsg = userDAO.toggleUserStatus(targetId) ? "Cập nhật trạng thái thành công!" : null;
                    adminErr = adminMsg == null ? "Không thể thay đổi trạng thái" : null;
                } else if ("resetpw".equals(adminAction)) {
                    String newPw = request.getParameter("newPassword");
                    if (newPw == null || newPw.length() < 8) {
                        adminErr = "Mật khẩu mới phải có ít nhất 8 ký tự";
                    } else {
                        adminMsg = userDAO.changePassword(targetId, newPw) ? "Đặt lại mật khẩu thành công!" : null;
                        adminErr = adminMsg == null ? "Đặt lại mật khẩu thất bại" : null;
                    }
                }
            }
        }
        // PRG pattern: redirect after POST to avoid resubmit
        if (adminErr == null) {
            response.sendRedirect(redirectUrl + "?tab=admin&success=" + java.net.URLEncoder.encode(adminMsg != null ? adminMsg : "ok", "UTF-8"));
        } else {
            response.sendRedirect(redirectUrl + "?tab=admin&err=" + java.net.URLEncoder.encode(adminErr, "UTF-8"));
        }
        return;
    }

    // ── Handle User Management POST actions (ADMIN / SUPER_ADMIN only) ──
    String userAction = request.getParameter("userAction");
    String userMsg = null;
    String userErr = null;

    if (userAction != null && (role.equals("super_admin") || role.equals("admin"))) {
        if ("delete".equals(userAction)) {
            int targetId = 0;
            try { targetId = Integer.parseInt(request.getParameter("userId")); }
            catch (NumberFormatException e) { userErr = "ID không hợp lệ"; }

            if (userErr == null && targetId > 0) {
                boolean ok = userDAO.deleteUser(targetId);
                if (ok) userMsg = "Xóa người dùng thành công!";
                else    userErr = "Không thể xóa người dùng (có thể là Super Admin)";
            }
        }
        if (userErr == null) {
            response.sendRedirect(request.getContextPath() + "/dashboard?tab=users"
                + (userMsg != null ? "&success=" + java.net.URLEncoder.encode(userMsg, "UTF-8") : ""));
            return;
        }
    }

    String activeTab = request.getParameter("tab") != null ? request.getParameter("tab") : "dashboard";
    // Read ?err= param for admin tab (set when server redirects on error)
    if (adminErr == null && "admin".equals(activeTab)) {
        String _errParam = request.getParameter("err");
        if (_errParam != null && !_errParam.trim().isEmpty()) adminErr = _errParam;
    }
    String _rawSuccess = request.getParameter("success");
    // photoUpdated และ profileUpdated ใช้ toast แทน modal — ไม่ส่งเข้า successParam
    boolean _showPhotoToast   = "photoUpdated".equals(_rawSuccess) || "1".equals(request.getParameter("photoToast"));
    boolean _showProfileToast = "profileUpdated".equals(_rawSuccess);
    String successParam = (_rawSuccess != null && !_rawSuccess.equals("photoUpdated") && !_rawSuccess.equals("profileUpdated"))
                          ? _rawSuccess : null;

    DashboardDTO _dd = _dashSvc.getDashboardData();
    int totalStudents     = (int) _dd.getTotalStudents();
    int totalTeachers     = (int) _dd.getTotalTeachers();
    int totalCourses      = (int) _dd.getTotalCourses();
    int totalEnrollments  = (int) _dd.getTotalEnrollments();
    int newStudentsToday  = (int) _dd.getNewStudentsToday();
    int newCoursesMonth   = (int) _dd.getNewCoursesThisMonth();

    List<Map<String,Object>> monthly       = _dd.getMonthlyEnrollments();
    List<Map<String,Object>> topCourses    = _dd.getTopCourses();
    List<Map<String,Object>> recentEnroll  = _dd.getRecentEnrollments();
    List<Map<String,Object>> detailedStats = _dd.getMonthlyDetailedStats();
    // BUG FIX: โหลด homework submissions ล่าสุดสำหรับแสดงในหน้า approval
    List<Map<String,Object>> recentHwSubs  = _dd.getRecentHomeworkSubmissions() != null
        ? _dd.getRecentHomeworkSubmissions() : new java.util.ArrayList<>();

    // Chart labels & data
    StringBuilder cLabels = new StringBuilder();
    StringBuilder cData   = new StringBuilder();
    for (int i = 0; i < monthly.size(); i++) {
        if (i > 0) { cLabels.append(","); cData.append(","); }
        Object _mVal = monthly.get(i).get("month");
        String _mStr = (_mVal != null) ? _mVal.toString().replace("\\","\\\\").replace("\"","\\\"") : "";
        cLabels.append("\"").append(_mStr).append("\"");
        cData.append(monthly.get(i).get("total"));
    }
    if (monthly.isEmpty()) {
        cLabels = new StringBuilder("\"Th1\",\"Th2\",\"Th3\",\"Th4\",\"Th5\",\"Th6\"");
        cData   = new StringBuilder("0,0,0,0,0,0");
    }

    // Top courses for donut chart
    StringBuilder dLabels = new StringBuilder();
    StringBuilder dData   = new StringBuilder();
    for (int i = 0; i < topCourses.size(); i++) {
        if (i > 0) { dLabels.append(","); dData.append(","); }
        Object _nVal = topCourses.get(i).get("name");
        String _nStr = (_nVal != null) ? _nVal.toString().replace("\\","\\\\").replace("\"","\\\"") : "";
        if (_nStr.length() > 18) _nStr = _nStr.substring(0,18) + "…";
        dLabels.append("\"").append(_nStr).append("\"");
        dData.append(topCourses.get(i).get("total"));
    }
    if (topCourses.isEmpty()) { dLabels = new StringBuilder("\"Không có dữ liệu\""); dData = new StringBuilder("1"); }

    // Build JS arrays for charts from detailedStats (moved to top for DashboardConfig)
    StringBuilder jsMonths = new StringBuilder();
    StringBuilder jsEnroll = new StringBuilder();
    StringBuilder jsStudents = new StringBuilder();
    StringBuilder jsTeachers = new StringBuilder();
    for (int i = 0; i < detailedStats.size(); i++) {
        Map<String,Object> dsRow = detailedStats.get(i);
        if (i > 0) { jsMonths.append(","); jsEnroll.append(","); jsStudents.append(","); jsTeachers.append(","); }
        Object _mlVal = dsRow.get("month_label");
        String _mlStr = (_mlVal != null) ? _mlVal.toString().replace("\\","\\\\").replace("\"","\\\"") : "";
        jsMonths.append("\"").append(_mlStr).append("\"");
        jsEnroll.append(dsRow.get("enrollments") != null ? dsRow.get("enrollments") : 0);
        jsStudents.append(dsRow.get("new_students") != null ? dsRow.get("new_students") : 0);
        jsTeachers.append(dsRow.get("new_teachers") != null ? dsRow.get("new_teachers") : 0);
    }
    if (detailedStats.isEmpty()) {
        jsMonths = new StringBuilder("\"T1\",\"T2\",\"T3\",\"T4\",\"T5\",\"T6\"");
        jsEnroll = new StringBuilder("0,0,0,0,0,0");
        jsStudents = new StringBuilder("0,0,0,0,0,0");
        jsTeachers = new StringBuilder("0,0,0,0,0,0");
    }

    // Tải danh sách user và admins chỉ cho super_admin
    List<UserDTO> allUsers = new ArrayList<UserDTO>();
    List<UserDTO> adminList = new ArrayList<UserDTO>();
    List<UserDTO> superAdminList = new ArrayList<UserDTO>();
    List<UserDTO> studentList = new ArrayList<UserDTO>();
    List<UserDTO> teacherList = new ArrayList<UserDTO>();
    List<UserDTO> pendingTeachers = new ArrayList<UserDTO>();  // Giáo viên chờ phê duyệt
    if (role.equals("super_admin") || role.equals("admin")) {
        studentList     = userSvc.getUsersByRole("STUDENT");
        teacherList     = userSvc.getUsersByRole("TEACHER");
        pendingTeachers = userSvc.getPendingTeachers();
    }
    if (role.equals("super_admin")) {
        allUsers       = userSvc.getAllUsers();
        adminList      = userSvc.getUsersByRole("ADMIN");
        superAdminList = userSvc.getUsersByRole("SUPER_ADMIN");
    }
    int pendingCount = pendingTeachers.size();

    // ── Tải dữ liệu khóa học ────────────────────────────
    // CourseService available as _courseSvc
    // VideoService available as _videoSvc
    // EnrollmentService available as _enrollSvc

    // FIX: แยก 2 list
    // allCourseList  → tab "Khóa học" (courses): ทุก role เห็นทุกคอร์ส
    // courseList     → tab "Quản lý" (manage-courses): teacher เห็นแค่คอร์สตัวเอง
    java.util.List<CourseDTO> allCourseList = _courseSvc.getAllCourses();
    java.util.List<CourseDTO> courseList = new java.util.ArrayList<CourseDTO>();
    if (role.equals("teacher")) {
        courseList = _courseSvc.getCoursesByTeacher(user.getId());
    } else {
        courseList = allCourseList;
    }

    // Khóa học người dùng đã đăng ký
    java.util.List<Integer> enrolledIds = _enrollSvc.getEnrolledCourseIds(user.getId());

    int openCourseId = 0;
    try { openCourseId = Integer.parseInt(request.getParameter("openCourse")); } catch (Exception ignore) {}

    String courseSuccess = null;
    String courseErr = null;
    String _sp = request.getParameter("success");
    String _ep = request.getParameter("err");
    if (activeTab.equals("manage-courses")) {
        if (_sp != null) {
            if ("courseAdded".equals(_sp))        courseSuccess = "Thêm khóa học thành công!";
            else if ("courseUpdated".equals(_sp)) courseSuccess = "Chỉnh sửa khóa học thành công!";
            else if ("courseDeleted".equals(_sp)) courseSuccess = "Xóa khóa học thành công!";
            else if ("videoUploaded".equals(_sp)) courseSuccess = "Tải video lên thành công!";
            else if ("videoUpdated".equals(_sp))  courseSuccess = "Chỉnh sửa video thành công!";
            else if ("videoDeleted".equals(_sp))  courseSuccess = "Xóa video thành công!";
            else if ("hwUploaded".equals(_sp))    courseSuccess = "Tải lên tệp bài tập thành công!";
            else if ("hwEdited".equals(_sp))      courseSuccess = "Sửa tệp bài tập thành công ✓";
            else if ("hwDeleted".equals(_sp))     courseSuccess = "Xóa tệp bài tập thành công";
        }
        if (_ep != null) {
            if ("nameRequired".equals(_ep))        courseErr = "Vui lòng nhập tên khóa học";
            else if ("addFailed".equals(_ep))      courseErr = "Không thể thêm khóa học";
            else if ("updateFailed".equals(_ep))   courseErr = "Không thể chỉnh sửa khóa học";
            else if ("deleteFailed".equals(_ep))   courseErr = "Không thể xóa khóa học";
            else if ("videoFailed".equals(_ep))    courseErr = "Tải video lên thất bại";
            else if ("noVideoSource".equals(_ep))  courseErr = "Vui lòng chọn file hoặc nhập URL video";
            else if ("hwInvalidData".equals(_ep))  courseErr = "Dữ liệu bài tập không hợp lệ";
            else if ("hwEditFailed".equals(_ep))   courseErr = "Sửa bài tập thất bại, vui lòng thử lại";
            else if ("hwDeleteFailed".equals(_ep)) courseErr = "Xóa bài tập thất bại, vui lòng thử lại";
            else if ("noPermission".equals(_ep))   courseErr = "Bạn không có quyền quản lý thông tin trong phần này";
            else if ("invalidUser".equals(_ep))    courseErr = "Phiên người dùng không hợp lệ, vui lòng đăng nhập lại";
            else courseErr = "Đã xảy ra lỗi, vui lòng thử lại";
        }
    }
    int totalAdmins       = adminList.size();
    int totalSuperAdmins  = superAdminList.size();
    long totalActiveAdmins = 0;
    for (UserDTO _au : adminList) { if ("ACTIVE".equalsIgnoreCase(_au.getStatus())) totalActiveAdmins++; }

    // ── Teacher Notifications: số bài nộp từ học sinh ────────────────────
    // BUG FIX: ดึง pendingHw จาก native query แทนการ loop ใน memory
    //          เพื่อให้นับครบทุกคอร์สที่ครูสอนและไม่พลาด student ที่ส่งงาน
    int teacherPendingHw = 0;
    int teacherNewEnrolls = 0;
    java.util.List<HomeworkDTO> teacherHwNotifs = new java.util.ArrayList<HomeworkDTO>();
    if (role.equals("teacher")) {
        for (CourseDTO _tc : courseList) {
            java.util.List<HomeworkDTO> _tcHws = _hwSvc.getStudentsByCourse(_tc.getId(), user.getId());
            teacherHwNotifs.addAll(_tcHws);
        }
        com.example.demo.repository.HomeworkRepository _hwRepo =
            _wac.getBean(com.example.demo.repository.HomeworkRepository.class);
        teacherPendingHw = (int) _hwRepo.countAllPendingHomeworkForTeacher(user.getId());
        teacherNewEnrolls = (int) _hwSvc.countRecentEnrollmentsByTeacher(user.getId());
    }
    // BADGE RESET: บันทึก lastSeen ลง session เมื่อเปิดหน้า notifications
    // badge จะนับเฉพาะ submission ที่มาหลัง lastSeen
    String _notifSessionKey = "notifLastSeen_" + (user != null ? user.getId() : "0");
    java.time.LocalDateTime _notifLastSeen = null;
    Object _nlsObj = session.getAttribute(_notifSessionKey);
    if (_nlsObj instanceof java.time.LocalDateTime) {
        _notifLastSeen = (java.time.LocalDateTime) _nlsObj;
        // DAILY RESET: ถ้า lastSeen เกิน 1 วัน → ถือว่า "ยังไม่เคยดู" ใหม่อีกครั้ง
        if (_notifLastSeen.isBefore(java.time.LocalDateTime.now().minusDays(1))) {
            _notifLastSeen = null;
            session.removeAttribute(_notifSessionKey);
        }
    }
    if (_notifLastSeen == null) {
        // ครั้งแรก (หรือ daily reset) → initialize lastSeen = ตอนนี้, badge = 0
        session.setAttribute(_notifSessionKey, java.time.LocalDateTime.now());
        _notifLastSeen = java.time.LocalDateTime.now();
    }
    if (activeTab.equals("notifications")) {
        session.setAttribute(_notifSessionKey, java.time.LocalDateTime.now());
        _notifLastSeen = java.time.LocalDateTime.now();
    }
    // คำนวณ badge: นับเฉพาะ item ที่เกิดขึ้นหลัง lastSeen เท่านั้น
    int _teacherNewBadge = 0;
    if (!activeTab.equals("notifications")) {
        // เคยเปิดดูแล้ว → นับเฉพาะที่ submit/enroll หลัง lastSeen
        final java.time.LocalDateTime _lsRef = _notifLastSeen;
        // นับ homework submissions หลัง lastSeen
        for (HomeworkDTO _bh : teacherHwNotifs) {
            if (_bh.getSubmittedAt() != null && !_bh.getSubmittedAt().isEmpty()) {
                try {
                    String _bRaw = _bh.getSubmittedAt().replace(" ","T");
                    java.time.LocalDateTime _bLdt = java.time.LocalDateTime.parse(
                        _bRaw.length() >= 19 ? _bRaw.substring(0,19) : _bRaw,
                        java.time.format.DateTimeFormatter.ISO_LOCAL_DATE_TIME);
                    if (_bLdt.isAfter(_lsRef)) _teacherNewBadge++;
                } catch (Exception _ignore) {}
            }
        }
        // นับ enrollments ใหม่หลัง lastSeen (นักเรียนลงทะเบียนกับครูคนนี้)
        try {
            com.example.demo.repository.EnrollmentRepository _eRepoB =
                _wac.getBean(com.example.demo.repository.EnrollmentRepository.class);
            for (Object[] _er : _eRepoB.findRecentEnrollmentsForTeacher(user.getId(), 7)) {
                Object _erDate = _er[2];
                java.time.LocalDateTime _erLdt = null;
                if (_erDate instanceof java.sql.Timestamp)
                    _erLdt = ((java.sql.Timestamp)_erDate).toLocalDateTime();
                else if (_erDate instanceof java.time.LocalDateTime)
                    _erLdt = (java.time.LocalDateTime)_erDate;
                else if (_erDate != null) {
                    try {
                        String _erRaw = _erDate.toString().replace(" ","T");
                        _erLdt = java.time.LocalDateTime.parse(
                            _erRaw.length() >= 19 ? _erRaw.substring(0,19) : _erRaw,
                            java.time.format.DateTimeFormatter.ISO_LOCAL_DATE_TIME);
                    } catch (Exception _ign2) {}
                }
                if (_erLdt != null && _erLdt.isAfter(_lsRef)) _teacherNewBadge++;
            }
        } catch (Exception _ignE) {}
    }
    // ถ้า activeTab == notifications → badge = 0 (กำลังดูอยู่)
    int teacherTotalNotif = _teacherNewBadge;

    // BADGE RESET admin: นับ pendingTeachers + คอร์สใหม่ใน 7 วัน
    // เมื่อเปิดหน้า approval → badge = 0 จนกว่าจะมีคอร์สใหม่หลัง lastSeen
    int _adminTotalNotif = 0;
    if (role.equals("admin") || role.equals("super_admin")) {
        com.example.demo.repository.CourseRepository _courseRepoSidebar =
            _wac.getBean(com.example.demo.repository.CourseRepository.class);
        // Session-based badge reset
        String _adminNotifKey = "adminNotifLastSeen_" + (user != null ? user.getId() : "0");
        java.time.LocalDateTime _adminLastSeen = null;
        Object _alsObj = session.getAttribute(_adminNotifKey);
        if (_alsObj instanceof java.time.LocalDateTime) {
            _adminLastSeen = (java.time.LocalDateTime) _alsObj;
            // DAILY RESET: ถ้า lastSeen เกิน 1 วัน → ถือว่า "ยังไม่เคยดู" ใหม่อีกครั้ง
            if (_adminLastSeen.isBefore(java.time.LocalDateTime.now().minusDays(1))) {
                _adminLastSeen = null;
                session.removeAttribute(_adminNotifKey);
            }
        }
        if (activeTab.equals("approval")) {
            session.setAttribute(_adminNotifKey, java.time.LocalDateTime.now());
            _adminLastSeen = java.time.LocalDateTime.now();
        }
        int _newCoursesWeek = (int) _courseRepoSidebar.countNewCoursesInDays(7);
        if (_adminLastSeen == null) {
            // ครั้งแรก (หรือ daily reset) → initialize lastSeen = ตอนนี้, badge = 0
            session.setAttribute(_adminNotifKey, java.time.LocalDateTime.now());
            _adminLastSeen = java.time.LocalDateTime.now();
        }
        if (!activeTab.equals("approval")) {
            // เคยเปิดแล้ว → นับเฉพาะ pending teachers (urgent เสมอ) + คอร์สหลัง lastSeen
            final java.time.LocalDateTime _alsRef = _adminLastSeen;
            long _newCoursesAfterSeen = 0;
            try {
                // นับคอร์สที่สร้างหลัง lastSeen
                java.util.List<Object[]> _allCrs = _courseRepoSidebar.findRecentCoursesWithTeacher(50);
                for (Object[] _crs : _allCrs) {
                    Object _crsDate = _crs[3];
                    java.time.LocalDateTime _crsLdt = null;
                    if (_crsDate instanceof java.sql.Timestamp)
                        _crsLdt = ((java.sql.Timestamp)_crsDate).toLocalDateTime();
                    else if (_crsDate instanceof java.time.LocalDateTime)
                        _crsLdt = (java.time.LocalDateTime)_crsDate;
                    if (_crsLdt != null && _crsLdt.isAfter(_alsRef)) _newCoursesAfterSeen++;
                }
            } catch (Exception _ign) {}
            _adminTotalNotif = pendingCount + (int)_newCoursesAfterSeen;
        }
        // ถ้า activeTab == approval → badge = pendingCount เท่านั้น (กำลังดูอยู่)
        if (activeTab.equals("approval")) {
            _adminTotalNotif = pendingCount;
        }
    }
%>
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8"/>
<meta name="viewport" content="width=device-width,initial-scale=1"/>
<title>Dashboard – Hệ thống học trực tuyến</title>

<link rel="stylesheet" href="css/dashboard.css?v=4">
<script>
  window.DashboardConfig = {
    contextPath: '<%= request.getContextPath() %>',
    studentCount: <%= totalStudents %>,
    teacherCount: <%= totalTeachers %>,
    adminCount: <%= totalAdmins %>,
    cLabels: [<%= cLabels.toString().replace("\n", " ").replace("\r", "") %>],
    cData: [<%= cData.toString() %>],
    dLabels: [<%= dLabels.toString().replace("\n", " ").replace("\r", "") %>],
    dData: [<%= dData.toString() %>],
    jsMonths: [<%= jsMonths.toString().replace("\n", " ").replace("\r", "") %>],
    jsEnroll: [<%= jsEnroll.toString() %>],
    jsStudents: [<%= jsStudents.toString() %>],
    jsTeachers: [<%= jsTeachers.toString() %>],
    courseVideos: {
      <% for (CourseDTO _cx : courseList) {
           java.util.List<VideoDTO> _vx = _videoSvc.getVideosByCourse(_cx.getId());
      %>
      <%= _cx.getId() %>: [
        <% for (int _vi=0; _vi < _vx.size(); _vi++) {
             VideoDTO _v = _vx.get(_vi);
             String _vUrl2 = _v.getFilePath() != null ? _v.getFilePath() : "";
             String _vTitle = _v.getTitle() != null ? _v.getTitle().replace("\\","\\\\").replace("'","\\'").replace("\n"," ") : "";
             String _vDesc = _v.getDescription() != null ? _v.getDescription().replace("\\","\\\\").replace("'","\\'").replace("\n"," ") : "";
        %>
        {id:<%= _v.getId() %>, title:'<%= _vTitle %>', desc:'<%= _vDesc %>', url:'<%= _vUrl2.replace("\\","\\\\").replace("'","\\'") %>', order:<%= _v.getOrderNo() %>}<%= _vi < _vx.size()-1 ? "," : "" %>
        <% } %>
      ],
      <% } %>
    },
    courseHomeworks: {
      <% for (CourseDTO _cx2 : courseList) {
              java.util.List<HomeworkDTO> _hws = _hwSvc.getTeacherFiles(_cx2.getId(), _cx2.getTeacherId());
      %>
      <%= _cx2.getId() %>: [
        <% for (int _hi=0; _hi < _hws.size(); _hi++) {
                HomeworkDTO _h = _hws.get(_hi);
                String _hFile = _h.getFileName() != null ? _h.getFileName().replace("\\","\\\\").replace("'","\\'").replace("\n"," ") : "";
                String _hPath = _h.getFilePath() != null ? _h.getFilePath().replace("\\","\\\\").replace("'","\\'").replace("\n"," ") : "";
                String _hTitle = _h.getTitle() != null ? _h.getTitle().replace("\\","\\\\").replace("'","\\'").replace("\n"," ") : "";
                String _hDate = _h.getSubmittedAt() != null && _h.getSubmittedAt().length() >= 10 ? _h.getSubmittedAt().substring(0,10) : "";
        %>
        {id:<%= _h.getId() %>, title:'<%= _hTitle %>', file:'<%= _hFile %>', path:'<%= request.getContextPath() %>/<%= _hPath %>', date:'<%= _hDate %>'}<%= _hi < _hws.size()-1 ? "," : "" %>
        <% } %>
      ],
      <% } %>
    }  };
</script>
<!-- ── CHART.JS & DASHBOARD JS ── loaded AFTER DashboardConfig ── -->
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.min.js"></script>
<script src="<%= request.getContextPath() %>/js/dashboard.js"></script>
</head>
<body>

<!-- SIDEBAR -->
<div class="sidebar">
  <div class="sb-brand">
    <div class="sb-logo">
      <img src="<%= request.getContextPath() %>/logo/StudyFlow.png" alt="StudyFlow Logo" style="height: 32px; width: auto; vertical-align: middle;">
    </div>
    <div>
      <div class="sb-title">StudyFlow</div>
      <div class="sb-sub">Hệ thống học trực tuyến</div>
    </div>
  </div>

  <div class="sb-user">
    <%
      String _sbPhoto = user.getProfilePhoto();
      String _sbPhotoUrl = (_sbPhoto != null && !_sbPhoto.trim().isEmpty())
          ? request.getContextPath() + "/uploads/" + _sbPhoto : null;
      String _sbInit = "";
      if (user.getFirstName() != null && !user.getFirstName().isEmpty()) _sbInit += user.getFirstName().charAt(0);
      if (user.getLastName()  != null && !user.getLastName().isEmpty())  _sbInit += user.getLastName().charAt(0);
      if (_sbInit.isEmpty()) _sbInit = user.getUsername().substring(0,1).toUpperCase();
    %>
    <% if (_sbPhotoUrl != null) { %>
    <img src="<%= _sbPhotoUrl %>" alt="Avatar"
         class="sb-avatar" style="object-fit:cover;cursor:pointer;"
         onclick="location.href='dashboard?tab=profile'" title="Xem hồ sơ">
    <% } else { %>
    <div class="sb-avatar"><%= _sbInit.toUpperCase() %></div>
    <% } %>
    <div>
      <div class="sb-uname"><%= user.getUsername() %></div>
      <div class="sb-urole"><%= user.getRole() %></div>
    </div>
  </div>

  <div class="menu-sec">
    <div class="menu-label">Menu chính</div>
    <a href="dashboard" class="<%= activeTab.equals("dashboard") ? "active" : "" %>"><span class="ico">🏠</span>Trang chủ</a>

    <div class="menu-label">Khóa học</div>
    <a href="dashboard?tab=courses" class="<%= "courses".equals(activeTab) ? "active" : "" %>"><span class="ico">🎓</span>Tất cả khóa học</a>
    <% if (role.equals("teacher") || role.equals("admin") || role.equals("super_admin")) { %>
      <div class="menu-label">Quản lý khóa học</div>
      <a href="dashboard?tab=manage-courses" class="<%= "manage-courses".equals(activeTab) ? "active" : "" %>"><span class="ico">📚️</span>Quản lý khóa học</a>
    <% } %>

    <% if (role.equals("teacher")) { %>
      <div class="menu-label">Thông báo</div>
      <a href="dashboard?tab=notifications" class="<%= activeTab.equals("notifications") ? "active" : "" %>" style="position:relative;">
        <span class="ico">🔔</span>Thông báo
        <% if (teacherTotalNotif > 0) { %>
          <span style="position:absolute;right:14px;top:50%;transform:translateY(-50%);background:#ef4444;color:#fff;font-size:11px;font-weight:700;border-radius:999px;padding:1px 7px;min-width:20px;text-align:center;"><%= teacherTotalNotif %></span>
        <% } %>
      </a>
    <% } %>
    <% if (role.equals("admin") || role.equals("super_admin")) { %>
      <div class="menu-label">Quản lý hệ thống</div>
      <a href="dashboard?tab=users" class="<%= activeTab.equals("users") ? "active" : "" %>"><span class="ico">👥</span>Quản lý người dùng</a>
      <a href="dashboard?tab=approval" class="<%= activeTab.equals("approval") ? "active" : "" %>" style="position:relative;">
        <span class="ico">🔔</span>Thông báo
        <% if (_adminTotalNotif > 0) { %>
          <span style="position:absolute;right:14px;top:50%;transform:translateY(-50%);background:#ef4444;color:#fff;font-size:11px;font-weight:700;border-radius:999px;padding:1px 7px;min-width:20px;text-align:center;"><%= _adminTotalNotif > 99 ? "99+" : _adminTotalNotif %></span>
        <% } %>
      </a>
      <a href="dashboard?tab=stats" class="<%= activeTab.equals("stats") ? "active" : "" %>"><span class="ico">📊</span>Báo cáo thống kê</a>
    <% } %>
    <% if (role.equals("teacher") || role.equals("admin")) { %>
      <div class="menu-label">Tài khoản</div>
      <a href="dashboard?tab=security" class="<%= activeTab.equals("security") ? "active" : "" %>"><span class="ico">🔐</span>Bảo mật</a>
    <% } %>
    <% if (role.equals("super_admin")) { %>
      <div class="menu-label">Super Admin</div>
      <a href="dashboard?tab=admin" class="<%= activeTab.equals("admin") ? "active" : "" %>"><span class="ico">👑</span>Quản lý Admin</a>
      <a href="dashboard?tab=security" class="<%= activeTab.equals("security") ? "active" : "" %>"><span class="ico">🔐</span>Bảo mật</a>
    <% } %>
  </div>

  <div class="sb-footer">
    <a href="dashboard?tab=profile" class="<%= activeTab.equals("profile") ? "active" : "" %>" style="margin-bottom:4px;"><span>👤</span>Thông tin cá nhân</a>
    <a href="dashboard?tab=contact" class="<%= activeTab.equals("contact") ? "active" : "" %>" style="margin-bottom:4px;"><span>📞</span>Liên hệ</a>
    <a href="logout?redirectTo=register" style="background:rgba(99,102,241,.12);color:#818cf8;margin-bottom:6px;"><span>➕</span>Đăng ký tài khoản mới</a>
    <a href="logout"><span>🚪</span>Đăng xuất</a>
  </div>
</div>

<!-- MAIN -->
<div class="main-wrap">
  <div class="topbar">
    <div class="topbar-left">
    <span class="tb-title"><%= activeTab.equals("admin") ? "Quản lý Admin" : activeTab.equals("users") ? "Quản lý người dùng" : activeTab.equals("approval") ? "Thông báo" : activeTab.equals("courses") ? "Khóa học" : activeTab.equals("manage-courses") ? "Quản lý khóa học" : activeTab.equals("profile") ? "Thông tin cá nhân" : activeTab.equals("stats") ? "Báo cáo thống kê" : activeTab.equals("security") ? "Bảo mật" : activeTab.equals("contact") ? "Liên hệ" : activeTab.equals("notifications") ? "Thông báo" : "Dashboard" %></span>
      <span class="tb-bread">/ <%= activeTab.equals("admin") ? "Super Admin" : activeTab.equals("users") ? "Tất cả người dùng" : activeTab.equals("approval") ? "Trung tâm thông báo" : activeTab.equals("courses") ? "Tất cả khóa học" : activeTab.equals("manage-courses") ? "Tất cả khóa học" : activeTab.equals("profile") ? "Hồ sơ" : activeTab.equals("stats") ? "Báo cáo" : activeTab.equals("security") ? "Cài đặt bảo mật" : activeTab.equals("contact") ? "Hỗ trợ" : activeTab.equals("notifications") ? "Bài nộp của học sinh" : "Trang chủ" %></span>
    </div>
    <div class="topbar-right">
      <span class="tb-date" id="nowDate"></span>
    </div>
  </div>

  <div class="content">

    <% if (!activeTab.equals("admin") && !activeTab.equals("users") && !activeTab.equals("approval") && !activeTab.equals("courses") && !activeTab.equals("manage-courses") && !activeTab.equals("profile") && !activeTab.equals("stats") && !activeTab.equals("security") && !activeTab.equals("contact") && !activeTab.equals("notifications")) { /* ══ TAB: DASHBOARD ════════════════════════════ */ %>

    <!-- PAGE HEADER -->
    <div class="page-hdr">
      <h2>Chào mừng, <%= user.getUsername() %> 👋</h2>
      <p>Tổng quan hệ thống học trực tuyến — dữ liệu cập nhật real-time từ cơ sở dữ liệu</p>
    </div>

    <!-- ROLE BANNER -->
    <% if (role.equals("student")) { %>
    <div class="role-banner">
      <div class="rb-icon">🎓</div>
      <div><div class="rb-title">Chế độ học sinh</div><div class="rb-sub">Xem khóa học đã đăng ký và tiếp tục học ngay</div></div>
    </div>
    <% } else if (role.equals("teacher")) { %>
    <div class="role-banner" style="background:linear-gradient(135deg,#065f46,#047857);">
      <div class="rb-icon">👨‍🏫</div>
      <div><div class="rb-title">Chế độ giáo viên</div><div class="rb-sub">Quản lý khóa học và xem thống kê học sinh</div></div>
    </div>
    <% } else if (role.equals("super_admin")) { %>
    <div class="role-banner" style="background:linear-gradient(135deg,#b45309,#92400e);">
      <div class="rb-icon">👑</div>
      <div><div class="rb-title">Chế độ Super Admin</div><div class="rb-sub">Kiểm soát hệ thống tối cao — quản lý tất cả mọi thứ</div></div>
    </div>
    <% } else { %>
    <div class="role-banner" style="background:linear-gradient(135deg,#7c3aed,#5b21b6);">
      <div class="rb-icon">🛡️</div>
      <div><div class="rb-title">Chế độ quản trị viên</div><div class="rb-sub">Kiểm soát và xem tổng quan toàn bộ hệ thống</div></div>
    </div>
    <% } %>

    <!-- STAT CARDS — Personalized by role -->
    <div class="stat-grid">
    <% if (role.equals("teacher")) { %>
      <div class="stat-card sc-t1">
        <div class="sc-icon sc-i1">📚</div>
        <div>
          <div class="sc-val"><%= courseList.size() %></div>
          <div class="sc-lbl">Khóa học của tôi</div>
          <div class="sc-sub">+<%= newCoursesMonth %> tháng này</div>
        </div>
      </div>
      <div class="stat-card sc-t2">
        <div class="sc-icon sc-i2">👨‍🎓</div>
        <div>
          <div class="sc-val"><%= totalStudents %></div>
          <div class="sc-lbl">Tổng học sinh</div>
          <div class="sc-sub">Trong hệ thống</div>
        </div>
      </div>
      <div class="stat-card sc-t3">
        <div class="sc-icon sc-i3">📝</div>
        <div>
          <div class="sc-val"><%= teacherPendingHw %></div>
          <div class="sc-lbl">Bài nộp chờ xem</div>
          <div class="sc-sub">Từ học sinh</div>
        </div>
      </div>
      <div class="stat-card sc-t4">
        <div class="sc-icon sc-i4">📊</div>
        <div>
          <div class="sc-val"><%= totalEnrollments %></div>
          <div class="sc-lbl">Lượt đăng ký</div>
          <div class="sc-sub">Tất cả các khóa</div>
        </div>
      </div>
    <% } else { /* admin / super_admin */ %>
      <div class="stat-card sc-t1">
        <div class="sc-icon sc-i1">👨‍🎓</div>
        <div>
          <div class="sc-val"><%= totalStudents %></div>
          <div class="sc-lbl">Tổng học sinh</div>
          <div class="sc-sub">+<%= newStudentsToday %> hôm nay</div>
        </div>
      </div>
      <div class="stat-card sc-t2">
        <div class="sc-icon sc-i2">📚</div>
        <div>
          <div class="sc-val"><%= totalCourses %></div>
          <div class="sc-lbl">Tổng khóa học</div>
          <div class="sc-sub">+<%= newCoursesMonth %> tháng này</div>
        </div>
      </div>
      <div class="stat-card sc-t3">
        <div class="sc-icon sc-i3">📝</div>
        <div>
          <div class="sc-val"><%= totalEnrollments %></div>
          <div class="sc-lbl">Tổng lượt đăng ký</div>
          <div class="sc-sub">Tất cả các khóa</div>
        </div>
      </div>
      <div class="stat-card sc-t4">
        <div class="sc-icon sc-i4">👨‍🏫</div>
        <div>
          <div class="sc-val"><%= totalTeachers %></div>
          <div class="sc-lbl">Tổng giáo viên</div>
          <div class="sc-sub"><%= pendingCount > 0 ? pendingCount + " chờ duyệt" : "Đang hoạt động" %></div>
        </div>
      </div>
    <% } %>
    </div>

    <!-- CHARTS ROW -->
    <div class="charts-row">
      <!-- Bar Chart — Lượt đăng ký hàng tháng -->
      <div class="chart-card">
        <h3>📈 Lượt đăng ký hàng tháng</h3>
        <div class="ch-sub">6 tháng gần đây — dữ liệu từ bảng enrollments</div>
        <canvas id="barChart" height="110"></canvas>
      </div>
      <!-- Donut Chart — Khóa học phổ biến -->
      <div class="chart-card">
        <h3>🏆 Khóa học phổ biến</h3>
        <div class="ch-sub">Xếp theo số lượt đăng ký</div>
        <canvas id="donutChart" height="150"></canvas>
      </div>
    </div>
    <script>
    (function() {
        function waitAndInitDash(attempt) {
            if (typeof Chart !== 'undefined' && typeof initDashboardCharts === 'function') {
                window._chartsInitialized = false;
                initDashboardCharts();
            } else if (attempt < 20) {
                setTimeout(function() { waitAndInitDash(attempt + 1); }, 150);
            }
        }
        waitAndInitDash(0);
    })();
    </script>

    <!-- TABLES ROW -->
    <div class="tables-row">

      <!-- Bảng khóa học phổ biến -->
      <div class="tbl-card">
        <div class="tbl-hdr">
          <h3>🏆 Top 5 khóa học phổ biến</h3>
          <a href="dashboard?tab=courses">Xem tất cả →</a>
        </div>
        <% if (topCourses.isEmpty()) { %>
          <p class="empty-msg">Chưa có dữ liệu khóa học</p>
        <% } else { %>
        <table>
          <thead><tr><th>#</th><th>Tên khóa học</th><th>Đăng ký</th></tr></thead>
          <tbody>
          <% String[] colors = {"b-blue","b-green","b-orange","b-purple","b-blue"};
             for (int i = 0; i < topCourses.size(); i++) {
               Map<String,Object> c2 = topCourses.get(i);
               String cname = c2.get("name").toString();
               if (cname.length() > 24) cname = cname.substring(0,24) + "…";
          %>
            <tr>
              <td><span class="badge <%= colors[i % colors.length] %>"><%= (i+1) %></span></td>
              <td><%= cname %></td>
              <td><strong><%= c2.get("total") %></strong> người</td>
            </tr>
          <% } %>
          </tbody>
        </table>
        <% } %>
      </div>

      <!-- Bảng đăng ký gần đây -->
      <div class="tbl-card">
        <div class="tbl-hdr">
          <h3>🕐 Đăng ký gần đây</h3>
          <a href="#">Xem tất cả →</a>
        </div>
        <% if (recentEnroll.isEmpty()) { %>
          <p class="empty-msg">Chưa có lượt đăng ký</p>
        <% } else { %>
        <table>
          <thead><tr><th>Học sinh</th><th>Khóa học</th><th>Ngày</th></tr></thead>
          <tbody>
          <% for (Map<String,Object> e : recentEnroll) {
               String cname = e.get("course").toString();
               if (cname.length() > 18) cname = cname.substring(0,18) + "…";
               // BUG FIX: แปลง enrolled_at อย่างปลอดภัย
               Object _eDateObj = e.get("enrolled_at");
               String edate = "—";
               if (_eDateObj instanceof java.sql.Timestamp) {
                   edate = ((java.sql.Timestamp)_eDateObj).toLocalDateTime()
                           .format(java.time.format.DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm"));
               } else if (_eDateObj != null) {
                   String _rawE = _eDateObj.toString().replace("T"," ");
                   if (_rawE.matches("\\d{4}-\\d{2}-\\d{2}.*")) {
                       String[] _dp = _rawE.substring(0,10).split("-");
                       edate = _dp[2] + "/" + _dp[1] + "/" + _dp[0];
                       if (_rawE.length() >= 16) edate += " " + _rawE.substring(11,16);
                   } else { edate = _rawE.length() > 0 ? _rawE : "—"; }
               }
          %>
            <tr>
              <td>👤 <%= e.get("username") %></td>
              <td><span class="badge b-blue"><%= cname %></span></td>
              <td><%= edate %></td>
            </tr>
          <% } %>
          </tbody>
        </table>
        <% } %>
      </div>

    </div><!-- end tables-row -->

    <!-- ═══ SUPER ADMIN SECTION ═══════════════════════════════════ -->
    <% if (role.equals("super_admin")) { %>
    <div class="sa-section">
      <div class="sa-title">👑 Quản lý hệ thống — Super Admin</div>

      <!-- Mini stats -->
      <div class="sa-grid">
        <div class="sa-stat">
          <div class="sa-s-icon">👥</div>
          <div>
            <div class="sa-s-val"><%= allUsers.size() %></div>
            <div class="sa-s-lbl">Tổng người dùng trong hệ thống</div>
          </div>
        </div>
        <div class="sa-stat">
          <div class="sa-s-icon">🛡️</div>
          <div>
            <div class="sa-s-val">
              <%
                long adminCount = 0;
                for (UserDTO _xu : allUsers) { if ("admin".equalsIgnoreCase(_xu.getRole())) adminCount++; }
              %>
              <%= adminCount %>
            </div>
            <div class="sa-s-lbl">Số lượng Admin trong hệ thống</div>
          </div>
        </div>
      </div>

      <!-- All Users Table -->
      <div class="user-tbl-card">
        <div class="user-tbl-hdr">
          <h3>📋 Danh sách tất cả người dùng</h3>
          <span><%= allUsers.size() %> người</span>
        </div>
        <% if (allUsers.isEmpty()) { %>
          <p class="empty-msg">Chưa có người dùng trong hệ thống</p>
        <% } else { %>
        <table>
          <thead>
            <tr>
              <th>ID</th>
              <th>Username</th>
              <th>Role</th>
              <th>Trạng thái</th>
            </tr>
          </thead>
          <tbody>
          <% for (UserDTO u : allUsers) {
               String chipClass = "chip-student";
               String roleLabel = u.getRole();
               if ("super_admin".equalsIgnoreCase(u.getRole()))  { chipClass = "chip-sa";      roleLabel = "Super Admin"; }
               else if ("admin".equalsIgnoreCase(u.getRole()))   { chipClass = "chip-admin";   roleLabel = "Admin"; }
               else if ("teacher".equalsIgnoreCase(u.getRole())) { chipClass = "chip-teacher"; roleLabel = "Teacher"; }
               else                                              { chipClass = "chip-student"; roleLabel = "Học sinh"; }
          %>
            <tr>
              <td><span class="badge b-blue">#<%= u.getId() %></span></td>
              <td>
                <% if ("super_admin".equalsIgnoreCase(u.getRole())) { %>
                  👑 <strong><%= u.getUsername() %></strong>
                <% } else { %>
                  👤 <%= u.getUsername() %>
                <% } %>
              </td>
              <td><span class="role-chip <%= chipClass %>"><%= roleLabel %></span></td>
              <td><span style="color:#10b981;font-size:12px;">● Đang hoạt động</span></td>
            </tr>
          <% } %>
          </tbody>
        </table>
        <% } %>
      </div>
    </div><!-- end sa-section -->
    <% } %>

    <% } else if (activeTab.equals("admin") && role.equals("super_admin")) { /* ══ TAB: ADMIN MANAGEMENT ══ */ %>

    <!-- CSS bổ sung cho tab Quản lý Admin -->
    <link rel="stylesheet" href="css/dashboard.css?v=4">

    <!-- Page Header -->
    <div class="am-page-hdr">
      <div>
        <h2>👑 Quản lý Admin</h2>
        <p>Tạo, chỉnh sửa và quản lý tài khoản Admin trong hệ thống</p>
      </div>
      <button class="btn btn-primary" onclick="amOpenCreate()">➕ Thêm Admin mới</button>
    </div>

    <!-- Alerts -->
    <% if (successParam != null && !successParam.isEmpty()) { %>
    <script>document.addEventListener('DOMContentLoaded',function(){ showNotifyModal('success','✅ Thành công','<%= successParam.replace("'","\\'") %>'); });</script>
    <% } %>
    <% if (adminErr != null) { %>
    <script>document.addEventListener('DOMContentLoaded',function(){ showNotifyModal('error','⚠️ Lỗi','<%= adminErr.replace("'","\\'") %>'); });</script>
    <% } %>

    <!-- Stat Cards -->
    <div class="am-stat-row" style="grid-template-columns:repeat(4,1fr);">
      <div class="am-stat-card am-sc-t1">
        <div class="am-sc-icon am-sc-i1">👑</div>
        <div><div class="am-sc-val"><%= totalSuperAdmins %></div><div class="am-sc-lbl">Tổng Super Admin</div></div>
      </div>
      <div class="am-stat-card am-sc-t2">
        <div class="am-sc-icon" style="background:#fef3c7;">🛡️</div>
        <div><div class="am-sc-val"><%= totalAdmins %></div><div class="am-sc-lbl">Tổng Admin</div></div>
      </div>
      <div class="am-stat-card am-sc-t2">
        <div class="am-sc-icon am-sc-i2">✅</div>
        <div><div class="am-sc-val"><%= totalActiveAdmins %></div><div class="am-sc-lbl">Admin đang hoạt động</div></div>
      </div>
      <div class="am-stat-card am-sc-t3">
        <div class="am-sc-icon am-sc-i3">⛔</div>
        <div><div class="am-sc-val"><%= totalAdmins - totalActiveAdmins %></div><div class="am-sc-lbl">Admin bị vô hiệu hóa</div></div>
      </div>
    </div>

    <!-- Super Admin Table -->
    <div class="am-card" style="margin-bottom:18px;">
      <div class="am-card-hdr">
        <h3>👑 Danh sách Super Admin (<%= totalSuperAdmins %> người)</h3>
      </div>
      <% if (superAdminList.isEmpty()) { %>
        <div class="am-empty-state"><div class="ei">👑</div><p>Không có dữ liệu Super Admin</p></div>
      <% } else { %>
      <table>
        <thead><tr><th>ID</th><th>Tên đăng nhập</th><th>Vai trò</th><th>Trạng thái</th><th>Thao tác</th></tr></thead>
        <tbody>
        <% for (UserDTO sa : superAdminList) { %>
          <tr>
            <td><span style="font-size:12px;color:#94a3b8;">#<%= sa.getId() %></span></td>
            <td>
              <div class="am-user-info">
                <div class="am-user-avatar" style="background:linear-gradient(135deg,#b45309,#92400e);">👑</div>
                <div>
                  <div class="am-user-name"><%= sa.getUsername() %></div>
                  <div class="am-user-id">ID: <%= sa.getId() %></div>
                </div>
              </div>
            </td>
            <td><span class="badge chip-sa">👑 Super Admin</span></td>
            <td><span class="badge badge-active">● Đang hoạt động</span></td>
            <td>
              <div class="am-actions">
                <button class="btn btn-info btn-sm" onclick="amOpenReset(<%= sa.getId() %>, '<%= sa.getUsername() %>')">🔑 Đặt lại MK</button>
              </div>
            </td>
          </tr>
        <% } %>
        </tbody>
      </table>
      <% } %>
    </div>

    <!-- Admin Table -->
    <div class="am-card">
      <div class="am-card-hdr">
        <h3>Danh sách Admin (<%= totalAdmins %> người)</h3>
      </div>
      <% if (adminList.isEmpty()) { %>
        <div class="am-empty-state">
          <div class="ei">🛡️</div>
          <p>Chưa có Admin trong hệ thống</p><br/>
          <button class="btn btn-primary" onclick="amOpenCreate()">➕ Thêm Admin đầu tiên</button>
        </div>
      <% } else { %>
      <table>
        <thead><tr><th>ID</th><th>Tên đăng nhập</th><th>Vai trò</th><th>Trạng thái</th><th>Thao tác</th></tr></thead>
        <tbody>
        <% for (UserDTO adm : adminList) { %>
          <tr>
            <td><span style="font-size:12px;color:#94a3b8;">#<%= adm.getId() %></span></td>
            <td>
              <div class="am-user-info">
                <div class="am-user-avatar"><%= adm.getUsername().substring(0,1).toUpperCase() %></div>
                <div>
                  <div class="am-user-name"><%= adm.getUsername() %></div>
                  <div class="am-user-id">ID: <%= adm.getId() %></div>
                </div>
              </div>
            </td>
            <td><span class="badge badge-admin">🛡️ Admin</span></td>
            <td>
              <% if ("ACTIVE".equalsIgnoreCase(adm.getStatus())) { %>
                <span class="badge badge-active">● Đang hoạt động</span>
              <% } else { %>
                <span class="badge badge-inactive">○ Không hoạt động</span>
              <% } %>
            </td>
            <td>
              <div class="am-actions">
                <form method="post" action="dashboard?tab=admin" style="display:inline;">
                  <input type="hidden" name="adminAction" value="toggle"/>
                  <input type="hidden" name="userId" value="<%= adm.getId() %>"/>
                  <button type="submit" class="btn btn-warning btn-sm">
                    🔄 <%= "ACTIVE".equalsIgnoreCase(adm.getStatus()) ? "Vô hiệu hóa" : "Kích hoạt" %>
                  </button>
                </form>
                <button class="btn btn-info btn-sm" onclick="amOpenReset(<%= adm.getId() %>, '<%= adm.getUsername() %>')">🔑 Đặt lại MK</button>
                <button class="btn btn-danger btn-sm" onclick="amOpenDelete(<%= adm.getId() %>, '<%= adm.getUsername() %>')">🗑️ Xóa</button>
              </div>
            </td>
          </tr>
        <% } %>
        </tbody>
      </table>
      <% } %>
    </div>

    <!-- MODAL: Thêm Admin / Super Admin mới -->
    <div class="am-modal-overlay" id="amCreateModal">
      <div class="am-modal">
        <div class="am-modal-title">➕ Thêm quản trị viên mới</div>
        <div class="am-modal-sub">Tạo tài khoản Admin hoặc Super Admin</div>
        <form method="post" action="dashboard?tab=admin">
          <input type="hidden" name="adminAction" value="create"/>
          <div class="am-field">
            <label>Vai trò <span class="req">*</span></label>
            <select name="saRole" id="saRoleSelect" onchange="amUpdateRoleUI()"
              style="width:100%;height:42px;padding:0 12px;border:1.5px solid #e2e8f0;border-radius:9px;font-size:13px;font-family:inherit;outline:none;color:#1a2332;">
              <option value="ADMIN">🛡️ Admin</option>
              <option value="SUPER_ADMIN">👑 Super Admin</option>
            </select>
          </div>
          <div id="amRoleBanner" style="display:none;background:#fffbeb;border:1.5px solid #fde68a;border-radius:9px;padding:10px 14px;font-size:12px;color:#92400e;margin-bottom:14px;">
            ⚠️ Super Admin có quyền cao nhất trong hệ thống, vui lòng xác nhận trước khi tạo
          </div>
          <div class="am-row-2">
            <div class="am-field"><label>Họ <span class="req">*</span></label><input type="text" name="firstName" placeholder="Họ" required/></div>
            <div class="am-field"><label>Tên <span class="req">*</span></label><input type="text" name="lastName" placeholder="Tên" required/></div>
          </div>
          <div class="am-field"><label>Tên đăng nhập <span class="req">*</span></label><input type="text" name="username" placeholder="username" required minlength="4" pattern="[a-zA-Z0-9_]+"/></div>
          <div class="am-field"><label>Email <span class="req">*</span></label><input type="email" name="email" placeholder="email@example.com" required/></div>
          <div class="am-field"><label>Mật khẩu <span class="req">*</span></label><input type="password" name="password" placeholder="Tối thiểu 8 ký tự" required minlength="8"/></div>
          <div class="am-modal-footer">
            <button type="button" class="btn btn-cancel" onclick="amCloseCreate()">Hủy</button>
            <button type="submit" class="btn btn-primary" id="amCreateBtn">✅ Tạo Admin</button>
          </div>
        </form>
      </div>
    </div>

    <!-- MODAL: Đặt lại mật khẩu -->
    <div class="am-modal-overlay" id="amResetModal">
      <div class="am-modal">
        <div class="am-modal-title">🔑 Đặt lại mật khẩu</div>
        <div class="am-modal-sub">Đặt mật khẩu mới cho: <strong id="amResetName"></strong></div>
        <form method="post" action="dashboard?tab=admin">
          <input type="hidden" name="adminAction" value="resetpw"/>
          <input type="hidden" name="userId" id="amResetId"/>
          <div class="am-field"><label>Mật khẩu mới <span class="req">*</span></label><input type="password" name="newPassword" id="amNewPw" placeholder="Tối thiểu 8 ký tự" required minlength="8"/></div>
          <div class="am-modal-footer">
            <button type="button" class="btn btn-cancel" onclick="amCloseReset()">Hủy</button>
            <button type="submit" class="btn btn-primary">🔑 Xác nhận</button>
          </div>
        </form>
      </div>
    </div>

    <!-- MODAL: Xác nhận xóa -->
    <div id="amDeleteModal" style="display:none;position:fixed;inset:0;z-index:9999;align-items:center;justify-content:center;">
      <div onclick="amCloseDelete()" style="position:absolute;inset:0;background:rgba(15,23,42,.4);backdrop-filter:blur(4px);"></div>
      <div style="position:relative;background:#fff;border-radius:20px;padding:36px 32px 28px;width:360px;max-width:90vw;box-shadow:0 24px 60px rgba(0,0,0,.18);animation:toastIn .22s ease;text-align:center;">
        <div style="font-size:50px;margin-bottom:12px;">🗑️</div>
        <div style="font-size:18px;font-weight:700;color:#1a2332;margin-bottom:8px;">Xác nhận xóa</div>
        <div style="font-size:14px;color:#64748b;margin-bottom:28px;line-height:1.6;">
          Bạn có chắc muốn xóa <strong id="amDeleteName"></strong>?<br/>Hành động này không thể hoàn tác
        </div>
        <form method="post" action="dashboard?tab=admin">
          <input type="hidden" name="adminAction" value="delete"/>
          <input type="hidden" name="userId" id="amDeleteId"/>
          <div style="display:flex;gap:10px;">
            <button type="button" onclick="amCloseDelete()"
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

    <script>
    <% if (adminErr != null) { %>amOpenCreate();<% } %>
    </script>

    <% } else if (activeTab.equals("users") && (role.equals("super_admin") || role.equals("admin"))) { /* ══ TAB: USERS ══ */ %>

    <link rel="stylesheet" href="css/dashboard.css?v=4">

    <!-- Page Header -->
    <div class="um-page-hdr">
      <h2>👥 Quản lý người dùng</h2>
      <p>Xem danh sách và quản lý học sinh / giáo viên trong hệ thống</p>
    </div>

    <!-- Alerts -->
    <% if (successParam != null && !successParam.isEmpty() && activeTab.equals("users")) { %>
    <script>document.addEventListener('DOMContentLoaded',function(){ showNotifyModal('success','✅ Thành công','<%= successParam.replace("'","\\'") %>'); });</script>
    <% } %>
    <% if (userErr != null) { %>
    <script>document.addEventListener('DOMContentLoaded',function(){ showNotifyModal('error','⚠️ Lỗi','<%= userErr.replace("'","\\'") %>'); });</script>
    <% } %>

    <!-- Stat Cards -->
    <div class="um-stat-row">
      <div class="um-stat-card um-sc-t1">
        <div class="um-sc-icon um-sc-i1">👨‍🎓</div>
        <div>
          <div class="um-sc-val"><%= studentList.size() %></div>
          <div class="um-sc-lbl">Tổng học sinh</div>
        </div>
      </div>
      <div class="um-stat-card um-sc-t2">
        <div class="um-sc-icon um-sc-i2">👨‍🏫</div>
        <div>
          <div class="um-sc-val"><%= teacherList.size() %></div>
          <div class="um-sc-lbl">Tổng giáo viên</div>
        </div>
      </div>
    </div>

    <!-- Students Table -->
    <div class="um-card">
      <div class="um-card-hdr">
        <h3>👨‍🎓 Danh sách học sinh</h3>
        <span><%= studentList.size() %> người</span>
      </div>
      <% if (studentList.isEmpty()) { %>
        <div class="um-empty">Chưa có học sinh trong hệ thống</div>
      <% } else { %>
      <table>
        <thead><tr><th>ID</th><th>Tên đăng nhập</th><th>Vai trò</th><th>Trạng thái</th><th>Thao tác</th></tr></thead>
        <tbody>
        <% for (UserDTO u2 : studentList) { %>
          <tr>
            <td><span style="font-size:12px;color:#94a3b8;">#<%= u2.getId() %></span></td>
            <td>
              <div class="um-user-info">
                <div class="um-avatar um-avatar-s"><%= u2.getUsername().substring(0,1).toUpperCase() %></div>
                <div>
                  <div class="um-user-name"><%= u2.getUsername() %></div>
                  <div class="um-user-id">ID: <%= u2.getId() %></div>
                </div>
              </div>
            </td>
            <td><span class="badge b-blue">🎓 Học sinh</span></td>
            <td>
              <% if ("ACTIVE".equalsIgnoreCase(u2.getStatus()) || u2.getStatus() == null) { %>
                <span class="badge badge-active">● Đang hoạt động</span>
              <% } else { %>
                <span class="badge badge-inactive">○ Không hoạt động</span>
              <% } %>
            </td>
            <td style="white-space:nowrap;">
              <button class="btn btn-sm" onclick="umOpenResetPw(<%= u2.getId() %>, '<%= u2.getUsername() %>')"
                style="background:#e0f2fe;color:#0369a1;border:none;border-radius:7px;padding:5px 10px;font-size:12px;font-weight:700;cursor:pointer;margin-right:4px;"
                onmouseenter="this.style.background='#bae6fd'" onmouseleave="this.style.background='#e0f2fe'">🔑 Đặt lại MK</button>
              <% String _bg    = "ACTIVE".equalsIgnoreCase(u2.getStatus()) ? "#fef2f2" : "#f0fdf4"; %>
              <% String _color = "ACTIVE".equalsIgnoreCase(u2.getStatus()) ? "#dc2626" : "#16a34a"; %>
              <% String _label = "ACTIVE".equalsIgnoreCase(u2.getStatus()) ? "🔒 Khóa" : "🔓 Mở"; %>
              <button class="btn btn-sm" onclick="umToggleStatus(<%= u2.getId() %>, '<%= u2.getUsername() %>', '<%= u2.getStatus() %>')"
                style="background:<%= _bg %>;color:<%= _color %>;border:none;border-radius:7px;padding:5px 10px;font-size:12px;font-weight:700;cursor:pointer;margin-right:4px;"
                onmouseenter="this.style.opacity='.8'" onmouseleave="this.style.opacity='1'"><%= _label %></button>
              <button class="btn btn-danger btn-sm" onclick="umOpenDelete(<%= u2.getId() %>, '<%= u2.getUsername() %>')">🗑️</button>
            </td>
          </tr>
        <% } %>
        </tbody>
      </table>
      <% } %>
    </div>

    <!-- Teachers Table -->
    <div class="um-card">
      <div class="um-card-hdr">
        <h3>👨‍🏫 Danh sách giáo viên</h3>
        <span><%= teacherList.size() %> người</span>
      </div>
      <% if (teacherList.isEmpty()) { %>
        <div class="um-empty">Chưa có giáo viên trong hệ thống</div>
      <% } else { %>
      <table>
        <thead><tr><th>ID</th><th>Tên đăng nhập</th><th>Vai trò</th><th>Trạng thái</th><th>Thao tác</th></tr></thead>
        <tbody>
        <% for (UserDTO u2 : teacherList) { %>
          <tr>
            <td><span style="font-size:12px;color:#94a3b8;">#<%= u2.getId() %></span></td>
            <td>
              <div class="um-user-info">
                <div class="um-avatar um-avatar-t"><%= u2.getUsername().substring(0,1).toUpperCase() %></div>
                <div>
                  <div class="um-user-name"><%= u2.getUsername() %></div>
                  <div class="um-user-id">ID: <%= u2.getId() %></div>
                </div>
              </div>
            </td>
            <td><span class="badge b-green">🏫 Giáo viên</span></td>
            <td>
              <% if ("ACTIVE".equalsIgnoreCase(u2.getStatus()) || u2.getStatus() == null) { %>
                <span class="badge badge-active">● Đang hoạt động</span>
              <% } else { %>
                <span class="badge badge-inactive">○ Không hoạt động</span>
              <% } %>
            </td>
            <td style="white-space:nowrap;">
              <button class="btn btn-sm" onclick="umOpenResetPw(<%= u2.getId() %>, '<%= u2.getUsername() %>')"
                style="background:#e0f2fe;color:#0369a1;border:none;border-radius:7px;padding:5px 10px;font-size:12px;font-weight:700;cursor:pointer;margin-right:4px;"
                onmouseenter="this.style.background='#bae6fd'" onmouseleave="this.style.background='#e0f2fe'">🔑 Đặt lại MK</button>
              <% String _bg    = "ACTIVE".equalsIgnoreCase(u2.getStatus()) ? "#fef2f2" : "#f0fdf4"; %>
              <% String _color = "ACTIVE".equalsIgnoreCase(u2.getStatus()) ? "#dc2626" : "#16a34a"; %>
              <% String _label = "ACTIVE".equalsIgnoreCase(u2.getStatus()) ? "🔒 Khóa" : "🔓 Mở"; %>
              <button class="btn btn-sm" onclick="umToggleStatus(<%= u2.getId() %>, '<%= u2.getUsername() %>', '<%= u2.getStatus() %>')"
                style="background:<%= _bg %>;color:<%= _color %>;border:none;border-radius:7px;padding:5px 10px;font-size:12px;font-weight:700;cursor:pointer;margin-right:4px;"
                onmouseenter="this.style.opacity='.8'" onmouseleave="this.style.opacity='1'"><%= _label %></button>
              <button class="btn btn-danger btn-sm" onclick="umOpenDelete(<%= u2.getId() %>, '<%= u2.getUsername() %>')">🗑️</button>
            </td>
          </tr>
        <% } %>
        </tbody>
      </table>
      <% } %>
    </div>

    <!-- MODAL: Xác nhận xóa người dùng -->
    <div id="umDeleteModal" style="display:none;position:fixed;inset:0;z-index:9999;align-items:center;justify-content:center;">
      <div onclick="umCloseDelete()" style="position:absolute;inset:0;background:rgba(15,23,42,.4);backdrop-filter:blur(4px);"></div>
      <div style="position:relative;background:#fff;border-radius:20px;padding:36px 32px 28px;width:360px;max-width:90vw;box-shadow:0 24px 60px rgba(0,0,0,.18);animation:toastIn .22s ease;text-align:center;">
        <div style="font-size:50px;margin-bottom:12px;">🗑️</div>
        <div style="font-size:18px;font-weight:700;color:#1a2332;margin-bottom:8px;">Xác nhận xóa</div>
        <div style="font-size:14px;color:#64748b;margin-bottom:28px;line-height:1.6;">
          Bạn có chắc muốn xóa <strong id="umDeleteName"></strong>?<br/>Hành động này không thể hoàn tác
        </div>
        <form method="post" action="<%= request.getContextPath() %>/dashboard?tab=users">
          <input type="hidden" name="userAction" value="delete"/>
          <input type="hidden" name="userId" id="umDeleteId"/>
          <div style="display:flex;gap:10px;">
            <button type="button" onclick="umCloseDelete()"
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

    <!-- MODAL: Reset mật khẩu -->
    <div id="umResetPwModal" style="display:none;position:fixed;inset:0;z-index:9999;align-items:center;justify-content:center;">
      <div onclick="umCloseResetPw()" style="position:absolute;inset:0;background:rgba(15,23,42,.4);backdrop-filter:blur(4px);"></div>
      <div style="position:relative;background:#fff;border-radius:20px;padding:36px 32px 28px;width:400px;max-width:90vw;box-shadow:0 24px 60px rgba(0,0,0,.18);animation:toastIn .22s ease;text-align:center;">
        <div style="font-size:50px;margin-bottom:12px;">🔑</div>
        <div style="font-size:18px;font-weight:700;color:#1a2332;margin-bottom:8px;">Đặt lại mật khẩu</div>
        <div style="font-size:14px;color:#64748b;margin-bottom:20px;line-height:1.6;">
          Đặt mật khẩu mới cho <strong id="umResetName"></strong>
        </div>
        <form method="post" action="<%= request.getContextPath() %>/dashboard?tab=users">
          <input type="hidden" name="userAction" value="resetPassword"/>
          <input type="hidden" name="userId" id="umResetId"/>
          <div style="margin-bottom:16px;text-align:left;">
            <label style="font-size:11px;font-weight:700;color:#64748b;text-transform:uppercase;letter-spacing:.5px;display:block;margin-bottom:6px;">มật khẩuใหม่ (ขั้นต่ำ 8 ตัว)</label>
            <input type="password" name="newPassword" id="umResetPwInput" placeholder="Nhập mật khẩu mới..." required minlength="8"
              style="width:100%;box-sizing:border-box;padding:10px 14px;border:1.5px solid #e2e8f0;border-radius:10px;font-size:13px;outline:none;background:#f8fafc;"
              onfocus="this.style.borderColor='#6366f1'" onblur="this.style.borderColor='#e2e8f0'"/>
          </div>
          <div style="display:flex;gap:10px;">
            <button type="button" onclick="umCloseResetPw()"
              style="flex:1;padding:11px 0;border-radius:10px;border:1.5px solid #e2e8f0;background:#f8fafc;color:#475569;font-size:14px;font-weight:600;cursor:pointer;">
              Hủy
            </button>
            <button type="submit"
              style="flex:1;padding:11px 0;border-radius:10px;border:none;background:linear-gradient(135deg,#6366f1,#8b5cf6);color:#fff;font-size:14px;font-weight:700;cursor:pointer;">
              🔑 Đặt lại
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- MODAL: Xác nhận khóa/mở tài khoản -->
    <div id="umToggleModal" style="display:none;position:fixed;inset:0;z-index:9999;align-items:center;justify-content:center;">
      <div onclick="umCloseToggle()" style="position:absolute;inset:0;background:rgba(15,23,42,.4);backdrop-filter:blur(4px);"></div>
      <div style="position:relative;background:#fff;border-radius:20px;padding:36px 32px 28px;width:380px;max-width:90vw;box-shadow:0 24px 60px rgba(0,0,0,.18);animation:toastIn .22s ease;text-align:center;">
        <div id="umToggleIcon" style="font-size:50px;margin-bottom:12px;">🔒</div>
        <div id="umToggleTitle" style="font-size:18px;font-weight:700;color:#1a2332;margin-bottom:8px;">Khóa tài khoản</div>
        <div style="font-size:14px;color:#64748b;margin-bottom:28px;line-height:1.6;">
          Bạn có chắc muốn <span id="umToggleAction">khóa</span> tài khoản <strong id="umToggleName"></strong>?
        </div>
        <form method="post" action="<%= request.getContextPath() %>/dashboard?tab=users">
          <input type="hidden" name="userAction" value="toggleStatus"/>
          <input type="hidden" name="userId" id="umToggleId"/>
          <div style="display:flex;gap:10px;">
            <button type="button" onclick="umCloseToggle()"
              style="flex:1;padding:11px 0;border-radius:10px;border:1.5px solid #e2e8f0;background:#f8fafc;color:#475569;font-size:14px;font-weight:600;cursor:pointer;">
              Hủy
            </button>
            <button type="submit" id="umToggleSubmitBtn"
              style="flex:1;padding:11px 0;border-radius:10px;border:none;background:linear-gradient(135deg,#ef4444,#dc2626);color:#fff;font-size:14px;font-weight:700;cursor:pointer;">
              🔒 Khóa
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- User Management JS moved to dashboard.js -->



    <% } else if (activeTab.equals("manage-courses") && (role.equals("teacher") || role.equals("admin") || role.equals("super_admin"))) { /* ══ TAB: MANAGE-COURSES ══ */ %>

    <% if (courseSuccess != null) { %>
    <script>document.addEventListener('DOMContentLoaded',function(){ showNotifyModal('success','✅ Thành công','<%= courseSuccess.replace("'","\\'") %>'); });</script>
    <% } %>
    <% if (courseErr != null) { %>
    <script>document.addEventListener('DOMContentLoaded',function(){ showNotifyModal('error','⚠️ Lỗi','<%= courseErr.replace("'","\\'") %>'); });</script>
    <% } %>

    <div class="cm-page-hdr">
      <div>
        <h2>📚 Quản lý khóa học</h2>
        <p>Tạo và quản lý khóa học, cùng với tải video vào từng khóa học</p>
      </div>
      <button class="btn btn-primary" onclick="openModal('modalAddCourse')" style="display:flex;align-items:center;gap:6px;font-size:13px;padding:10px 18px;">
        <span>+</span> Thêm khóa học mới
      </button>
    </div>

    <!-- STAT CARDS -->
    <div class="cm-stat-row">
      <div class="cm-stat-card cm-sc-t1">
        <div class="cm-sc-icon cm-sc-i1">📚</div>
        <div><div class="cm-sc-val"><%= courseList.size() %></div><div class="cm-sc-lbl">Tổng khóa học</div></div>
      </div>
      <div class="cm-stat-card cm-sc-t2">
        <div class="cm-sc-icon cm-sc-i2">🎬</div>
        <div>
          <div class="cm-sc-val"><%
            int _totalVids = 0;
            for (CourseDTO _cs : courseList) { _totalVids += _videoSvc.getVideosByCourse(_cs.getId()).size(); }
            out.print(_totalVids);
          %></div>
          <div class="cm-sc-lbl">Tổng video</div>
        </div>
      </div>
      <div class="cm-stat-card cm-sc-t3">
        <div class="cm-sc-icon cm-sc-i3">👨‍🏫</div>
        <div>
          <div class="cm-sc-val"><%
            long _teacherCount = 0;
            for (UserDTO _tu : allUsers) { if (_tu.getRole().equalsIgnoreCase("teacher")) _teacherCount++; }
            out.print(role.equals("teacher") ? "1" : String.valueOf(_teacherCount));
          %></div>
          <div class="cm-sc-lbl">Giáo viên</div>
        </div>
      </div>
      <div class="cm-stat-card" style="border-top-color:#8b5cf6;">
        <div class="cm-sc-icon" style="background:#f5f3ff;">👥</div>
        <div>
          <div class="cm-sc-val"><%
            out.print(totalEnrollments);
          %></div>
          <div class="cm-sc-lbl">Học viên</div>
        </div>
      </div>
    </div>

    <!-- SEARCH & FILTER BAR -->
    <div class="cm-filter-bar">
      <div class="cm-search-wrap">
        <span class="cm-search-ico">🔍</span>
        <input type="text" id="cmSearch" placeholder="Tìm kiếm khóa học..." oninput="cmFilter()" autocomplete="off">
      </div>
      <select id="cmCatFilter" onchange="cmFilter()">
        <option value="">Tất cả danh mục</option>
        <option value="General">Tổng hợp</option>
        <option value="Programming">Lập trình</option>
        <option value="Design">Thiết kế</option>
        <option value="Business">Kinh doanh</option>
        <option value="Language">Ngoại ngữ</option>
        <option value="Math">Toán học</option>
        <option value="Science">Khoa học</option>
        <option value="Other">Khác</option>
      </select>
      <select id="cmStatusFilter" onchange="cmFilter()">
        <option value="">Tất cả trạng thái</option>
        <option value="ACTIVE">Đang hoạt động</option>
        <option value="INACTIVE">Đã ẩn</option>
      </select>
    </div>

    <!-- COURSE GRID -->
    <% if (courseList.isEmpty()) { %>
      <div class="cm-empty">
        <div class="cm-empty-icon">📚</div>
        <div class="cm-empty-title">Chưa có khóa học nào</div>
        <div class="cm-empty-sub">Hãy bắt đầu tạo khóa học đầu tiên của bạn!</div>
        <button class="btn btn-primary" onclick="openModal('modalAddCourse')">Thêm khóa học đầu tiên</button>
      </div>
    <% } else { %>
      <div class="course-grid" id="cmCourseGrid">
      <% for (CourseDTO _c : courseList) {
           java.util.List<VideoDTO> _vids = _videoSvc.getVideosByCourse(_c.getId());
           boolean _isOpen = (_c.getId() == openCourseId);
           String _cat    = _c.getCategory() != null ? _c.getCategory() : "General";
           String _status = _c.getStatus()   != null ? _c.getStatus()   : "ACTIVE";
           boolean _isActive = "ACTIVE".equalsIgnoreCase(_status);
           // ── thumbnail จาก video แรก ──
           String _dThumb = null;
           String[] _dGrads = {"linear-gradient(135deg,#1e3a5f,#3b82f6)","linear-gradient(135deg,#064e3b,#10b981)","linear-gradient(135deg,#4c1d95,#7c3aed)","linear-gradient(135deg,#7c2d12,#ea580c)","linear-gradient(135deg,#1e1b4b,#4f46e5)"};
           String _dGrad = _dGrads[_c.getId() % _dGrads.length];
           if (!_vids.isEmpty()) {
               String _fp = _vids.get(0).getFilePath();
               if (_fp != null && !_fp.isEmpty()) {
                   String _ytId = null;
                   if (_fp.contains("youtu.be/")) { String[] _p = _fp.split("youtu\\.be/"); if(_p.length>1) _ytId=_p[1].split("[?&]")[0]; }
                   else if (_fp.contains("v="))   { String[] _p = _fp.split("v=");           if(_p.length>1) _ytId=_p[1].split("[?&]")[0]; }
                   else if (_fp.contains("/embed/")){ String[] _p = _fp.split("/embed/");    if(_p.length>1) _ytId=_p[1].split("[?&/]")[0]; }
                   if (_ytId != null && !_ytId.isEmpty()) _dThumb = "https://img.youtube.com/vi/" + _ytId + "/mqdefault.jpg";
               }
           }
      %>
        <%
          int _enrollCnt = _enrollSvc.countEnrollmentsByCourse(_c.getId());
          String _teacherInitials = "";
          String _tName = _c.getTeacherName() != null ? _c.getTeacherName().trim() : "";
          if (!_tName.isEmpty()) {
              String[] _parts = _tName.split("\\s+");
              _teacherInitials = _parts[0].substring(0,1).toUpperCase();
              if (_parts.length > 1) _teacherInitials += _parts[1].substring(0,1).toUpperCase();
          } else { _teacherInitials = "??"; }
          String[] _avatarColors = {"#4f46e5","#0891b2","#059669","#d97706","#dc2626","#7c3aed","#db2777"};
          String _avatarColor = _avatarColors[Math.abs(_tName.hashCode()) % _avatarColors.length];
        %>
        <div class="cc2-card" id="card-<%= _c.getId() %>"
             data-name="<%= (_c.getName() != null ? _c.getName() : "").toLowerCase().replace("\"","") %>"
             data-cat="<%= _cat %>"
             data-status="<%= _status %>"
             onclick="openCoursePanel(<%= _c.getId() %>,'<%= (_c.getName()!=null?_c.getName():"").replace("'","\\'") %>','<%= (_c.getDescription()!=null?_c.getDescription():"").replace("'","\\'") %>','<%= _cat %>','<%= _status %>',<%= _vids.size() %>,<%= _enrollCnt %>)">

          <!-- Banner -->
          <div class="cc2-banner" style="background:<%= _dGrad %>">
            <div class="cc2-free-badge">Miễn phí</div>
            <% if (_dThumb != null) { %>
              <img src="<%= _dThumb %>" alt="<%= _c.getName() %>" loading="lazy"
                   onerror="this.style.display='none'"/>
            <% } else { %>
              <div class="cc2-banner-icon">📚</div>
            <% } %>
          </div>

          <!-- Teacher row -->
          <div class="cc2-teacher-row">
            <div class="cc2-avatar" style="background:<%= _avatarColor %>"><%= _teacherInitials %></div>
            <div class="cc2-teacher-info">
              <div class="cc2-teacher-name"><%= _tName.isEmpty() ? "Giảng viên" : _tName %></div>
              <div class="cc2-teacher-cat"><%= _cat %></div>
            </div>
          </div>

          <!-- Title -->
          <div class="cc2-title"><%= _c.getName() %></div>
          <div class="cc2-subtitle"><%= _enrollCnt %> học viên đã đăng ký</div>

          <!-- Footer -->
          <div class="cc2-footer">
            <span class="cc2-price">Miễn phí</span>
            <div class="cc2-footer-stats">
              <span class="cc2-stat"><span>👥</span> <%= _enrollCnt %> người</span>
              <% if (_vids.size() > 0) { %>
              <span class="cc2-stat cc2-stat-vid"><span>▶</span> <%= _vids.size() %> bài</span>
              <% } %>
            </div>
          </div>

        </div>
      <% } %>
      </div>
      <div class="cm-empty" id="cmNoResults" style="display:none;">
        <div class="cm-empty-icon">🔍</div>
        <div class="cm-empty-title">Không tìm thấy khóa học</div>
        <div class="cm-empty-sub">Thử từ khóa khác hoặc thay đổi bộ lọc</div>
      </div>
    <% } %>

    <!-- MODAL: Course Panel (กดการ์ด → จัดการ) -->
    <div class="cm-overlay" id="modalCoursePanel" onclick="if(event.target===this)closeModal('modalCoursePanel')">
      <div class="cm-modal cp-modal">
        <button class="cp-close-btn" onclick="closeModal('modalCoursePanel')">✕</button>

        <!-- Gradient Header Banner -->
        <div class="cp-header">
          <div class="cp-header-inner">
            <div style="flex:1;min-width:0;">
              <div class="cp-course-title" id="cpTitle">—</div>
              <div class="cp-course-meta">
                <span id="cpCat" class="cp-tag"></span>
                <span id="cpStatus" class="cp-tag-status"></span>
              </div>
            </div>
            <div class="cp-header-stats">
              <div class="cp-stat-box"><div class="cp-stat-val" id="cpVideos">0</div><div class="cp-stat-lbl">bài học</div></div>
              <div class="cp-stat-box"><div class="cp-stat-val" id="cpEnrolls">0</div><div class="cp-stat-lbl">học viên</div></div>
            </div>
          </div>
        </div>

        <!-- Action buttons -->
        <div class="cp-actions">
          <button class="cp-action-btn cp-act-video" id="cpBtnVideo">
            <span class="cp-act-icon">🎬</span>
            <span class="cp-act-label">Thêm video</span>
          </button>
          <button class="cp-action-btn cp-act-edit" id="cpBtnEdit">
            <span class="cp-act-icon">✏️</span>
            <span class="cp-act-label">Sửa</span>
          </button>
          <button class="cp-action-btn cp-act-hw" id="cpBtnHw">
            <span class="cp-act-icon">📋</span>
            <span class="cp-act-label">Bài tập</span>
          </button>
          <button class="cp-action-btn cp-act-delete" id="cpBtnDelete">
            <span class="cp-act-icon">🗑️</span>
            <span class="cp-act-label">Xóa</span>
          </button>
        </div>

        <!-- Video list -->
        <div class="cp-section-title">▶ Danh sách video</div>
        <div id="cpVideoList" class="cp-video-list">
          <div class="cpb-empty">📭 Chưa có video trong khóa học này</div>
        </div>

        <!-- Homework list -->
        <div class="cp-section-title">📂 Tệp bài tập đã tải lên</div>
        <div id="cpHomeworkList" class="cp-video-list">
          <div class="cpb-empty">📭 Chưa có tệp bài tập — nhấn 📋 Bài tập để tải lên</div>
        </div>

        <!-- Go to classroom link -->
        <div style="padding:0 16px 22px;text-align:center;">
          <a id="cpClassroomLink" href="#"
             style="display:inline-flex;align-items:center;gap:8px;font-size:13px;font-weight:700;color:#1d4ed8;background:#eff6ff;border:1.5px solid #bfdbfe;padding:10px 24px;border-radius:12px;text-decoration:none;transition:all .15s;"
             onmouseover="this.style.background='#dbeafe'" onmouseout="this.style.background='#eff6ff'">
            🎓 Vào lớp học →
          </a>
        </div>
      </div>
    </div>

    <!-- MODAL: Upload Homework -->
    <div class="cm-overlay" id="modalHomework" onclick="if(event.target===this)closeModal('modalHomework')">
      <div class="cm-modal">
        <div class="cm-modal-title">📎 Đính kèm tệp bài tập</div>
        <div class="cm-modal-sub" id="hwSubtitle">Tải lên tệp bài tập cho khóa học này</div>
        <form method="post" action="<%= request.getContextPath() %>/course-manage" enctype="multipart/form-data" id="hwForm">
          <input type="hidden" name="courseAction" value="uploadHomework">
          <input type="hidden" name="courseId" id="hwCourseId">
          <div class="cm-field">
            <label>Tiêu đề bài tập <span class="cm-req">*</span></label>
            <input type="text" name="hwTitle" id="hwTitle" placeholder="Ví dụ: Bài tập tuần 1 - Python cơ bản" maxlength="255" required>
          </div>
          <div class="cm-field">
            <label>Mô tả</label>
            <textarea name="hwDesc" id="hwDesc" placeholder="Chi tiết bài tập..." rows="2"></textarea>
          </div>
          <div class="upload-area" id="hwDropzone"
               onclick="document.getElementById('hwFile').click()"
               ondragover="this.classList.add('drag-over');event.preventDefault()"
               ondragleave="this.classList.remove('drag-over')"
               ondrop="hwHandleDrop(event)"
               style="cursor:pointer;">
            <input type="file" id="hwFile" name="hwFile" style="display:none"
                   accept=".pdf,.doc,.docx,.zip,.rar,.png,.jpg,.jpeg,.txt,.pptx,.xlsx"
                   onchange="hwShowFile(this)">
            <div class="upload-icon">📎</div>
            <div class="upload-label">Nhấp để chọn tệp hoặc kéo và thả</div>
            <div class="upload-hint">PDF, DOC, DOCX, ZIP, PNG, JPG, XLSX, PPTX • Tối đa 50MB</div>
            <div class="upload-filename" id="hwFileName"></div>
          </div>
          <div class="cm-modal-footer">
            <button type="button" class="btn btn-outline" onclick="closeModal('modalHomework')">Hủy</button>
            <button type="submit" class="btn btn-primary" id="hwSubmitBtn">📤 Tải lên bài tập</button>
          </div>
        </form>
      </div>
    </div>

    <!-- MODAL: แก้ไขการบ้าน -->
    <div class="cm-overlay" id="modalEditHomework" onclick="if(event.target===this)closeModal('modalEditHomework')">
      <div class="cm-modal">
        <div class="cm-modal-title">✏️ Sửa bài tập</div>
        <div class="cm-modal-sub" id="editHwSubtitle">Sửa thông tin tệp bài tập</div>
        <form method="post" action="<%= request.getContextPath() %>/course-manage" enctype="multipart/form-data" id="editHwForm">
          <input type="hidden" name="courseAction" value="editHomework">
          <input type="hidden" name="hwId" id="editHwId">
          <input type="hidden" name="courseId" id="editHwCourseId">
          <div class="cm-field">
            <label>Tiêu đề bài tập <span class="cm-req">*</span></label>
            <input type="text" name="hwTitle" id="editHwTitle" maxlength="255" required>
          </div>
          <div class="cm-field">
            <label>Mô tả</label>
            <textarea name="hwDesc" id="editHwDesc" rows="2" placeholder="Chi tiết bài tập..."></textarea>
          </div>
          <div class="cm-field">
            <label>Thay đổi tệp đính kèm (nếu cần)</label>
            <div class="upload-area" id="editHwDropzone"
                 onclick="document.getElementById('editHwFile').click()"
                 ondragover="this.classList.add('drag-over');event.preventDefault()"
                 ondragleave="this.classList.remove('drag-over')"
                 ondrop="editHwHandleDrop(event)"
                 style="cursor:pointer;">
              <input type="file" id="editHwFile" name="hwFile" style="display:none"
                     accept=".pdf,.doc,.docx,.zip,.rar,.png,.jpg,.jpeg,.txt,.pptx,.xlsx"
                     onchange="editHwShowFile(this)">
              <div class="upload-icon">📎</div>
              <div class="upload-label">Nhấp để chọn tệp mới hoặc kéo và thả</div>
              <div class="upload-hint">Nếu không chọn, sẽ sử dụng tệp cũ</div>
              <div class="upload-filename" id="editHwFileName"></div>
            </div>
          </div>
          <div class="cm-modal-footer">
            <button type="button" class="btn btn-outline" onclick="closeModal('modalEditHomework')">Hủy</button>
            <button type="submit" class="btn btn-primary" id="editHwSubmitBtn">💾 Lưu thay đổi</button>
          </div>
        </form>
      </div>
    </div>

    <!-- MODAL: ยืนยันลบการบ้าน -->
    <div id="modalDeleteHomework" style="display:none;position:fixed;inset:0;z-index:9999;align-items:center;justify-content:center;">
      <div onclick="closeModal('modalDeleteHomework')" style="position:absolute;inset:0;background:rgba(15,23,42,.4);backdrop-filter:blur(4px);"></div>
      <div style="position:relative;background:#fff;border-radius:20px;padding:36px 32px 28px;width:360px;max-width:90vw;box-shadow:0 24px 60px rgba(0,0,0,.18);animation:toastIn .22s ease;text-align:center;">
        <div style="font-size:50px;margin-bottom:12px;">🗑️</div>
        <div style="font-size:18px;font-weight:700;color:#1a2332;margin-bottom:8px;">Xác nhận xóa</div>
        <div id="deleteHwMsg" style="font-size:14px;color:#64748b;margin-bottom:28px;line-height:1.6;">Bạn có chắc chắn muốn xóa tệp bài tập này không?</div>
        <form method="post" action="<%= request.getContextPath() %>/course-manage" enctype="multipart/form-data" id="deleteHwForm">
          <input type="hidden" name="courseAction" value="deleteHomework">
          <input type="hidden" name="hwId" id="deleteHwId">
          <input type="hidden" name="courseId" id="deleteHwCourseId">
          <div style="display:flex;gap:10px;">
            <button type="button" onclick="closeModal('modalDeleteHomework')"
              style="flex:1;padding:11px 0;border-radius:10px;border:1.5px solid #e2e8f0;background:#f8fafc;color:#475569;font-size:14px;font-weight:600;cursor:pointer;"
              onmouseenter="this.style.background='#f1f5f9'" onmouseleave="this.style.background='#f8fafc'">Hủy</button>
            <button type="submit" id="deleteHwSubmitBtn"
              style="flex:1;padding:11px 0;border-radius:10px;border:none;background:linear-gradient(135deg,#ef4444,#dc2626);color:#fff;font-size:14px;font-weight:700;cursor:pointer;transition:opacity .15s;"
              onmouseenter="this.style.opacity='.88'" onmouseleave="this.style.opacity='1'">🗑️ Xóa</button>
          </div>
        </form>
      </div>
    </div>

    <!-- MODAL: Thêm khóa học mới -->
    <div class="cm-overlay" id="modalAddCourse">
      <div class="cm-modal">
        <div class="cm-modal-title">📚 Thêm khóa học mới</div>
        <div class="cm-modal-sub">Điền thông tin cơ bản của khóa học, sau đó thêm video vào sau</div>
        <form method="post" action="<%= request.getContextPath() %>/course-manage" enctype="multipart/form-data">
          <input type="hidden" name="courseAction" value="addCourse">
          <div class="cm-field">
            <label>Tên khóa học <span class="cm-req">*</span></label>
            <input type="text" name="courseName" id="addCourseName" placeholder="Ví dụ: Lập trình Python cơ bản" maxlength="255" required>
          </div>
          <div class="cm-field">
            <label>Mô tả khóa học</label>
            <textarea name="courseDesc" id="addCourseDesc" placeholder="Mô tả những gì học sinh sẽ học được..." rows="3"></textarea>
          </div>
          <div style="display:grid;grid-template-columns:1fr 1fr;gap:12px;">
            <div class="cm-field" style="margin-bottom:0;">
              <label>Danh mục</label>
              <select name="courseCategory" id="addCourseCategory">
                <option value="General">Tổng hợp</option>
                <option value="Programming">Lập trình</option>
                <option value="Design">Thiết kế</option>
                <option value="Business">Kinh doanh</option>
                <option value="Language">Ngoại ngữ</option>
                <option value="Math">Toán học</option>
                <option value="Science">Khoa học</option>
                <option value="Other">Khác</option>
              </select>
            </div>
            <div class="cm-field" style="margin-bottom:0;">
              <label>Trạng thái</label>
              <select name="courseStatus" id="addCourseStatus">
                <option value="ACTIVE">Đang hoạt động</option>
                <option value="INACTIVE">Ẩn khóa học</option>
              </select>
            </div>
          </div>
          <div class="cm-modal-footer">
            <button type="button" class="btn btn-outline" onclick="closeModal('modalAddCourse')">Hủy</button>
            <button type="submit" class="btn btn-primary">Tạo khóa học</button>
          </div>
        </form>
      </div>
    </div>

    <!-- MODAL: Chỉnh sửa khóa học -->
    <div class="cm-overlay" id="modalEditCourse">
      <div class="cm-modal">
        <div class="cm-modal-title">✏️ Chỉnh sửa thông tin khóa học</div>
        <div class="cm-modal-sub">Chỉnh sửa tên, mô tả, danh mục và trạng thái khóa học</div>
        <form method="post" action="<%= request.getContextPath() %>/course-manage" enctype="multipart/form-data">
          <input type="hidden" name="courseAction" value="editCourse">
          <input type="hidden" name="courseId" id="editCourseId">
          <div class="cm-field">
            <label>Tên khóa học <span class="cm-req">*</span></label>
            <input type="text" name="courseName" id="editCourseName" maxlength="255" required>
          </div>
          <div class="cm-field">
            <label>Mô tả</label>
            <textarea name="courseDesc" id="editCourseDesc" rows="3"></textarea>
          </div>
          <div style="display:grid;grid-template-columns:1fr 1fr;gap:12px;">
            <div class="cm-field" style="margin-bottom:0;">
              <label>Danh mục</label>
              <select name="courseCategory" id="editCourseCategory">
                <option value="General">Tổng hợp</option>
                <option value="Programming">Lập trình</option>
                <option value="Design">Thiết kế</option>
                <option value="Business">Kinh doanh</option>
                <option value="Language">Ngoại ngữ</option>
                <option value="Math">Toán học</option>
                <option value="Science">Khoa học</option>
                <option value="Other">Khác</option>
              </select>
            </div>
            <div class="cm-field" style="margin-bottom:0;">
              <label>Trạng thái</label>
              <select name="courseStatus" id="editCourseStatus">
                <option value="ACTIVE">Đang hoạt động</option>
                <option value="INACTIVE">Ẩn khóa học</option>
              </select>
            </div>
          </div>
          <div class="cm-modal-footer">
            <button type="button" class="btn btn-outline" onclick="closeModal('modalEditCourse')">Hủy</button>
            <button type="submit" class="btn btn-primary">Lưu thay đổi</button>
          </div>
        </form>
      </div>
    </div>

    <!-- MODAL: Xóa khóa học -->
    <div id="modalDeleteCourse" style="display:none;position:fixed;inset:0;z-index:9999;align-items:center;justify-content:center;">
      <div onclick="closeModal('modalDeleteCourse')" style="position:absolute;inset:0;background:rgba(15,23,42,.4);backdrop-filter:blur(4px);"></div>
      <div style="position:relative;background:#fff;border-radius:20px;padding:36px 32px 28px;width:360px;max-width:90vw;box-shadow:0 24px 60px rgba(0,0,0,.18);animation:toastIn .22s ease;text-align:center;">
        <div style="font-size:50px;margin-bottom:12px;">🗑️</div>
        <div style="font-size:18px;font-weight:700;color:#1a2332;margin-bottom:8px;">Xác nhận xóa</div>
        <div id="deleteCourseMsg" style="font-size:14px;color:#64748b;margin-bottom:28px;line-height:1.6;">Xóa khóa học này sẽ xóa tất cả video bên trong, không thể khôi phục</div>
        <form method="post" action="<%= request.getContextPath() %>/course-manage" enctype="multipart/form-data">
          <input type="hidden" name="courseAction" value="deleteCourse">
          <input type="hidden" name="courseId" id="deleteCourseId">
          <div style="display:flex;gap:10px;">
            <button type="button" onclick="closeModal('modalDeleteCourse')"
              style="flex:1;padding:11px 0;border-radius:10px;border:1.5px solid #e2e8f0;background:#f8fafc;color:#475569;font-size:14px;font-weight:600;cursor:pointer;"
              onmouseenter="this.style.background='#f1f5f9'" onmouseleave="this.style.background='#f8fafc'">Hủy</button>
            <button type="submit"
              style="flex:1;padding:11px 0;border-radius:10px;border:none;background:linear-gradient(135deg,#ef4444,#dc2626);color:#fff;font-size:14px;font-weight:700;cursor:pointer;transition:opacity .15s;"
              onmouseenter="this.style.opacity='.88'" onmouseleave="this.style.opacity='1'">🗑️ Xóa</button>
          </div>
        </form>
      </div>
    </div>

    <!-- MODAL: Tải video lên khóa học -->
    <div class="cm-overlay" id="modalUploadVideo">
      <div class="cm-modal">
        <div class="cm-modal-title">🎬 Tải video lên khóa học</div>
        <div class="cm-modal-sub" id="uploadVideoSubtitle">Chọn phương thức tải video lên</div>
        <form method="post" action="<%= request.getContextPath() %>/course-manage"
              enctype="multipart/form-data" id="uploadVideoForm" onsubmit="showUploadProgress()">
          <input type="hidden" name="courseAction" value="uploadVideo">
          <input type="hidden" name="courseId" id="uploadVideoCourseId">
          <div class="cm-field">
            <label>Tên video <span class="cm-req">*</span></label>
            <input type="text" name="videoTitle" id="videoTitle" placeholder="Ví dụ: Bài 1 - Giới thiệu Python" maxlength="255" required>
          </div>
          <div class="cm-field">
            <label>Mô tả video</label>
            <textarea name="videoDesc" id="videoDesc" placeholder="Mô tả nội dung video" rows="2"></textarea>
          </div>
          <div class="upload-tabs">
            <button type="button" class="upload-tab active" id="tabFile" onclick="switchUploadTab('file')">📁 Tải lên tệp</button>
            <button type="button" class="upload-tab" id="tabUrl" onclick="switchUploadTab('url')">🔗 Nhập URL</button>
          </div>
          <div id="fileSection">
            <div class="upload-area" id="dropzone" onclick="document.getElementById('videoFile').click()"
                 ondragover="this.classList.add('drag-over');event.preventDefault()"
                 ondrop="handleDrop(event)" ondragleave="this.classList.remove('drag-over')">
              <input type="file" name="videoFile" id="videoFile" accept="video/*" onchange="showFileName(this)" style="display:none">
              <div class="upload-icon">🎬</div>
              <div class="upload-label">Nhấp chọn tệp hoặc kéo thả tệp vào đây</div>
              <div class="upload-hint">MP4, MOV, AVI, MKV • Dung lượng tối đa 500MB</div>
              <div class="upload-filename" id="uploadFilename"></div>
            </div>
            <!-- Progress bar (ẩn, hiện khi đang upload) -->
            <div class="upload-progress" id="uploadProgress">
              <div style="font-size:12px;color:#64748b;margin-bottom:6px;">⏳ Đang tải lên, vui lòng chờ...</div>
              <progress id="uploadProgressBar" value="0" max="100"></progress>
            </div>
          </div>
          <div id="urlSection" style="display:none;">
            <div class="cm-field" style="margin:0;">
              <label>URL video (YouTube, Google Drive, hoặc URL trực tiếp) <span class="cm-req">*</span></label>
              <input type="text" name="videoUrl" id="videoUrl" placeholder="https://www.youtube.com/watch?v=...">
            </div>
          </div>
          <div class="cm-modal-footer">
            <button type="button" class="btn btn-outline" onclick="closeModal('modalUploadVideo')">Hủy</button>
            <button type="submit" class="btn btn-primary" id="uploadSubmitBtn">📤 Tải video lên</button>
          </div>
        </form>
      </div>
    </div>

    <!-- MODAL: Chỉnh sửa video -->
    <div class="cm-overlay" id="modalEditVideo">
      <div class="cm-modal">
        <div class="cm-modal-title">✏️ Chỉnh sửa video</div>
        <div class="cm-modal-sub">Cập nhật tên, mô tả hoặc đường dẫn video</div>
        <form method="post" action="<%= request.getContextPath() %>/course-manage" enctype="multipart/form-data">
          <input type="hidden" name="courseAction" value="editVideo">
          <input type="hidden" name="videoId"   id="editVideoId">
          <input type="hidden" name="courseId"  id="editVideoCourseId">
          <div class="cm-field">
            <label>Tên video <span class="cm-req">*</span></label>
            <input type="text" name="videoTitle" id="editVideoTitle" maxlength="255" required>
          </div>
          <div class="cm-field">
            <label>Mô tả video</label>
            <textarea name="videoDesc" id="editVideoDesc" rows="2"></textarea>
          </div>
          <div class="cm-field">
            <label>URL video</label>
            <input type="text" name="videoUrl" id="editVideoUrl" placeholder="https://www.youtube.com/watch?v=...">
          </div>
          <div class="cm-modal-footer">
            <button type="button" class="btn btn-outline" onclick="closeModal('modalEditVideo')">Hủy</button>
            <button type="submit" class="btn btn-primary">Lưu thay đổi</button>
          </div>
        </form>
      </div>
    </div>

    <!-- MODAL: Xóa video (beautiful) -->
    <div id="modalDeleteVideo" style="display:none;position:fixed;inset:0;z-index:9999;align-items:center;justify-content:center;">
      <div onclick="closeModal('modalDeleteVideo')" style="position:absolute;inset:0;background:rgba(15,23,42,.4);backdrop-filter:blur(4px);"></div>
      <div style="position:relative;background:#fff;border-radius:20px;padding:36px 32px 28px;width:360px;max-width:90vw;box-shadow:0 24px 60px rgba(0,0,0,.18);animation:toastIn .22s ease;text-align:center;">
        <div style="font-size:50px;margin-bottom:12px;">🗑️</div>
        <div style="font-size:18px;font-weight:700;color:#1a2332;margin-bottom:8px;">Xác nhận xóa</div>
        <div id="deleteVideoMsg" style="font-size:14px;color:#64748b;margin-bottom:28px;line-height:1.6;">Bạn có chắc muốn xóa video này không?<br/>Hành động này không thể hoàn tác</div>
        <form method="post" action="<%= request.getContextPath() %>/course-manage" enctype="multipart/form-data" id="deleteVideoForm">
          <input type="hidden" name="courseAction" value="deleteVideo">
          <input type="hidden" name="videoId" id="deleteVideoId">
          <input type="hidden" name="courseId" id="deleteVideoCourseId">
          <div style="display:flex;gap:10px;">
            <button type="button" onclick="closeModal('modalDeleteVideo')"
              style="flex:1;padding:11px 0;border-radius:10px;border:1.5px solid #e2e8f0;background:#f8fafc;color:#475569;font-size:14px;font-weight:600;cursor:pointer;"
              onmouseenter="this.style.background='#f1f5f9'" onmouseleave="this.style.background='#f8fafc'">Hủy</button>
            <button type="submit"
              style="flex:1;padding:11px 0;border-radius:10px;border:none;background:linear-gradient(135deg,#ef4444,#dc2626);color:#fff;font-size:14px;font-weight:700;cursor:pointer;transition:opacity .15s;"
              onmouseenter="this.style.opacity='.88'" onmouseleave="this.style.opacity='1'">🗑️ Xóา</button>
          </div>
        </form>
      </div>
    </div>

    <!-- Course Management JS moved to dashboard.js -->


    <% } /* end tab check */ %>

    <%-- ══ TAB: KHÓA HỌC (tất cả khóa học — mọi role đều thấy) ══════════════ --%>
    <% if (activeTab.equals("courses")) { %>

    <div style="display:flex;align-items:center;gap:16px;margin-bottom:24px;">
      <div style="width:54px;height:54px;border-radius:16px;background:linear-gradient(135deg,#3b82f6,#1d4ed8);display:flex;align-items:center;justify-content:center;font-size:26px;box-shadow:0 6px 18px rgba(59,130,246,.3);flex-shrink:0;">🎓</div>
      <div>
        <div style="font-size:22px;font-weight:800;color:#0f2744;letter-spacing:-.4px;">Tất cả khóa học</div>
        <div style="font-size:13px;color:#64748b;margin-top:3px;"><%= allCourseList.size() %> khóa học trong hệ thống</div>
      </div>
    </div>

    <!-- Search bar -->
    <div class="cm-filter-bar" style="margin-bottom:20px;">
      <div class="cm-search-wrap">
        <span class="cm-search-ico">🔍</span>
        <input type="text" id="allCsSearch" placeholder="Tìm kiếm khóa học..." oninput="allCsFilter()" autocomplete="off">
      </div>
      <select id="allCsCatFilter" onchange="allCsFilter()">
        <option value="">Tất cả danh mục</option>
        <option value="General">Tổng hợp</option>
        <option value="Programming">Lập trình</option>
        <option value="Design">Thiết kế</option>
        <option value="Business">Kinh doanh</option>
        <option value="Language">Ngoại ngữ</option>
        <option value="Math">Toán học</option>
        <option value="Science">Khoa học</option>
        <option value="Other">Khác</option>
      </select>
    </div>

    <% if (allCourseList.isEmpty()) { %>
      <div class="cm-empty">
        <div class="cm-empty-icon">📚</div>
        <div class="cm-empty-title">Chưa có khóa học nào</div>
        <div class="cm-empty-sub">Hệ thống chưa có khóa học. Giáo viên hãy tạo khóa học đầu tiên!</div>
      </div>
    <% } else { %>
      <div class="course-grid" id="allCsGrid">
      <%

         for (CourseDTO _ac : allCourseList) {
           java.util.List<VideoDTO> _acVids = _videoSvc.getVideosByCourse(_ac.getId());
           int _acEnroll = _enrollSvc.countEnrollmentsByCourse(_ac.getId());
           boolean _acEnrolled = enrolledIds.contains(_ac.getId());
           String _acCat = _ac.getCategory() != null ? _ac.getCategory() : "General";
           String[] _acGrads = {"linear-gradient(135deg,#1e3a5f,#3b82f6)","linear-gradient(135deg,#064e3b,#10b981)","linear-gradient(135deg,#4c1d95,#7c3aed)","linear-gradient(135deg,#7c2d12,#ea580c)","linear-gradient(135deg,#1e1b4b,#4f46e5)"};
           String _acGrad = _acGrads[_ac.getId() % _acGrads.length];
           String _acThumb = null;
           if (!_acVids.isEmpty()) {
               String _acFp = _acVids.get(0).getFilePath();
               if (_acFp != null && !_acFp.isEmpty()) {
                   String _acYtId = null;
                   if (_acFp.contains("youtu.be/")) { String[] _p=_acFp.split("youtu\\.be/"); if(_p.length>1) _acYtId=_p[1].split("[?&]")[0]; }
                   else if (_acFp.contains("v="))    { String[] _p=_acFp.split("v=");          if(_p.length>1) _acYtId=_p[1].split("[?&]")[0]; }
                   else if (_acFp.contains("/embed/")){ String[] _p=_acFp.split("/embed/");    if(_p.length>1) _acYtId=_p[1].split("[?&/]")[0]; }
                   if (_acYtId != null && !_acYtId.isEmpty()) _acThumb = "https://img.youtube.com/vi/" + _acYtId + "/mqdefault.jpg";
               }
           }
           String _acTName = _ac.getTeacherName() != null ? _ac.getTeacherName().trim() : "Giáo viên";
           String[] _acAvColors = {"#4f46e5","#0891b2","#059669","#d97706","#dc2626","#7c3aed","#db2777"};
           String _acAvColor = _acAvColors[Math.abs(_acTName.hashCode()) % _acAvColors.length];
           String _acInit = _acTName.length() > 0 ? String.valueOf(_acTName.charAt(0)).toUpperCase() : "?";
      %>
        <div class="cc2-card" id="allcard-<%= _ac.getId() %>"
             data-name="<%= (_ac.getName()!=null?_ac.getName():"").toLowerCase() %>"
             data-cat="<%= _acCat %>"
             style="cursor:default;">
          <div class="cc2-banner" style="background:<%= _acGrad %>">
            <% if (_acEnrolled) { %>
              <div style="position:absolute;top:10px;right:10px;background:#10b981;color:#fff;font-size:10px;font-weight:700;padding:3px 8px;border-radius:999px;">✓ Đã đăng ký</div>
            <% } %>
            <% if (_acThumb != null) { %>
              <img src="<%= _acThumb %>" alt="<%= _ac.getName() %>" loading="lazy" onerror="this.style.display='none'"/>
            <% } else { %>
              <div class="cc2-banner-icon">📚</div>
            <% } %>
          </div>
          <div class="cc2-teacher-row">
            <div class="cc2-avatar" style="background:<%= _acAvColor %>"><%= _acInit %></div>
            <div class="cc2-teacher-info">
              <div class="cc2-teacher-name"><%= _acTName %></div>
              <div class="cc2-teacher-cat"><%= _acCat %></div>
            </div>
          </div>
          <div class="cc2-title"><%= _ac.getName() %></div>
          <div class="cc2-subtitle"><%= _acEnroll %> học viên đã đăng ký</div>
          <div class="cc2-footer">
            <span class="cc2-price">Miễn phí</span>
            <div class="cc2-footer-stats">
              <span class="cc2-stat"><span>👥</span> <%= _acEnroll %></span>
              <% if (_acVids.size() > 0) { %>
              <span class="cc2-stat cc2-stat-vid"><span>▶</span> <%= _acVids.size() %> bài</span>
              <% } %>
            </div>
          </div>
          <div style="padding:0 14px 14px;">
            <a href="<%= request.getContextPath() %>/classroom?courseId=<%= _ac.getId() %>"
               style="display:block;text-align:center;padding:9px 0;background:linear-gradient(135deg,#3b82f6,#1d4ed8);color:#fff;border-radius:10px;font-size:13px;font-weight:700;text-decoration:none;transition:opacity .15s;"
               onmouseover="this.style.opacity='.88'" onmouseout="this.style.opacity='1'">
              🎓 Vào học ngay →
            </a>
          </div>
        </div>
      <% } %>
      </div>
      <div class="cm-empty" id="allCsNoResults" style="display:none;">
        <div class="cm-empty-icon">🔍</div>
        <div class="cm-empty-title">Không tìm thấy khóa học</div>
      </div>
    <% } %>

    <script>
    function allCsFilter() {
      var kw  = (document.getElementById('allCsSearch').value || '').toLowerCase().trim();
      var cat = document.getElementById('allCsCatFilter').value;
      var cards = document.querySelectorAll('#allCsGrid .cc2-card');
      var shown = 0;
      cards.forEach(function(card){
        var name = card.getAttribute('data-name') || '';
        var cCat = card.getAttribute('data-cat') || '';
        var match = (!kw || name.indexOf(kw) !== -1) && (!cat || cCat === cat);
        card.style.display = match ? '' : 'none';
        if (match) shown++;
      });
      var noRes = document.getElementById('allCsNoResults');
      if (noRes) noRes.style.display = (shown === 0) ? 'flex' : 'none';
    }
    </script>

    <% } /* end tab courses */ %>

    <%-- ══ TAB: THÔNG BÁO GIÁO VIÊN (teacher notifications) ═══════════════ --%>
    <% if (activeTab.equals("notifications") && role.equals("teacher")) { %>

    <div style="display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:12px;margin-bottom:26px;">
      <div style="display:flex;align-items:center;gap:16px;">
        <div style="width:54px;height:54px;border-radius:16px;background:linear-gradient(135deg,#f59e0b,#d97706);display:flex;align-items:center;justify-content:center;font-size:26px;box-shadow:0 6px 18px rgba(245,158,11,.3);flex-shrink:0;">🔔</div>
        <div>
          <div style="font-size:22px;font-weight:800;color:#0f2744;letter-spacing:-.4px;">Trung tâm thông báo</div>
          <div style="font-size:13px;color:#64748b;margin-top:3px;">Bài nộp, đăng ký và tin nhắn hỗ trợ từ học sinh</div>
        </div>
      </div>
      <% if (teacherTotalNotif > 0) { %>
      <div style="display:flex;align-items:center;gap:8px;background:#fffbeb;border:1.5px solid #fde68a;border-radius:12px;padding:10px 18px;">
        <span style="font-size:16px;">🔔</span>
        <span style="font-size:13px;font-weight:700;color:#d97706;"><%= teacherTotalNotif %> thông báo chưa xử lý</span>
      </div>
      <% } %>
    </div>

    <!-- Summary stats -->
    <div style="display:grid;grid-template-columns:repeat(4,1fr);gap:14px;margin-bottom:22px;">
      <div style="background:#fff;border-radius:16px;padding:20px;box-shadow:0 2px 12px rgba(0,0,0,.06);border:1.5px solid #e2e8f0;position:relative;overflow:hidden;">
        <div style="position:absolute;top:0;left:0;right:0;height:3px;background:linear-gradient(90deg,#f59e0b,#d97706);"></div>
        <div style="font-size:28px;margin-bottom:6px;">📝</div>
        <div style="font-size:30px;font-weight:800;color:#0f2744;line-height:1;"><%= teacherPendingHw %></div>
        <div style="font-size:12px;color:#64748b;margin-top:5px;">Bài chờ chấm</div>
      </div>
      <div style="background:#fff;border-radius:16px;padding:20px;box-shadow:0 2px 12px rgba(0,0,0,.06);border:1.5px solid #e2e8f0;position:relative;overflow:hidden;">
        <div style="position:absolute;top:0;left:0;right:0;height:3px;background:linear-gradient(90deg,#10b981,#059669);"></div>
        <div style="font-size:28px;margin-bottom:6px;">🎓</div>
        <div style="font-size:30px;font-weight:800;color:#0f2744;line-height:1;"><%= teacherNewEnrolls %></div>
        <div style="font-size:12px;color:#64748b;margin-top:5px;">Đăng ký mới (7 ngày)</div>
      </div>
      <div style="background:#fff;border-radius:16px;padding:20px;box-shadow:0 2px 12px rgba(0,0,0,.06);border:1.5px solid #e2e8f0;position:relative;overflow:hidden;">
        <div style="position:absolute;top:0;left:0;right:0;height:3px;background:linear-gradient(90deg,#3b82f6,#1d4ed8);"></div>
        <div style="font-size:28px;margin-bottom:6px;">📚</div>
        <div style="font-size:30px;font-weight:800;color:#0f2744;line-height:1;"><%= courseList.size() %></div>
        <div style="font-size:12px;color:#64748b;margin-top:5px;">Khóa học của tôi</div>
      </div>
      <div style="background:#fff;border-radius:16px;padding:20px;box-shadow:0 2px 12px rgba(0,0,0,.06);border:1.5px solid #e2e8f0;position:relative;overflow:hidden;">
        <div style="position:absolute;top:0;left:0;right:0;height:3px;background:linear-gradient(90deg,#8b5cf6,#6d28d9);"></div>
        <div style="font-size:28px;margin-bottom:6px;">👥</div>
        <div style="font-size:30px;font-weight:800;color:#0f2744;line-height:1;"><%= totalStudents %></div>
        <div style="font-size:12px;color:#64748b;margin-top:5px;">Tổng học sinh</div>
      </div>
    </div>

    <%-- ── SECTION: นักเรียนสมัครเรียนใหม่ (7 วัน) ── --%>
    <%
      java.util.List<java.util.Map<String,Object>> recentEnrollList = new java.util.ArrayList<>();
      // BUG FIX: ใช้ recentEnroll ที่โหลดจาก _dd แล้ว (ไม่ได้อยู่ใน request attribute)
      // EnrollmentRepository.findRecentEnrollments() ดึงแค่ 5 รายการล่าสุด
      // แก้เป็น query ครบทุก enrollment ของครูใน 7 วัน
      com.example.demo.repository.EnrollmentRepository _enrollRepo =
          _wac.getBean(com.example.demo.repository.EnrollmentRepository.class);
      java.util.List<java.util.Map<String,Object>> _allRecentEnrolls = new java.util.ArrayList<>();
      for (Object[] _rr : _enrollRepo.findRecentEnrollmentsForTeacher(user.getId(), 7)) {
          java.util.Map<String,Object> _rm = new java.util.LinkedHashMap<>();
          _rm.put("username",    _rr[0]);
          _rm.put("course",      _rr[1]);
          _rm.put("enrolled_at", _rr[2]);
          _allRecentEnrolls.add(_rm);
      }
    %>
    <div style="background:#fff;border-radius:20px;box-shadow:0 2px 14px rgba(0,0,0,.07);border:1.5px solid #e2e8f0;overflow:hidden;margin-bottom:20px;">
      <div style="padding:18px 22px;border-bottom:1.5px solid #f1f5f9;display:flex;align-items:center;gap:10px;background:linear-gradient(90deg,#f0fdf4,#f8fafc);">
        <span style="font-size:16px;">🎓</span>
        <span style="font-size:14px;font-weight:700;color:#0f2744;">Học sinh đăng ký khóa học gần đây</span>
        <% if (teacherNewEnrolls > 0) { %>
          <span style="background:#d1fae5;color:#065f46;font-size:11px;font-weight:700;padding:2px 8px;border-radius:999px;"><%= teacherNewEnrolls %> mới (7 ngày)</span>
        <% } %>
      </div>
      <%
        // BUG FIX: ใช้ _allRecentEnrolls ที่ query มาตรงๆ สำหรับครูคนนี้
        // ไม่ต้องกรองซ้ำเพราะ query กรองด้วย teacher_id แล้ว
        java.util.List<java.util.Map<String,Object>> teacherEnrollRows = _allRecentEnrolls;
      %>
      <% if (teacherEnrollRows.isEmpty()) { %>
        <div style="text-align:center;padding:40px 20px;">
          <div style="font-size:40px;margin-bottom:10px;">📭</div>
          <div style="font-size:14px;font-weight:600;color:#0f2744;margin-bottom:6px;">Chưa có học sinh đăng ký gần đây</div>
          <div style="font-size:12px;color:#94a3b8;">Khi học sinh đăng ký khóa học của bạn, thông tin sẽ hiển thị tại đây.</div>
        </div>
      <% } else { %>
        <div style="overflow-x:auto;">
          <table style="width:100%;border-collapse:collapse;font-size:13px;">
            <thead>
              <tr style="background:#f8fafc;font-size:11px;color:#64748b;text-transform:uppercase;letter-spacing:.5px;">
                <th style="padding:11px 18px;text-align:left;font-weight:700;">Học sinh</th>
                <th style="padding:11px 18px;text-align:left;font-weight:700;">Khóa học</th>
                <th style="padding:11px 18px;text-align:center;font-weight:700;">Ngày đăng ký</th>
              </tr>
            </thead>
            <tbody>
            <% for (java.util.Map<String,Object> _er : teacherEnrollRows) {
                 String _erUser   = _er.get("username")   != null ? _er.get("username").toString()   : "—";
                 String _erCourse = _er.get("course")     != null ? _er.get("course").toString()     : "—";
                 // BUG FIX: แปลง date อย่างปลอดภัย รองรับ String + Timestamp
                 String _erDate;
                 Object _erDateObj = _er.get("enrolled_at");
                 if (_erDateObj instanceof java.sql.Timestamp) {
                     _erDate = ((java.sql.Timestamp)_erDateObj).toLocalDateTime()
                               .format(java.time.format.DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm"));
                 } else if (_erDateObj != null && !_erDateObj.toString().isEmpty()) {
                     String _rawEr = _erDateObj.toString().replace("T"," ");
                     if (_rawEr.matches("\\d{4}-\\d{2}-\\d{2}.*")) {
                         String[] _dp = _rawEr.substring(0,10).split("-");
                         _erDate = _dp[2] + "/" + _dp[1] + "/" + _dp[0];
                         if (_rawEr.length() >= 16) _erDate += " " + _rawEr.substring(11,16);
                     } else { _erDate = _rawEr.length() > 16 ? _rawEr.substring(0,16) : _rawEr; }
                 } else { _erDate = "—"; }
            %>
              <tr style="border-top:1px solid #f1f5f9;" onmouseenter="this.style.background='#f0fdf4'" onmouseleave="this.style.background='transparent'">
                <td style="padding:12px 18px;">
                  <div style="display:flex;align-items:center;gap:8px;">
                    <div style="width:30px;height:30px;border-radius:8px;background:linear-gradient(135deg,#10b981,#059669);display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:800;color:#fff;flex-shrink:0;"><%= _erUser.substring(0,1).toUpperCase() %></div>
                    <span style="font-weight:600;color:#0f2744;"><%= _erUser %></span>
                  </div>
                </td>
                <td style="padding:12px 18px;"><span style="background:#d1fae5;color:#065f46;font-size:11px;font-weight:600;padding:3px 8px;border-radius:6px;"><%= _erCourse %></span></td>
                <td style="padding:12px 18px;text-align:center;font-size:12px;color:#64748b;"><%= _erDate %></td>
              </tr>
            <% } %>
            </tbody>
          </table>
        </div>
      <% } %>
    </div>

    <!-- Homework submissions list -->
    <div style="background:#fff;border-radius:20px;box-shadow:0 2px 14px rgba(0,0,0,.07);border:1.5px solid #e2e8f0;overflow:hidden;">
      <div style="padding:18px 22px;border-bottom:1.5px solid #f1f5f9;display:flex;align-items:center;gap:10px;background:linear-gradient(90deg,#fafbff,#f8fafc);">
        <span style="font-size:16px;">📋</span>
        <span style="font-size:14px;font-weight:700;color:#0f2744;">Danh sách bài nộp từ học sinh</span>
        <% if (teacherHwNotifs.size() > 0) { %>
          <span style="background:#fef3c7;color:#d97706;font-size:11px;font-weight:700;padding:2px 8px;border-radius:999px;"><%= teacherHwNotifs.size() %> bài</span>
        <% } %>
      </div>
      <% if (teacherHwNotifs.isEmpty()) { %>
        <div style="text-align:center;padding:60px 20px;">
          <div style="font-size:48px;margin-bottom:14px;">🎉</div>
          <div style="font-size:16px;font-weight:700;color:#0f2744;margin-bottom:8px;">Chưa có bài nộp!</div>
          <div style="font-size:13px;color:#64748b;">Khi học sinh nộp bài tập, chúng sẽ hiển thị tại đây.</div>
        </div>
      <% } else { %>
        <div style="overflow-x:auto;">
          <table style="width:100%;border-collapse:collapse;font-size:13px;">
            <thead>
              <tr style="background:#f8fafc;font-size:11px;color:#64748b;text-transform:uppercase;letter-spacing:.5px;">
                <th style="padding:11px 18px;text-align:left;font-weight:700;">#</th>
                <th style="padding:11px 18px;text-align:left;font-weight:700;">Học sinh</th>
                <th style="padding:11px 18px;text-align:left;font-weight:700;">Tiêu đề bài nộp</th>
                <th style="padding:11px 18px;text-align:left;font-weight:700;">Khóa học</th>
                <th style="padding:11px 18px;text-align:center;font-weight:700;">Ngày nộp</th>
                <th style="padding:11px 18px;text-align:center;font-weight:700;">File</th>
                <th style="padding:11px 18px;text-align:center;font-weight:700;">Trạng thái</th>
              </tr>
            </thead>
            <tbody>
            <%
              int _hwIdx = 0;
              java.util.Map<Integer,String> _cNameMap = new java.util.HashMap<Integer,String>();
              for (CourseDTO _cx : courseList) { _cNameMap.put(_cx.getId(), _cx.getName()); }
              for (HomeworkDTO _nhw : teacherHwNotifs) {
                _hwIdx++;
                String _hwDate = "—";
                if (_nhw.getSubmittedAt() != null && _nhw.getSubmittedAt().length() >= 10) {
                    String _rawHw = _nhw.getSubmittedAt();
                    // Format: "2026-06-01T15:30:00" or "2026-06-01 15:30:00"
                    try {
                        java.time.LocalDateTime _hwLdt = java.time.LocalDateTime.parse(
                            _rawHw.replace(" ","T").length() >= 19 ? _rawHw.replace(" ","T").substring(0,19) : _rawHw.replace(" ","T"),
                            java.time.format.DateTimeFormatter.ISO_LOCAL_DATE_TIME);
                        _hwDate = _hwLdt.format(java.time.format.DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm"));
                    } catch (Exception _ex) {
                        String[] _dp = _rawHw.substring(0,10).split("-");
                        _hwDate = _dp.length == 3 ? _dp[2]+"/"+_dp[1]+"/"+_dp[0] : _rawHw.substring(0,10);
                        if (_rawHw.length() >= 16) _hwDate += " " + _rawHw.substring(11,16).replace("T","");
                    }
                }
                String _hwCourseName = _cNameMap.getOrDefault(_nhw.getCourseId(), "Khóa học #" + _nhw.getCourseId());
                if (_hwCourseName.length() > 25) _hwCourseName = _hwCourseName.substring(0,25) + "…";
                String _hwStatus = _nhw.getStatus() != null ? _nhw.getStatus() : "PENDING";
                boolean _hwReviewed = "REVIEWED".equalsIgnoreCase(_hwStatus);
            %>
            <tr style="border-top:1px solid #f1f5f9;transition:background .12s;" onmouseenter="this.style.background='#f8fafc'" onmouseleave="this.style.background='transparent'">
              <td style="padding:12px 18px;"><span style="font-size:12px;color:#94a3b8;">#<%= _hwIdx %></span></td>
              <td style="padding:12px 18px;">
                <div style="display:flex;align-items:center;gap:8px;">
                  <div style="width:30px;height:30px;border-radius:8px;background:linear-gradient(135deg,#6366f1,#8b5cf6);display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:800;color:#fff;flex-shrink:0;">
                    <%= _nhw.getStudentName() != null && !_nhw.getStudentName().trim().isEmpty() ? _nhw.getStudentName().trim().substring(0,1).toUpperCase() : "?" %>
                  </div>
                  <span style="font-weight:600;color:#0f2744;"><%= _nhw.getStudentName() != null ? _nhw.getStudentName() : "Học sinh #" + _nhw.getStudentId() %></span>
                </div>
              </td>
              <td style="padding:12px 18px;"><span style="font-weight:600;color:#1e293b;"><%= _nhw.getTitle() != null ? _nhw.getTitle() : "—" %></span></td>
              <td style="padding:12px 18px;"><span style="background:#eff6ff;color:#1d4ed8;font-size:11px;font-weight:600;padding:3px 8px;border-radius:6px;"><%= _hwCourseName %></span></td>
              <td style="padding:12px 18px;text-align:center;font-size:12px;color:#64748b;"><%= _hwDate %></td>
              <td style="padding:12px 18px;text-align:center;">
                <% if (_nhw.getFileName() != null && !_nhw.getFileName().isEmpty()) { %>
                  <a href="<%= request.getContextPath() %>/<%= _nhw.getFilePath() != null ? _nhw.getFilePath() : "" %>" target="_blank"
                     style="display:inline-flex;align-items:center;gap:4px;background:#f0fdf4;color:#059669;font-size:11px;font-weight:600;padding:4px 10px;border-radius:7px;text-decoration:none;border:1px solid #6ee7b7;"
                     onmouseover="this.style.background='#d1fae5'" onmouseout="this.style.background='#f0fdf4'">
                    📥 Tải xuống
                  </a>
                <% } else { %>
                  <span style="font-size:12px;color:#94a3b8;">Không có file</span>
                <% } %>
              </td>
              <td style="padding:12px 18px;text-align:center;">
                <span style="font-size:11px;font-weight:700;padding:4px 10px;border-radius:999px;background:<%= _hwReviewed ? "#d1fae5" : "#fef3c7" %>;color:<%= _hwReviewed ? "#065f46" : "#d97706" %>;">
                  <%= _hwReviewed ? "✓ Đã xem" : "⏳ Chờ xem" %>
                </span>
              </td>
            </tr>
            <% } %>
            </tbody>
          </table>
        </div>
      <% } %>
    </div>

    <% } /* end tab notifications */ %>


    <%-- ══════════════════════════════════════════════════════════════
         TAB: TEACHER APPROVAL — REDESIGNED
    ══════════════════════════════════════════════════════════════ --%>
    <% if (activeTab.equals("approval") && (role.equals("admin") || role.equals("super_admin"))) { %>
    <%
        String approvalErr = request.getParameter("approvalErr");
        String approvalOk  = request.getParameter("success");
    %>
    <% if (approvalErr != null && !approvalErr.isEmpty()) { %>
    <script>document.addEventListener('DOMContentLoaded',function(){ showNotifyModal('error','⚠️ Lỗi','<%= approvalErr.replace("'","\\'") %>'); });</script>
    <% } %>
    <% if (approvalOk != null && !approvalOk.isEmpty()) { %>
    <script>document.addEventListener('DOMContentLoaded',function(){ showNotifyModal('success','✅ Thành công','<%= approvalOk.replace("'","\\'") %>'); });</script>
    <% } %>

    <!-- Page Header -->
    <div class="apv-pg-hdr">
      <div class="apv-pg-left">
        <div class="apv-pg-icon">🔔</div>
        <div>
          <div class="apv-pg-title">Trung tâm thông báo</div>
          <div class="apv-pg-sub">Quản lý yêu cầu phê duyệt giáo viên và thông báo hệ thống</div>
        </div>
      </div>
      <% if (pendingCount > 0) { %>
      <div style="display:flex;align-items:center;gap:8px;background:#fffbeb;border:1.5px solid #fde68a;border-radius:12px;padding:10px 18px;">
        <span style="font-size:16px;">⏳</span>
        <span style="font-size:13px;font-weight:700;color:#d97706;font-family:'Sora',sans-serif;"><%= pendingCount %> yêu cầu đang chờ xử lý</span>
      </div>
      <% } %>
    </div>

    <!-- Summary Cards -->
    <div class="apv-stat-row">
      <div class="apv-stat-card">
        <div class="apv-stat-icon" style="background:linear-gradient(135deg,#fffbeb,#fef3c7);">⏳</div>
        <div>
          <div class="apv-stat-val"><%= pendingTeachers.size() %></div>
          <div class="apv-stat-lbl">Chờ phê duyệt</div>
        </div>
      </div>
      <div class="apv-stat-card">
        <div class="apv-stat-icon" style="background:linear-gradient(135deg,#d1fae5,#a7f3d0);">👨‍🏫</div>
        <div>
          <div class="apv-stat-val"><%= teacherList.size() %></div>
          <div class="apv-stat-lbl">Giáo viên hoạt động</div>
        </div>
      </div>
      <div class="apv-stat-card">
        <div class="apv-stat-icon" style="background:linear-gradient(135deg,#ede9fe,#ddd6fe);">👥</div>
        <div>
          <div class="apv-stat-val"><%= totalStudents %></div>
          <div class="apv-stat-lbl">Tổng học viên</div>
        </div>
      </div>
      <div class="apv-stat-card">
        <div class="apv-stat-icon" style="background:linear-gradient(135deg,#dbeafe,#bfdbfe);">📚</div>
        <div>
          <div class="apv-stat-val"><%= totalCourses %></div>
          <div class="apv-stat-lbl">Tổng khóa học</div>
        </div>
      </div>
    </div>

    <!-- Pending Teachers Panel -->
    <div class="apv-panel">
      <div class="apv-panel-head">
        <div class="apv-panel-head-left">
          <span style="font-size:18px;">✅</span>
          <span class="apv-panel-title">Phê duyệt đăng ký giáo viên</span>
          <% if (!pendingTeachers.isEmpty()) { %>
            <span class="apv-pill apv-pill-pending"><%= pendingTeachers.size() %> đang chờ</span>
          <% } else { %>
            <span class="apv-pill apv-pill-done">Đã xử lý hết</span>
          <% } %>
        </div>
      </div>

      <% if (pendingTeachers.isEmpty()) { %>
        <div class="apv-empty">
          <div class="apv-empty-icon">🎉</div>
          <div class="apv-empty-title">Không có yêu cầu chờ phê duyệt!</div>
          <div class="apv-empty-sub">Tất cả yêu cầu đã được xử lý. Giáo viên mới đăng ký sẽ hiển thị tại đây.</div>
        </div>
      <% } else { %>
        <div>
          <% for (UserDTO t : pendingTeachers) { %>
          <div class="apv-teacher-row">
            <div class="apv-teacher-av"><%= t.getUsername().substring(0,1).toUpperCase() %></div>
            <div class="apv-teacher-info">
              <div>
                <span class="apv-teacher-name"><%= t.getFirstName() != null ? t.getFirstName() : "" %> <%= t.getLastName() != null ? t.getLastName() : "" %></span>
                <span class="apv-teacher-handle">@<%= t.getUsername() %></span>
              </div>
              <div class="apv-teacher-meta">
                <span class="apv-teacher-email">📧 <%= t.getEmail() != null ? t.getEmail() : "—" %></span>
                <span class="apv-status-pending">⏳ Chờ phê duyệt</span>
              </div>
            </div>
            <div class="apv-actions">
              <button type="button" class="apv-btn-approve" onclick="showApprovalModal('approve','<%= t.getId() %>','<%= t.getUsername() %>')">✓ Phê duyệt</button>
              <button type="button" class="apv-btn-reject" onclick="showApprovalModal('reject','<%= t.getId() %>','<%= t.getUsername() %>')">✕ Từ chối</button>
            </div>
          </div>
          <% } %>
        </div>
      <% } %>
    </div>

    <!-- System Notifications Panel -->
    <div class="apv-panel">
      <div class="apv-panel-head">
        <div class="apv-panel-head-left">
          <span style="font-size:18px;">📋</span>
          <span class="apv-panel-title">Thông báo hệ thống</span>
          <span class="apv-tag-today">Hôm nay</span>
        </div>
      </div>

      <%-- ── คำเตือน pending teachers (สำคัญที่สุด อยู่บนสุด) ── --%>
      <% if (pendingCount > 0) { %>
      <div class="apv-notif-row" style="background:#fffbeb;border-left:4px solid #f59e0b;">
        <div class="apv-notif-icon" style="background:linear-gradient(135deg,#fef3c7,#fde68a);">⚠️</div>
        <div class="apv-notif-body">
          <div class="apv-notif-title" style="color:#d97706;"><%= pendingCount %> giáo viên đang chờ phê duyệt tài khoản</div>
          <div class="apv-notif-sub">Vui lòng xem xét và xử lý các yêu cầu ở mục bên trên.</div>
        </div>
        <div class="apv-notif-time"><span class="apv-tag-warn">⚡ Cần xử lý</span></div>
      </div>
      <% } %>

      <%-- ── สถิติภาพรวม ── --%>
      <div class="apv-notif-row">
        <div class="apv-notif-icon" style="background:linear-gradient(135deg,#ede9fe,#ddd6fe);">📚</div>
        <div class="apv-notif-body">
          <div class="apv-notif-title">Tổng quan hệ thống: Tổng số <span style="color:#5b4af7;font-weight:800;"><%= totalEnrollments %></span> lượt đăng ký &nbsp;·&nbsp; <%= newCoursesMonth %> khóa học mới trong tháng này</div>
          <div class="apv-notif-sub">Tổng số khóa học: <strong><%= totalCourses %></strong> &nbsp;·&nbsp; Giảng viên: <strong><%= totalTeachers %></strong> &nbsp;·&nbsp; Học viên: <strong><%= totalStudents %></strong></div>
        </div>
        <div class="apv-notif-time"><span class="apv-tag-today">Trực tiếp</span></div>
      </div>

      <%-- ── นักเรียนใหม่วันนี้ ── --%>
      <div class="apv-notif-row"<% if (newStudentsToday > 0) { %> style="background:#f0fdf4;"<% } %>>
        <div class="apv-notif-icon" style="background:linear-gradient(135deg,#d1fae5,#a7f3d0);">👤</div>
        <div class="apv-notif-body">
          <% if (newStudentsToday > 0) { %>
          <div class="apv-notif-title" style="color:#059669;">🎉 Có <strong><%= newStudentsToday %></strong> học viên mới đăng ký hôm nay!</div>
          <% } else { %>
          <div class="apv-notif-title">Hôm nay chưa có học viên mới</div>
          <% } %>
          <div class="apv-notif-sub">Tổng số học viên trong hệ thống: <strong><%= totalStudents %></strong> người</div>
        </div>
        <div class="apv-notif-time"><span class="apv-tag-today">Hôm nay</span></div>
      </div>

      <%-- ── การลงทะเบียนล่าสุด ── --%>
      <% if (!recentEnroll.isEmpty()) { %>
      <div style="padding:12px 18px 4px;">
        <div style="font-size:12px;font-weight:700;color:#64748b;text-transform:uppercase;letter-spacing:.5px;margin-bottom:8px;">📝 Đăng ký gần đây</div>
        <% int _rCount = 0; for (java.util.Map<String,Object> _re : recentEnroll) { if (_rCount++ >= 5) break;
             // BUG FIX: แปลง enrolled_at เป็น string อย่างปลอดภัย
             // ป้องกัน Timestamp.toString() ที่อาจคืนปีผิด
             Object _rDateObj = _re.get("enrolled_at");
             String _rDate = "—";
             if (_rDateObj instanceof java.sql.Timestamp) {
                 _rDate = ((java.sql.Timestamp)_rDateObj).toLocalDateTime()
                          .format(java.time.format.DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm"));
             } else if (_rDateObj != null && !_rDateObj.toString().isEmpty()) {
                 String _rawR = _rDateObj.toString().replace("T"," ");
                 if (_rawR.matches("\\d{4}-\\d{2}-\\d{2}.*")) {
                     String[] _dp = _rawR.substring(0,10).split("-");
                     _rDate = _dp[2] + "/" + _dp[1] + "/" + _dp[0];
                     if (_rawR.length() >= 16) _rDate += " " + _rawR.substring(11,16);
                 } else { _rDate = _rawR.length() > 0 ? _rawR : "—"; }
             }
             String _rCourse = _re.get("course") != null ? _re.get("course").toString() : "";
             if (_rCourse.length() > 30) _rCourse = _rCourse.substring(0,30) + "…";
        %>
        <div class="apv-notif-row" style="padding:8px 0;border-left:none;margin:0;">
          <div class="apv-notif-icon" style="background:#eff6ff;font-size:14px;width:32px;height:32px;min-width:32px;border-radius:8px;">📖</div>
          <div class="apv-notif-body">
            <div class="apv-notif-title" style="font-size:13px;">👤 <strong><%= _re.get("username") %></strong> đã đăng ký <span style="color:#3b82f6;"><%= _rCourse %></span></div>
          </div>
          <div class="apv-notif-time" style="font-size:11px;color:#94a3b8;white-space:nowrap;"><%= _rDate %></div>
        </div>
        <% } %>
      </div>
      <% } %>

      <%-- ══ ส่วน: ห้องเรียนใหม่ที่ครูสร้างล่าสุด ══ --%>
      <%
        com.example.demo.repository.CourseRepository _courseRepoApv =
            _wac.getBean(com.example.demo.repository.CourseRepository.class);
        java.util.List<Object[]> _recentCourseRows = _courseRepoApv.findRecentCoursesWithTeacher(7);
        long _newCoursesWeekApv = _courseRepoApv.countNewCoursesInDays(7);
      %>
      <div style="padding:14px 18px 6px;border-top:1px solid #f1f5f9;">
        <div style="font-size:12px;font-weight:700;color:#64748b;text-transform:uppercase;letter-spacing:.5px;margin-bottom:10px;display:flex;align-items:center;gap:8px;">
          🏫 ห้องเรียนที่ครูสร้างล่าสุด
          <% if (_newCoursesWeekApv > 0) { %>
            <span style="background:#dbeafe;color:#1d4ed8;font-size:11px;font-weight:700;padding:2px 8px;border-radius:999px;"><%= _newCoursesWeekApv %> ใหม่ (7 วัน)</span>
          <% } %>
        </div>
        <% if (_recentCourseRows.isEmpty()) { %>
          <div style="text-align:center;padding:20px;color:#94a3b8;font-size:13px;">ยังไม่มีห้องเรียนในระบบ</div>
        <% } else {
             for (Object[] _cr : _recentCourseRows) {
               // cols: id, name, category, created_at, teacher_username, teacher_fullname
               String _crName      = _cr[1] != null ? _cr[1].toString() : "—";
               String _crCategory  = _cr[2] != null ? _cr[2].toString() : "";
               String _crTeacherU  = _cr[4] != null ? _cr[4].toString() : "—";
               String _crTeacherFN = _cr[5] != null && !_cr[5].toString().isEmpty() ? _cr[5].toString() : _crTeacherU;
               String _crDate = "—";
               Object _crDateObj = _cr[3];
               if (_crDateObj instanceof java.sql.Timestamp) {
                   _crDate = ((java.sql.Timestamp)_crDateObj).toLocalDateTime()
                             .format(java.time.format.DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm"));
               } else if (_crDateObj instanceof java.time.LocalDateTime) {
                   _crDate = ((java.time.LocalDateTime)_crDateObj)
                             .format(java.time.format.DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm"));
               } else if (_crDateObj != null && !_crDateObj.toString().isEmpty()) {
                   String _crRaw = _crDateObj.toString().replace("T"," ");
                   String[] _dp = _crRaw.substring(0,10).split("-");
                   _crDate = (_dp.length == 3 ? _dp[2]+"/"+_dp[1]+"/"+_dp[0] : _crRaw.substring(0,10));
                   if (_crRaw.length() >= 16) _crDate += " " + _crRaw.substring(11,16);
               }
               if (_crName.length() > 35) _crName = _crName.substring(0,35) + "…";
               if (_crTeacherFN.length() > 25) _crTeacherFN = _crTeacherFN.substring(0,25) + "…";
               // ตรวจว่าใหม่ใน 7 วันไหม
               boolean _crIsNew = false;
               try {
                   java.time.LocalDateTime _crLdt = null;
                   if (_crDateObj instanceof java.sql.Timestamp) {
                       _crLdt = ((java.sql.Timestamp)_crDateObj).toLocalDateTime();
                   } else if (_crDateObj instanceof java.time.LocalDateTime) {
                       _crLdt = (java.time.LocalDateTime)_crDateObj;
                   }
                   if (_crLdt != null) _crIsNew = _crLdt.isAfter(java.time.LocalDateTime.now().minusDays(7));
               } catch (Exception _ign) {}
        %>
        <div class="apv-notif-row" style="padding:8px 0;border-left:none;margin:0;border-bottom:1px solid #f8fafc;align-items:center;">
          <div class="apv-notif-icon" style="background:linear-gradient(135deg,#dbeafe,#bfdbfe);font-size:16px;width:36px;height:36px;min-width:36px;border-radius:10px;display:flex;align-items:center;justify-content:center;">
            🏫
          </div>
          <div class="apv-notif-body">
            <div class="apv-notif-title" style="font-size:13px;">
              <strong style="color:#0f2744;"><%= _crName %></strong>
              <% if (!_crCategory.isEmpty()) { %>
                <span style="background:#f1f5f9;color:#475569;font-size:10px;font-weight:600;padding:1px 6px;border-radius:4px;margin-left:4px;"><%= _crCategory %></span>
              <% } %>
              <% if (_crIsNew) { %>
                <span style="background:#d1fae5;color:#065f46;font-size:10px;font-weight:700;padding:1px 6px;border-radius:4px;margin-left:4px;">✨ ใหม่</span>
              <% } %>
            </div>
            <div class="apv-notif-sub" style="margin-top:3px;">
              👨‍🏫 สร้างโดย <strong><%= _crTeacherFN %></strong>
              <span style="color:#94a3b8;margin-left:4px;">@<%= _crTeacherU %></span>
            </div>
          </div>
          <div class="apv-notif-time" style="font-size:11px;color:#94a3b8;white-space:nowrap;padding-top:2px;"><%= _crDate %></div>
        </div>
        <% } } %>
      </div>

      <%-- ── สถานะระบบ ── --%>
      <div class="apv-notif-row" style="background:#f0fdf4;border-top:1px solid #d1fae5;">
        <div class="apv-notif-icon" style="background:linear-gradient(135deg,#d1fae5,#a7f3d0);">✅</div>
        <div class="apv-notif-body">
          <div class="apv-notif-title" style="color:#059669;">Hệ thống hoạt động bình thường</div>
          <div class="apv-notif-sub">Không có lỗi cần thông báo. Trang này tải dữ liệu trực tiếp từ Database mỗi khi mở.</div>
        </div>
        <div class="apv-notif-time"><span class="apv-tag-done">✓ Bình thường</span></div>
      </div>
    </div>

    <% } /* end tab approval */ %>

    <%-- ══ TAB: THÔNG TIN CÁ NHÂN (PROFILE) — REDESIGNED ═══════════════ --%>
    <% if (activeTab.equals("profile")) { %>

    <!-- Toast: อัปโหลดรูป / อัปเดตโปรไฟล์ สำเร็จ -->
    <% if (_showPhotoToast || _showProfileToast) { %>
    <div id="pfToast" style="position:fixed;bottom:28px;right:28px;z-index:9999;background:#0f2744;color:#fff;padding:14px 22px;border-radius:14px;font-size:14px;font-weight:700;box-shadow:0 8px 30px rgba(0,0,0,.22);display:flex;align-items:center;gap:10px;animation:slideInRight .3s ease;">
      <span style="font-size:20px;"><%= _showPhotoToast ? "🖼️" : "✅" %></span>
      <%= _showPhotoToast ? "Cập nhật ảnh đại diện thành công!" : "Lưu thông tin thành công!" %>
    </div>
    <script>setTimeout(function(){ var t=document.getElementById('pfToast'); if(t){ t.style.transition='opacity .4s'; t.style.opacity='0'; setTimeout(function(){ t.style.display='none'; },400); } }, 2800);</script>
    <% } %>

    <!-- Page Header -->
    <div class="profile-pg-hdr">
      <div class="profile-pg-icon">👤</div>
      <div>
        <div class="profile-pg-title">Thông tin cá nhân</div>
        <div class="profile-pg-sub">Xem và quản lý thông tin tài khoản của bạn</div>
      </div>
    </div>

    <div class="profile-layout">

      <!-- ══ LEFT: Avatar Card ══ -->
      <div class="pf-avatar-card">
        <div class="pf-av-banner"></div>
        <div class="pf-av-body">
          <%
            String _dashPhotoPath = user.getProfilePhoto();
            String _dashPhotoUrl  = (_dashPhotoPath != null && !_dashPhotoPath.trim().isEmpty())
                ? request.getContextPath() + "/uploads/" + _dashPhotoPath
                : null;
            String _dashInit = "";
            if (user.getFirstName() != null && !user.getFirstName().isEmpty()) _dashInit += user.getFirstName().charAt(0);
            if (user.getLastName()  != null && !user.getLastName().isEmpty())  _dashInit += user.getLastName().charAt(0);
            if (_dashInit.isEmpty()) _dashInit = user.getUsername().substring(0,1).toUpperCase();
          %>
          <% if (_dashPhotoUrl != null) { %>
          <img src="<%= _dashPhotoUrl %>" alt="Ảnh đại diện"
               class="pf-av-circle"
               style="object-fit:cover;cursor:pointer;"
               onclick="document.getElementById('dash-photo-input').click()"
               title="Nhấn để đổi ảnh đại diện">
          <% } else { %>
          <div class="pf-av-circle" onclick="document.getElementById('dash-photo-input').click()"
               style="cursor:pointer;" title="Nhấn để tải ảnh đại diện">
            <%= _dashInit.toUpperCase() %>
          </div>
          <% } %>
          <!-- Upload form ẩn -->
          <form id="dash-photo-form" action="<%= request.getContextPath() %>/profile/photo"
                method="post" enctype="multipart/form-data" style="display:none;">
            <input type="hidden" name="redirectTo" value="/dashboard?tab=profile&photoToast=1">
            <input type="file" id="dash-photo-input" name="photo" accept="image/*"
                   onchange="document.getElementById('dash-photo-form').submit()">
          </form>
          <!-- Nút đổi ảnh -->
          <button onclick="document.getElementById('dash-photo-input').click()"
                  style="margin-top:8px;background:#f0f7ff;border:1.5px dashed #93c5fd;color:#1d4ed8;padding:7px 16px;border-radius:9px;font-size:12px;font-weight:700;cursor:pointer;font-family:'Nunito',sans-serif;transition:.2s;"
                  onmouseover="this.style.background='#dbeafe'" onmouseout="this.style.background='#f0f7ff'">
            📷 Đổi ảnh đại diện
          </button>
          <div style="font-size:10px;color:#94a3b8;margin-top:3px;">JPG, PNG · Tối đa 2MB</div>
          <div class="pf-fullname"><%= user.getFullName() != null && !user.getFullName().trim().isEmpty() ? user.getFullName() : user.getUsername() %></div>
          <div class="pf-username">@<%= user.getUsername() %></div>
          <div class="pf-role-badge" style="background:<%= role.equals("super_admin") ? "#fffbeb" : role.equals("admin") ? "#ede9fe" : role.equals("teacher") ? "#d1fae5" : "#dbeafe" %>;color:<%= role.equals("super_admin") ? "#d97706" : role.equals("admin") ? "#6d28d9" : role.equals("teacher") ? "#065f46" : "#1d4ed8" %>;border-color:<%= role.equals("super_admin") ? "#fde68a" : role.equals("admin") ? "#c4b5fd" : role.equals("teacher") ? "#6ee7b7" : "#93c5fd" %>;">
            <%= role.equals("super_admin") ? "👑 Super Admin" : role.equals("admin") ? "🛡️ Admin" : role.equals("teacher") ? "👨‍🏫 Giáo viên" : "🎓 Học viên" %>
          </div>
          <div class="pf-status">
            <div class="pf-status-dot" style="background:<%= "ACTIVE".equalsIgnoreCase(user.getStatus()) ? "#059669" : "#ef4444" %>;"></div>
            <span class="pf-status-text"><%= "ACTIVE".equalsIgnoreCase(user.getStatus()) ? "Đang hoạt động" : "Không hoạt động" %></span>
          </div>
          <hr class="pf-divider">
          <div class="pf-stats-grid">
            <div class="pf-stat-cell">
              <div class="pf-stat-val">#<%= user.getId() %></div>
              <div class="pf-stat-lbl">User ID</div>
            </div>
            <div class="pf-stat-cell">
              <div class="pf-stat-val accent"><%= role.equals("super_admin") ? "SA" : role.equals("admin") ? "AD" : role.equals("teacher") ? "TC" : "SV" %></div>
              <div class="pf-stat-lbl">Role</div>
            </div>
          </div>
          <%-- แสดงจำนวนคอร์สที่สมัครเรียน (เฉพาะ teacher — นับคอร์สตัวเอง; admin/super_admin — นับทั้งหมด) --%>
          <%
            int _pfEnrolledCount = 0;
            if (role.equals("teacher")) {
                _pfEnrolledCount = courseList.size();
            } else if (role.equals("admin") || role.equals("super_admin")) {
                _pfEnrolledCount = allCourseList.size();
            }
          %>
          <div style="margin-top:14px;background:#f8fafc;border-radius:12px;padding:14px 16px;border:1.5px solid #e2e8f0;">
            <div style="font-size:11px;color:#94a3b8;text-transform:uppercase;letter-spacing:.5px;margin-bottom:8px;font-weight:600;">📊 Thống kê</div>
            <% if (role.equals("teacher")) { %>
            <div style="display:flex;justify-content:space-between;align-items:center;padding:6px 0;border-bottom:1px solid #e2e8f0;">
              <span style="font-size:12px;color:#64748b;">Khóa học của tôi</span>
              <span style="font-size:14px;font-weight:800;color:#0f2744;"><%= _pfEnrolledCount %></span>
            </div>
            <div style="display:flex;justify-content:space-between;align-items:center;padding:6px 0;">
              <span style="font-size:12px;color:#64748b;">Bài chờ chấm</span>
              <span style="font-size:14px;font-weight:800;color:<%= teacherPendingHw > 0 ? "#ef4444" : "#059669" %>;"><%= teacherPendingHw %></span>
            </div>
            <% } else { %>
            <div style="display:flex;justify-content:space-between;align-items:center;padding:6px 0;border-bottom:1px solid #e2e8f0;">
              <span style="font-size:12px;color:#64748b;">Tổng khóa học</span>
              <span style="font-size:14px;font-weight:800;color:#0f2744;"><%= _pfEnrolledCount %></span>
            </div>
            <div style="display:flex;justify-content:space-between;align-items:center;padding:6px 0;">
              <span style="font-size:12px;color:#64748b;">Tổng học sinh</span>
              <span style="font-size:14px;font-weight:800;color:#0f2744;"><%= totalStudents %></span>
            </div>
            <% } %>
          </div>
        </div>
      </div>

      <!-- ══ RIGHT: Info + Actions ══ -->
      <div class="pf-info-col">

        <!-- Account Info Card -->
        <div class="pf-card">
          <div class="pf-card-head">
            <div class="pf-card-head-icon" style="background:#eef2ff;">📋</div>
            <span class="pf-card-head-title">Thông tin tài khoản</span>
          </div>
          <div class="pf-card-body">
            <div class="pf-fields-grid">
              <div>
                <div class="pf-field-label">Tên đăng nhập</div>
                <div class="pf-field-val"><span class="pf-field-icon">👤</span><%= user.getUsername() %></div>
              </div>
              <div>
                <div class="pf-field-label">Email</div>
                <div class="pf-field-val" style="overflow:hidden;"><span class="pf-field-icon">📧</span><span style="white-space:nowrap;overflow:hidden;text-overflow:ellipsis;"><%= user.getEmail() != null && !user.getEmail().isEmpty() ? user.getEmail() : "Chưa cập nhật" %></span></div>
              </div>
              <div>
                <div class="pf-field-label">Họ</div>
                <div class="pf-field-val"><%= user.getFirstName() != null && !user.getFirstName().isEmpty() ? user.getFirstName() : "Chưa cập nhật" %></div>
              </div>
              <div>
                <div class="pf-field-label">Tên</div>
                <div class="pf-field-val"><%= user.getLastName() != null && !user.getLastName().isEmpty() ? user.getLastName() : "Chưa cập nhật" %></div>
              </div>
            </div>
          </div>
        </div>

        <!-- Quick Actions Card -->
        <div class="pf-card">
          <div class="pf-card-head">
            <div class="pf-card-head-icon" style="background:#f0fdf4;">⚡</div>
            <span class="pf-card-head-title">Thao tác nhanh</span>
          </div>
          <div class="pf-card-body">
            <div class="pf-actions-row">
              <a href="dashboard?tab=security" class="pf-btn-primary">🔐 Đổi mật khẩu</a>
              <a href="dashboard?tab=contact" class="pf-btn-outline">📞 Liên hệ hỗ trợ</a>
              <a href="dashboard" class="pf-btn-ghost">🏠 Trang chủ</a>
            </div>
          </div>
        </div>

        <%-- ══ TEACHER ONLY: Student Review Section ══ --%>
        <% if (role.equals("teacher")) {
            @SuppressWarnings("unchecked")
            List<TeacherReviewDTO> _teacherReviews = (List<TeacherReviewDTO>) request.getAttribute("teacherReviews");
            double _avgRating   = request.getAttribute("teacherAvgRating")   != null ? (double) request.getAttribute("teacherAvgRating")   : 0.0;
            long   _reviewCount = request.getAttribute("teacherReviewCount")  != null ? (long)   request.getAttribute("teacherReviewCount")  : 0L;
            if (_teacherReviews == null) _teacherReviews = new java.util.ArrayList<>();
        %>
        <div class="pf-card" style="margin-top:0;">
          <div class="pf-card-head">
            <div class="pf-card-head-icon" style="background:#fffbeb;">⭐</div>
            <span class="pf-card-head-title">Đánh giá từ học sinh</span>
          </div>
          <div class="pf-card-body">
            <!-- Summary row -->
            <div style="display:flex;align-items:center;gap:18px;background:#f8fafc;border-radius:12px;padding:14px 18px;margin-bottom:16px;border:1.5px solid #e2e8f0;">
              <div style="text-align:center;">
                <div style="font-size:36px;font-weight:900;color:#d97706;line-height:1;"><%= String.format("%.1f", _avgRating) %></div>
                <div style="font-size:11px;color:#94a3b8;margin-top:2px;">/ 5.0</div>
              </div>
              <div style="flex:1;">
                <!-- Star bar -->
                <div style="display:flex;gap:3px;margin-bottom:6px;">
                  <% for (int _s = 1; _s <= 5; _s++) { %>
                  <span style="font-size:20px;color:<%= _s <= Math.round(_avgRating) ? "#f59e0b" : "#e2e8f0" %>;">★</span>
                  <% } %>
                </div>
                <div style="font-size:12px;color:#64748b;">จาก <strong style="color:#0f2744;"><%= _reviewCount %></strong> đánh giá</div>
              </div>
            </div>

            <!-- Review list -->
            <% if (_teacherReviews.isEmpty()) { %>
            <div style="text-align:center;padding:28px 0;color:#94a3b8;">
              <div style="font-size:32px;margin-bottom:8px;">📭</div>
              <div style="font-size:13px;">Chưa có đánh giá nào từ học sinh</div>
            </div>
            <% } else { %>
            <div style="display:flex;flex-direction:column;gap:10px;max-height:340px;overflow-y:auto;padding-right:4px;">
              <% for (TeacherReviewDTO _rv : _teacherReviews) { %>
              <div style="background:#fff;border:1.5px solid #e2e8f0;border-radius:12px;padding:12px 14px;">
                <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:6px;">
                  <div style="display:flex;align-items:center;gap:8px;">
                    <div style="width:30px;height:30px;border-radius:50%;background:#eef2ff;display:flex;align-items:center;justify-content:center;font-size:13px;font-weight:800;color:#4f46e5;">
                      <%= _rv.getStudentName() != null && !_rv.getStudentName().isEmpty() ? _rv.getStudentName().substring(0,1).toUpperCase() : "?" %>
                    </div>
                    <div>
                      <div style="font-size:13px;font-weight:700;color:#0f2744;"><%= _rv.getStudentName() %></div>
                      <div style="font-size:10px;color:#94a3b8;"><%= _rv.getCourseName() %></div>
                    </div>
                  </div>
                  <div style="display:flex;gap:2px;">
                    <% for (int _rs = 1; _rs <= 5; _rs++) { %>
                    <span style="font-size:13px;color:<%= _rs <= _rv.getRating() ? "#f59e0b" : "#e2e8f0" %>;">★</span>
                    <% } %>
                  </div>
                </div>
                <% if (_rv.getComment() != null && !_rv.getComment().isEmpty()) { %>
                <div style="font-size:12px;color:#475569;background:#f8fafc;border-radius:8px;padding:8px 10px;border-left:3px solid #93c5fd;">
                  "<%= org.springframework.web.util.HtmlUtils.htmlEscape(_rv.getComment()) %>"
                </div>
                <% } %>
                <div style="font-size:10px;color:#cbd5e1;margin-top:6px;text-align:right;"><%= _rv.getCreatedAt().length() > 10 ? _rv.getCreatedAt().substring(0,10) : _rv.getCreatedAt() %></div>
              </div>
              <% } %>
            </div>
            <% } %>
          </div>
        </div>
        <% } /* end teacher review section */ %>

      </div><!-- end right col -->
    </div><!-- end profile-layout -->
    <% } /* end tab profile */ %>

    <%-- ══ TAB: LIÊN HỆ (CONTACT) ════════════════════════════════════ --%>
    <% if (activeTab.equals("contact")) { %>

    <!-- ══ CONTACT NOTIFICATIONS ══ -->
    <%
      String contactSuccess = null;
      String contactErr = null;
      if ("sent".equals(request.getParameter("success"))) {
          contactSuccess = "Yêu cầu đã gửi thành công! Chúng tôi sẽ phản hồi sớm nhất có thể.";
      }
      String errParam = request.getParameter("err");
      if (errParam != null) {
          if ("emptyFields".equals(errParam)) contactErr = "Vui lòng điền đầy đủ tất cả các trường!";
          else if ("invalidEmail".equals(errParam)) contactErr = "Địa chỉ email không hợp lệ!";
          else if ("mailFailed".equals(errParam)) contactErr = "Gửi email thất bại, vui lòng thử lại sau!";
      }
    %>
    <% if (contactSuccess != null) { %>
    <script>document.addEventListener('DOMContentLoaded',function(){ showNotifyModal('success','✅ Thành công','<%= contactSuccess.replace("'","\\'") %>'); });</script>
    <% } %>
    <% if (contactErr != null) { %>
    <script>document.addEventListener('DOMContentLoaded',function(){ showNotifyModal('error','⚠️ Lỗi','<%= contactErr.replace("'","\\'") %>'); });</script>
    <% } %>

    <!-- ══ CONTACT HEADER ══ -->
    <div style="display:flex;align-items:center;gap:16px;margin-bottom:28px;">
      <div style="width:54px;height:54px;border-radius:16px;background:linear-gradient(135deg,#06b6d4,#0891b2);display:flex;align-items:center;justify-content:center;font-size:26px;box-shadow:0 6px 18px rgba(6,182,212,.3);flex-shrink:0;">📞</div>
      <div>
        <div style="font-size:22px;font-weight:800;color:#0f2744;letter-spacing:-.4px;">Liên hệ &amp; Hỗ trợ</div>
        <div style="font-size:13px;color:#64748b;margin-top:3px;">Chúng tôi luôn sẵn sàng hỗ trợ bạn 24/7</div>
      </div>
    </div>

    <div style="display:grid;grid-template-columns:320px 1fr;gap:20px;align-items:start;">

      <!-- ══ LEFT: Contact Info ══ -->
      <div style="display:flex;flex-direction:column;gap:14px;">
        <!-- Contact cards -->
        <% String[][] contacts = {
          {"📧","Email hỗ trợ","support@studyflow.edu.vn","Phản hồi trong 24 giờ","#dbeafe","#1d4ed8"},
          {"📞","Hotline","1800 9999 (miễn phí)","Thứ 2 – Thứ 6 | 8:00 – 17:00","#d1fae5","#065f46"},
          {"📍","Địa chỉ","123 Đường Nguyễn Huệ, Q.1","TP. Hồ Chí Minh, Việt Nam","#fef3c7","#92400e"}
        }; %>
        <% for (String[] c : contacts) { %>
        <div style="background:#fff;border-radius:16px;box-shadow:0 2px 10px rgba(0,0,0,.06);border:1.5px solid #e2e8f0;padding:16px 18px;display:flex;align-items:flex-start;gap:14px;transition:box-shadow .15s;" onmouseenter="this.style.boxShadow='0 6px 20px rgba(0,0,0,.1)'" onmouseleave="this.style.boxShadow='0 2px 10px rgba(0,0,0,.06)'">
          <div style="width:42px;height:42px;border-radius:12px;background:<%= c[4] %>;display:flex;align-items:center;justify-content:center;font-size:20px;flex-shrink:0;"><%= c[0] %></div>
          <div>
            <div style="font-size:13px;font-weight:700;color:#0f2744;margin-bottom:3px;"><%= c[1] %></div>
            <div style="font-size:13px;color:#374151;font-weight:600;"><%= c[2] %></div>
            <div style="font-size:11px;color:#94a3b8;margin-top:2px;"><%= c[3] %></div>
          </div>
        </div>
        <% } %>

        <!-- Social Media -->
        <div style="background:#fff;border-radius:16px;box-shadow:0 2px 10px rgba(0,0,0,.06);border:1.5px solid #e2e8f0;padding:16px 18px;">
          <div style="font-size:13px;font-weight:700;color:#0f2744;margin-bottom:12px;display:flex;align-items:center;gap:7px;"><span>🔗</span> Mạng xã hội</div>
          <div style="display:flex;gap:8px;">
            <a href="#" style="flex:1;padding:9px 0;text-align:center;background:#1877f2;color:#fff;border-radius:9px;font-size:12px;font-weight:700;text-decoration:none;transition:opacity .15s;" onmouseenter="this.style.opacity='.85'" onmouseleave="this.style.opacity='1'">📘 Facebook</a>
            <a href="#" style="flex:1;padding:9px 0;text-align:center;background:#ff0000;color:#fff;border-radius:9px;font-size:12px;font-weight:700;text-decoration:none;transition:opacity .15s;" onmouseenter="this.style.opacity='.85'" onmouseleave="this.style.opacity='1'">▶ YouTube</a>
            <a href="#" style="flex:1;padding:9px 0;text-align:center;background:#0ea5e9;color:#fff;border-radius:9px;font-size:12px;font-weight:700;text-decoration:none;transition:opacity .15s;" onmouseenter="this.style.opacity='.85'" onmouseleave="this.style.opacity='1'">🐦 Twitter</a>
          </div>
        </div>
      </div>

      <!-- ══ RIGHT: Contact Form ══ -->
      <div style="background:#fff;border-radius:20px;box-shadow:0 2px 14px rgba(0,0,0,.07);border:1.5px solid #e2e8f0;overflow:hidden;">
        <!-- Form header -->
        <div style="padding:20px 24px;border-bottom:1.5px solid #f1f5f9;background:linear-gradient(90deg,#fafbff,#f8fafc);display:flex;align-items:center;gap:10px;">
          <span style="font-size:17px;">✉️</span>
          <span style="font-size:15px;font-weight:700;color:#0f2744;">Gửi yêu cầu hỗ trợ</span>
        </div>
        <div style="padding:24px;">
          <form method="post" action="<%= request.getContextPath() %>/contact">
            <input type="hidden" name="redirect" value="/dashboard?tab=contact"/>
            <div style="display:flex;flex-direction:column;gap:14px;">
              <div style="display:grid;grid-template-columns:1fr 1fr;gap:14px;">
                <div>
                  <label style="font-size:11px;font-weight:700;color:#64748b;text-transform:uppercase;letter-spacing:.5px;display:block;margin-bottom:6px;">Họ và tên</label>
                  <input name="name" type="text" value="<%= user.getFullName() != null ? user.getFullName() : user.getUsername() %>" required
                    style="width:100%;box-sizing:border-box;padding:10px 14px;border:1.5px solid #e2e8f0;border-radius:10px;font-size:13px;outline:none;transition:border .2s;background:#f8fafc;"
                    onfocus="this.style.borderColor='#06b6d4';this.style.background='#fff'" onblur="this.style.borderColor='#e2e8f0';this.style.background='#f8fafc'"/>
                </div>
                <div>
                  <label style="font-size:11px;font-weight:700;color:#64748b;text-transform:uppercase;letter-spacing:.5px;display:block;margin-bottom:6px;">Email</label>
                  <input name="email" type="email" value="<%= user.getEmail() != null ? user.getEmail() : "" %>" required
                    style="width:100%;box-sizing:border-box;padding:10px 14px;border:1.5px solid #e2e8f0;border-radius:10px;font-size:13px;outline:none;transition:border .2s;background:#f8fafc;"
                    onfocus="this.style.borderColor='#06b6d4';this.style.background='#fff'" onblur="this.style.borderColor='#e2e8f0';this.style.background='#f8fafc'"/>
                </div>
              </div>
              <div>
                <label style="font-size:11px;font-weight:700;color:#64748b;text-transform:uppercase;letter-spacing:.5px;display:block;margin-bottom:6px;">Chủ đề</label>
                <select name="subject" required style="width:100%;padding:10px 14px;border:1.5px solid #e2e8f0;border-radius:10px;font-size:13px;outline:none;background:#f8fafc;cursor:pointer;transition:border .2s;font-family:inherit;"
                  onfocus="this.style.borderColor='#06b6d4'" onblur="this.style.borderColor='#e2e8f0'">
                  <option value="">-- Chọn chủ đề --</option>
                  <option value="account">Vấn đề tài khoản</option>
                  <option value="course">Vấn đề khóa học</option>
                  <option value="payment">Thanh toán</option>
                  <option value="technical">Lỗi kỹ thuật</option>
                  <option value="other">Khác</option>
                </select>
              </div>
              <div>
                <label style="font-size:11px;font-weight:700;color:#64748b;text-transform:uppercase;letter-spacing:.5px;display:block;margin-bottom:6px;">Nội dung</label>
                <textarea name="message" rows="5" required
                  style="width:100%;box-sizing:border-box;padding:10px 14px;border:1.5px solid #e2e8f0;border-radius:10px;font-size:13px;outline:none;resize:vertical;font-family:inherit;transition:border .2s;background:#f8fafc;line-height:1.6;"
                  onfocus="this.style.borderColor='#06b6d4';this.style.background='#fff'" onblur="this.style.borderColor='#e2e8f0';this.style.background='#f8fafc'"
                  placeholder="Mô tả vấn đề của bạn chi tiết để chúng tôi hỗ trợ nhanh hơn..."></textarea>
              </div>
              <div style="display:flex;gap:10px;padding-top:4px;">
                <button type="submit"
                  style="flex:1;padding:12px 0;background:linear-gradient(135deg,#06b6d4,#0891b2);color:#fff;border:none;border-radius:12px;font-size:14px;font-weight:700;cursor:pointer;transition:all .15s;box-shadow:0 4px 12px rgba(6,182,212,.3);"
                  onmouseenter="this.style.opacity='.88';this.style.transform='translateY(-1px)'" onmouseleave="this.style.opacity='1';this.style.transform=''">
                  🚀 Gửi yêu cầu hỗ trợ
                </button>
                <a href="dashboard" style="display:inline-flex;align-items:center;justify-content:center;padding:12px 20px;background:#f8fafc;color:#64748b;border-radius:12px;font-size:13px;font-weight:600;text-decoration:none;border:1.5px solid #e2e8f0;transition:all .15s;" onmouseenter="this.style.background='#f1f5f9'" onmouseleave="this.style.background='#f8fafc'">
                  🏠 Trang chủ
                </a>
              </div>
            </div>
          </form>
        </div>
      </div>
    </div>
    <% } else if (activeTab.equals("stats")) { /* ══ TAB: BÁO CÁO THỐNG KÊ ════════════════════ */ %>

    <!-- ══ HEADER ══ -->
    <div style="display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:12px;margin-bottom:26px;">
      <div style="display:flex;align-items:center;gap:16px;">
        <div style="width:54px;height:54px;border-radius:16px;background:linear-gradient(135deg,#6366f1,#8b5cf6);display:flex;align-items:center;justify-content:center;font-size:26px;box-shadow:0 6px 18px rgba(99,102,241,.3);flex-shrink:0;">📊</div>
        <div>
          <div style="font-size:22px;font-weight:800;color:#0f2744;letter-spacing:-.4px;">Báo cáo thống kê</div>
          <div style="font-size:13px;color:#64748b;margin-top:3px;">Dữ liệu thực từ cơ sở dữ liệu — cập nhật theo thời gian thực</div>
        </div>
      </div>
      <div style="display:flex;align-items:center;gap:8px;background:#f0fdf4;border:1.5px solid #6ee7b7;border-radius:10px;padding:8px 14px;">
        <span style="font-size:13px;">🟢</span>
        <span style="font-size:12px;font-weight:700;color:#065f46;">Live data</span>
      </div>
    </div>

    <!-- ══ KPI CARDS ══ -->
    <div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(160px,1fr));gap:14px;margin-bottom:24px;">
      <div style="background:#fff;border-radius:16px;padding:20px;box-shadow:0 2px 12px rgba(0,0,0,.06);border:1.5px solid #e2e8f0;position:relative;overflow:hidden;">
        <div style="position:absolute;top:0;left:0;right:0;height:3px;background:linear-gradient(90deg,#6366f1,#8b5cf6);"></div>
        <div style="font-size:28px;margin-bottom:6px;">📚</div>
        <div style="font-size:30px;font-weight:800;color:#0f2744;line-height:1;"><%= totalCourses %></div>
        <div style="font-size:12px;color:#64748b;margin-top:5px;font-weight:500;">Tổng khóa học</div>
        <div style="font-size:11px;color:#6366f1;margin-top:3px;font-weight:600;">+<%= newCoursesMonth %> tháng này</div>
      </div>
      <div style="background:#fff;border-radius:16px;padding:20px;box-shadow:0 2px 12px rgba(0,0,0,.06);border:1.5px solid #e2e8f0;position:relative;overflow:hidden;">
        <div style="position:absolute;top:0;left:0;right:0;height:3px;background:linear-gradient(90deg,#10b981,#059669);"></div>
        <div style="font-size:28px;margin-bottom:6px;">👥</div>
        <div style="font-size:30px;font-weight:800;color:#0f2744;line-height:1;"><%= totalStudents %></div>
        <div style="font-size:12px;color:#64748b;margin-top:5px;font-weight:500;">Tổng học viên</div>
        <div style="font-size:11px;color:#10b981;margin-top:3px;font-weight:600;">+<%= newStudentsToday %> hôm nay</div>
      </div>
      <div style="background:#fff;border-radius:16px;padding:20px;box-shadow:0 2px 12px rgba(0,0,0,.06);border:1.5px solid #e2e8f0;position:relative;overflow:hidden;">
        <div style="position:absolute;top:0;left:0;right:0;height:3px;background:linear-gradient(90deg,#f59e0b,#d97706);"></div>
        <div style="font-size:28px;margin-bottom:6px;">👨‍🏫</div>
        <div style="font-size:30px;font-weight:800;color:#0f2744;line-height:1;"><%= totalTeachers %></div>
        <div style="font-size:12px;color:#64748b;margin-top:5px;font-weight:500;">Giáo viên</div>
        <div style="font-size:11px;color:#f59e0b;margin-top:3px;font-weight:600;"><%= pendingCount %> chờ duyệt</div>
      </div>
      <div style="background:#fff;border-radius:16px;padding:20px;box-shadow:0 2px 12px rgba(0,0,0,.06);border:1.5px solid #e2e8f0;position:relative;overflow:hidden;">
        <div style="position:absolute;top:0;left:0;right:0;height:3px;background:linear-gradient(90deg,#3b82f6,#2563eb);"></div>
        <div style="font-size:28px;margin-bottom:6px;">✅</div>
        <div style="font-size:30px;font-weight:800;color:#0f2744;line-height:1;"><%= totalEnrollments %></div>
        <div style="font-size:12px;color:#64748b;margin-top:5px;font-weight:500;">Lượt đăng ký</div>
        <div style="font-size:11px;color:#3b82f6;margin-top:3px;font-weight:600;">Tất cả thời gian</div>
      </div>
    </div>

    <!-- ══ CHARTS ROW ══ -->
    <div style="display:grid;grid-template-columns:1fr 1fr;gap:20px;margin-bottom:24px;">

      <!-- Chart 1: Enrollment trend (line) -->
      <div style="background:#fff;border-radius:20px;padding:24px;box-shadow:0 2px 14px rgba(0,0,0,.07);border:1.5px solid #e2e8f0;min-width:0;">
        <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:18px;">
          <div>
            <div style="font-size:14px;font-weight:700;color:#0f2744;">📈 Lượt đăng ký theo tháng</div>
            <div style="font-size:11px;color:#94a3b8;margin-top:2px;">12 tháng gần nhất</div>
          </div>
          <div style="width:32px;height:32px;background:#eef2ff;border-radius:8px;display:flex;align-items:center;justify-content:center;font-size:14px;">📈</div>
        </div>
        <div style="position:relative;height:220px;width:100%;"><canvas id="enrollChart"></canvas></div>
      </div>

      <!-- Chart 2: New students + teachers (bar) -->
      <div style="background:#fff;border-radius:20px;padding:24px;box-shadow:0 2px 14px rgba(0,0,0,.07);border:1.5px solid #e2e8f0;min-width:0;">
        <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:18px;">
          <div>
            <div style="font-size:14px;font-weight:700;color:#0f2744;">👥 Người dùng mới theo tháng</div>
            <div style="font-size:11px;color:#94a3b8;margin-top:2px;">Học viên & Giáo viên</div>
          </div>
          <div style="width:32px;height:32px;background:#f0fdf4;border-radius:8px;display:flex;align-items:center;justify-content:center;font-size:14px;">👥</div>
        </div>
        <div style="position:relative;height:220px;width:100%;"><canvas id="userChart"></canvas></div>
      </div>
    </div>

    <!-- ══ BOTTOM ROW: Top courses + Recent enrollments ══ -->
    <div style="display:grid;grid-template-columns:1fr 1fr;gap:20px;">

      <!-- Top Courses -->
      <div style="background:#fff;border-radius:20px;box-shadow:0 2px 14px rgba(0,0,0,.07);border:1.5px solid #e2e8f0;overflow:hidden;">
        <div style="padding:18px 22px;border-bottom:1.5px solid #f1f5f9;display:flex;align-items:center;gap:10px;background:linear-gradient(90deg,#fafbff,#f8fafc);">
          <span style="font-size:16px;">🏆</span>
          <span style="font-size:14px;font-weight:700;color:#0f2744;">Top 5 khóa học phổ biến</span>
        </div>
        <div style="padding:16px 22px;">
          <% if (topCourses.isEmpty()) { %>
            <div style="text-align:center;padding:28px;color:#94a3b8;font-size:13px;">Chưa có dữ liệu đăng ký</div>
          <% } else { %>
            <% for (int idx = 0; idx < topCourses.size(); idx++) {
                 Map<String,Object> tc = topCourses.get(idx);
                 String tcName  = tc.get("name").toString();
                 int    tcTotal = ((Number) tc.get("total")).intValue();
                 int    tcMax   = topCourses.isEmpty() ? 1 : ((Number)topCourses.get(0).get("total")).intValue();
                 int    tcPct   = tcMax == 0 ? 0 : (int)Math.round(100.0 * tcTotal / tcMax);
                 String[] barColors = {"#6366f1","#10b981","#f59e0b","#3b82f6","#ec4899"};
                 String barColor = barColors[idx % barColors.length];
            %>
            <div style="margin-bottom:<%= idx < topCourses.size()-1 ? "14" : "0" %>px;">
              <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:5px;">
                <div style="display:flex;align-items:center;gap:8px;">
                  <div style="width:22px;height:22px;border-radius:6px;background:<%= barColor %>;display:flex;align-items:center;justify-content:center;font-size:11px;font-weight:800;color:#fff;"><%= idx+1 %></div>
                  <span style="font-size:12px;font-weight:600;color:#0f2744;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;max-width:160px;"><%= tcName.length()>26 ? tcName.substring(0,26)+"…" : tcName %></span>
                </div>
                <span style="font-size:12px;font-weight:700;color:<%= barColor %>;"><%= tcTotal %> HV</span>
              </div>
              <div style="height:6px;background:#f1f5f9;border-radius:999px;overflow:hidden;">
                <div style="height:100%;background:<%= barColor %>;border-radius:999px;width:<%= tcPct %>%;transition:width .6s ease;"></div>
              </div>
            </div>
            <% } %>
          <% } %>
        </div>
      </div>

      <!-- Recent Enrollments -->
      <div style="background:#fff;border-radius:20px;box-shadow:0 2px 14px rgba(0,0,0,.07);border:1.5px solid #e2e8f0;overflow:hidden;">
        <div style="padding:18px 22px;border-bottom:1.5px solid #f1f5f9;display:flex;align-items:center;gap:10px;background:linear-gradient(90deg,#fafbff,#f8fafc);">
          <span style="font-size:16px;">🕐</span>
          <span style="font-size:14px;font-weight:700;color:#0f2744;">Đăng ký gần nhất</span>
        </div>
        <div>
          <% if (recentEnroll.isEmpty()) { %>
            <div style="text-align:center;padding:40px;color:#94a3b8;font-size:13px;">Chưa có dữ liệu</div>
          <% } else { %>
            <% for (Map<String,Object> re : recentEnroll) {
                 String reUser = re.get("username") != null ? re.get("username").toString() : "U";
                 String reInit = reUser.isEmpty() ? "U" : reUser.substring(0,1).toUpperCase();
            %>
            <div style="display:flex;align-items:center;gap:12px;padding:13px 22px;border-bottom:1px solid #f8fafc;transition:background .12s;" onmouseenter="this.style.background='#f8fafc'" onmouseleave="this.style.background='transparent'">
              <div style="width:36px;height:36px;border-radius:10px;background:linear-gradient(135deg,#6366f1,#8b5cf6);display:flex;align-items:center;justify-content:center;font-size:14px;font-weight:800;color:#fff;flex-shrink:0;">
                <%= reInit %>
              </div>
              <div style="flex:1;min-width:0;">
                <div style="font-size:13px;font-weight:700;color:#0f2744;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;"><%= re.get("username") %></div>
                <div style="font-size:11px;color:#64748b;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;margin-top:2px;">📚 <%= re.get("course") %></div>
              </div>
              <div style="font-size:11px;color:#94a3b8;white-space:nowrap;flex-shrink:0;">
                <%= re.get("enrolled_at") != null ? re.get("enrolled_at").toString().substring(0, Math.min(10, re.get("enrolled_at").toString().length())) : "" %>
              </div>
            </div>
            <% } %>
          <% } %>
        </div>
      </div>
    </div>

    <!-- ══ MONTHLY DETAIL TABLE ══ -->
    <div style="background:#fff;border-radius:20px;box-shadow:0 2px 14px rgba(0,0,0,.07);border:1.5px solid #e2e8f0;overflow:hidden;margin-top:24px;">
      <div style="padding:18px 22px;border-bottom:1.5px solid #f1f5f9;display:flex;align-items:center;gap:10px;background:linear-gradient(90deg,#fafbff,#f8fafc);">
        <span style="font-size:16px;">📅</span>
        <span style="font-size:14px;font-weight:700;color:#0f2744;">Chi tiết thống kê 12 tháng</span>
      </div>
      <div style="overflow-x:auto;">
        <table style="width:100%;border-collapse:collapse;font-size:13px;">
          <thead>
            <tr style="background:#f8fafc;font-size:11px;color:#64748b;text-transform:uppercase;letter-spacing:.5px;">
              <th style="padding:11px 18px;text-align:left;font-weight:700;">Tháng</th>
              <th style="padding:11px 18px;text-align:center;font-weight:700;">Lượt đăng ký</th>
              <th style="padding:11px 18px;text-align:center;font-weight:700;">Học viên mới</th>
              <th style="padding:11px 18px;text-align:center;font-weight:700;">Giáo viên mới</th>
              <th style="padding:11px 18px;text-align:center;font-weight:700;">Xu hướng</th>
            </tr>
          </thead>
          <tbody>
            <% for (int i = detailedStats.size()-1; i >= 0; i--) {
                 Map<String,Object> ds = detailedStats.get(i);
                 int dsEnroll = ((Number)ds.get("enrollments")).intValue();
                 int dsStu = ((Number)ds.get("new_students")).intValue();
                 int dsTea = ((Number)ds.get("new_teachers")).intValue();
                 boolean isCurrentMonth = (i == detailedStats.size()-1);
            %>
            <tr style="border-top:1px solid #f1f5f9;transition:background .12s;<%= isCurrentMonth ? "background:#fafbff;" : "" %>" onmouseenter="this.style.background='#f8fafc'" onmouseleave="this.style.background='<%= isCurrentMonth ? "#fafbff" : "transparent" %>'">
              <td style="padding:12px 18px;">
                <div style="display:flex;align-items:center;gap:8px;">
                  <% if (isCurrentMonth) { %>
                    <span style="background:#e0e7ff;color:#4338ca;font-size:10px;font-weight:700;padding:2px 7px;border-radius:999px;">Tháng này</span>
                  <% } %>
                  <span style="font-weight:600;color:#0f2744;"><%= ds.get("month_label") %></span>
                </div>
              </td>
              <td style="padding:12px 18px;text-align:center;">
                <span style="font-weight:700;color:<%= dsEnroll>0 ? "#6366f1" : "#94a3b8" %>;"><%= dsEnroll %></span>
              </td>
              <td style="padding:12px 18px;text-align:center;">
                <span style="font-weight:700;color:<%= dsStu>0 ? "#10b981" : "#94a3b8" %>;"><%= dsStu %></span>
              </td>
              <td style="padding:12px 18px;text-align:center;">
                <span style="font-weight:700;color:<%= dsTea>0 ? "#f59e0b" : "#94a3b8" %>;"><%= dsTea %></span>
              </td>
              <td style="padding:12px 18px;text-align:center;">
                <% int dsTotal = dsEnroll + dsStu; %>
                <span style="font-size:16px;"><%= dsTotal > 10 ? "🔥" : dsTotal > 5 ? "📈" : dsTotal > 0 ? "➡️" : "💤" %></span>
              </td>
            </tr>
            <% } %>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Re-init charts when stats tab is active (canvas newly rendered in DOM) -->
    <script>
    (function() {
        function waitAndInit(attempt) {
            if (typeof Chart !== 'undefined' && typeof initDashboardCharts === 'function') {
                window._chartsInitialized = false;
                initDashboardCharts();
            } else if (attempt < 20) {
                setTimeout(function() { waitAndInit(attempt + 1); }, 150);
            }
        }
        waitAndInit(0);
    })();
    </script>

    <% } else if (activeTab.equals("security")) { /* ══ TAB: BẢO MẬT ════════════════════════ */ %>

    <!-- ══ SECURITY HEADER ══ -->
    <div style="display:flex;align-items:center;gap:16px;margin-bottom:28px;">
      <div style="width:54px;height:54px;border-radius:16px;background:linear-gradient(135deg,#dc2626,#b91c1c);display:flex;align-items:center;justify-content:center;font-size:26px;box-shadow:0 6px 18px rgba(220,38,38,.28);flex-shrink:0;">🔐</div>
      <div>
        <div style="font-size:22px;font-weight:800;color:#0f2744;letter-spacing:-.4px;">Bảo mật tài khoản</div>
        <div style="font-size:13px;color:#64748b;margin-top:3px;">Quản lý mật khẩu, phiên đăng nhập và cài đặt bảo mật</div>
      </div>
    </div>

    <!-- ══ SECURITY STATUS BAR ══ -->
    <div style="background:linear-gradient(135deg,#f0fdf4,#dcfce7);border:1.5px solid #86efac;border-radius:14px;padding:14px 20px;margin-bottom:22px;display:flex;align-items:center;gap:14px;">
      <div style="width:36px;height:36px;background:#10b981;border-radius:10px;display:flex;align-items:center;justify-content:center;font-size:18px;flex-shrink:0;">🛡️</div>
      <div style="flex:1;">
        <div style="font-size:13px;font-weight:700;color:#065f46;">Tài khoản của bạn đang được bảo vệ</div>
        <div style="font-size:12px;color:#16a34a;margin-top:2px;">Đăng nhập lần cuối: hôm nay • IP: <%= request.getRemoteAddr() %></div>
      </div>
      <span style="font-size:11px;font-weight:700;color:#065f46;background:#bbf7d0;padding:4px 10px;border-radius:8px;white-space:nowrap;">🟢 An toàn</span>
    </div>

    <div style="display:grid;grid-template-columns:1fr 1fr;gap:20px;">

      <!-- ══ CARD: Đổi mật khẩu ══ -->
      <div style="background:#fff;border-radius:20px;box-shadow:0 2px 14px rgba(0,0,0,.07);border:1.5px solid #e2e8f0;overflow:hidden;">
        <div style="padding:18px 22px;border-bottom:1.5px solid #f1f5f9;background:linear-gradient(90deg,#fafbff,#f8fafc);display:flex;align-items:center;gap:10px;">
          <div style="width:34px;height:34px;background:#eef2ff;border-radius:9px;display:flex;align-items:center;justify-content:center;font-size:16px;">🔑</div>
          <span style="font-size:14px;font-weight:700;color:#0f2744;">Đổi mật khẩu</span>
        </div>
        <div style="padding:22px;display:flex;flex-direction:column;gap:14px;">
          <div>
            <label style="font-size:11px;font-weight:700;color:#64748b;text-transform:uppercase;letter-spacing:.5px;display:block;margin-bottom:6px;">Mật khẩu hiện tại</label>
            <div style="position:relative;">
              <input type="password" id="oldPass" placeholder="Nhập mật khẩu hiện tại"
                style="width:100%;box-sizing:border-box;padding:10px 40px 10px 14px;border:1.5px solid #e2e8f0;border-radius:10px;font-size:13px;outline:none;transition:border .2s;background:#f8fafc;"
                onfocus="this.style.borderColor='#6366f1';this.style.background='#fff'" onblur="this.style.borderColor='#e2e8f0';this.style.background='#f8fafc'"/>
              <span onclick="togglePass('oldPass',this)" style="position:absolute;right:12px;top:50%;transform:translateY(-50%);cursor:pointer;font-size:14px;opacity:.5;user-select:none;">👁</span>
            </div>
          </div>
          <div>
            <label style="font-size:11px;font-weight:700;color:#64748b;text-transform:uppercase;letter-spacing:.5px;display:block;margin-bottom:6px;">Mật khẩu mới</label>
            <div style="position:relative;">
              <input type="password" id="newPass" placeholder="Tối thiểu 8 ký tự"
                style="width:100%;box-sizing:border-box;padding:10px 40px 10px 14px;border:1.5px solid #e2e8f0;border-radius:10px;font-size:13px;outline:none;transition:border .2s;background:#f8fafc;"
                onfocus="this.style.borderColor='#6366f1';this.style.background='#fff'" onblur="this.style.borderColor='#e2e8f0';this.style.background='#f8fafc'"
                oninput="checkPassStrength(this.value)"/>
              <span onclick="togglePass('newPass',this)" style="position:absolute;right:12px;top:50%;transform:translateY(-50%);cursor:pointer;font-size:14px;opacity:.5;user-select:none;">👁</span>
            </div>
            <!-- Password strength bar -->
            <div style="margin-top:7px;">
              <div style="height:4px;background:#e2e8f0;border-radius:999px;overflow:hidden;">
                <div id="passStrengthBar" style="height:100%;width:0%;border-radius:999px;background:#10b981;transition:width .3s,background .3s;"></div>
              </div>
              <div id="passStrengthLabel" style="font-size:10px;color:#94a3b8;margin-top:4px;font-weight:600;"></div>
            </div>
          </div>
          <div>
            <label style="font-size:11px;font-weight:700;color:#64748b;text-transform:uppercase;letter-spacing:.5px;display:block;margin-bottom:6px;">Xác nhận mật khẩu mới</label>
            <div style="position:relative;">
              <input type="password" id="confirmPass" placeholder="Nhập lại mật khẩu mới"
                style="width:100%;box-sizing:border-box;padding:10px 40px 10px 14px;border:1.5px solid #e2e8f0;border-radius:10px;font-size:13px;outline:none;transition:border .2s;background:#f8fafc;"
                onfocus="this.style.borderColor='#6366f1';this.style.background='#fff'" onblur="this.style.borderColor='#e2e8f0';this.style.background='#f8fafc'"/>
              <span onclick="togglePass('confirmPass',this)" style="position:absolute;right:12px;top:50%;transform:translateY(-50%);cursor:pointer;font-size:14px;opacity:.5;user-select:none;">👁</span>
            </div>
          </div>
          <div id="passMsg" style="display:none;font-size:12px;font-weight:600;padding:9px 12px;border-radius:9px;"></div>
          <button onclick="doChangePass()"
            style="width:100%;padding:11px 0;background:linear-gradient(135deg,#6366f1,#8b5cf6);color:#fff;border:none;border-radius:11px;font-size:13px;font-weight:700;cursor:pointer;transition:all .15s;box-shadow:0 3px 10px rgba(99,102,241,.28);"
            onmouseenter="this.style.opacity='.88';this.style.transform='translateY(-1px)'" onmouseleave="this.style.opacity='1';this.style.transform=''">
            💾 Cập nhật mật khẩu
          </button>
        </div>
      </div>

      <!-- ══ RIGHT COLUMN ══ -->
      <div style="display:flex;flex-direction:column;gap:16px;">

        <!-- CARD: Phiên đăng nhập -->
        <div style="background:#fff;border-radius:20px;box-shadow:0 2px 14px rgba(0,0,0,.07);border:1.5px solid #e2e8f0;overflow:hidden;">
          <div style="padding:16px 20px;border-bottom:1.5px solid #f1f5f9;background:linear-gradient(90deg,#fafbff,#f8fafc);display:flex;align-items:center;gap:10px;">
            <div style="width:34px;height:34px;background:#f0fdf4;border-radius:9px;display:flex;align-items:center;justify-content:center;font-size:16px;">🖥️</div>
            <span style="font-size:14px;font-weight:700;color:#0f2744;">Phiên đang hoạt động</span>
          </div>
          <div style="padding:16px 20px;display:flex;flex-direction:column;gap:10px;">
            <div style="display:flex;align-items:center;gap:12px;padding:12px 14px;background:#f0fdf4;border-radius:12px;border:1px solid #bbf7d0;">
              <div style="width:36px;height:36px;background:#10b981;border-radius:9px;display:flex;align-items:center;justify-content:center;font-size:16px;flex-shrink:0;">💻</div>
              <div style="flex:1;">
                <div style="font-size:12px;font-weight:700;color:#065f46;">Thiết bị hiện tại</div>
                <div style="font-size:11px;color:#16a34a;margin-top:2px;">Trình duyệt Web • Đang hoạt động</div>
              </div>
              <span style="width:7px;height:7px;border-radius:50%;background:#10b981;flex-shrink:0;box-shadow:0 0 0 3px rgba(16,185,129,.2);"></span>
            </div>
            <div style="display:flex;align-items:center;gap:12px;padding:12px 14px;background:#f8fafc;border-radius:12px;border:1px solid #e2e8f0;">
              <div style="width:36px;height:36px;background:#e2e8f0;border-radius:9px;display:flex;align-items:center;justify-content:center;font-size:16px;flex-shrink:0;">📱</div>
              <div style="flex:1;">
                <div style="font-size:12px;font-weight:700;color:#374151;">Thiết bị di động</div>
                <div style="font-size:11px;color:#9ca3af;margin-top:2px;">Không rõ • 2 giờ trước</div>
              </div>
              <span style="width:7px;height:7px;border-radius:50%;background:#d1d5db;flex-shrink:0;"></span>
            </div>
            <button style="width:100%;padding:9px 0;background:#fee2e2;color:#dc2626;border:none;border-radius:10px;font-size:12px;font-weight:700;cursor:pointer;transition:background .2s;"
              onmouseenter="this.style.background='#fecaca'" onmouseleave="this.style.background='#fee2e2'">
              ✕ Đăng xuất khỏi tất cả thiết bị
            </button>
          </div>
        </div>

        <!-- CARD: Bảo mật nâng cao -->
        <div style="background:#fff;border-radius:20px;box-shadow:0 2px 14px rgba(0,0,0,.07);border:1.5px solid #e2e8f0;overflow:hidden;">
          <div style="padding:16px 20px;border-bottom:1.5px solid #f1f5f9;background:linear-gradient(90deg,#fafbff,#f8fafc);display:flex;align-items:center;gap:10px;">
            <div style="width:34px;height:34px;background:#fef3c7;border-radius:9px;display:flex;align-items:center;justify-content:center;font-size:16px;">🛡️</div>
            <span style="font-size:14px;font-weight:700;color:#0f2744;">Bảo mật nâng cao</span>
          </div>
          <div style="padding:16px 20px;display:flex;flex-direction:column;gap:10px;">
            <!-- 2FA row -->
            <div style="display:flex;align-items:center;justify-content:space-between;padding:12px 14px;background:#fffbeb;border-radius:12px;border:1px solid #fde68a;">
              <div style="display:flex;align-items:center;gap:10px;">
                <span style="font-size:18px;">🔐</span>
                <div>
                  <div style="font-size:12px;font-weight:700;color:#92400e;">Xác thực 2 yếu tố (2FA)</div>
                  <div style="font-size:11px;color:#b45309;margin-top:1px;">Chưa bật — khuyến nghị bật</div>
                </div>
              </div>
              <button style="padding:6px 14px;background:linear-gradient(135deg,#f59e0b,#d97706);color:#fff;border:none;border-radius:8px;font-size:11px;font-weight:700;cursor:pointer;white-space:nowrap;transition:opacity .15s;"
                onmouseenter="this.style.opacity='.85'" onmouseleave="this.style.opacity='1'">Bật 2FA</button>
            </div>
            <!-- Login notification row -->
            <div style="display:flex;align-items:center;justify-content:space-between;padding:12px 14px;background:#f0fdf4;border-radius:12px;border:1px solid #bbf7d0;">
              <div style="display:flex;align-items:center;gap:10px;">
                <span style="font-size:18px;">🔔</span>
                <div>
                  <div style="font-size:12px;font-weight:700;color:#065f46;">Thông báo đăng nhập</div>
                  <div style="font-size:11px;color:#16a34a;margin-top:1px;">Đang bật — nhận cảnh báo qua email</div>
                </div>
              </div>
              <button onclick="this.style.background='#fee2e2';this.style.color='#dc2626';this.textContent='Tắt'" style="padding:6px 14px;background:#10b981;color:#fff;border:none;border-radius:8px;font-size:11px;font-weight:700;cursor:pointer;transition:all .15s;">Đang bật</button>
            </div>
          </div>
        </div>

      </div><!-- end right col -->
    </div><!-- end grid -->

    <!-- Profile & Security JS moved to dashboard.js -->
    <% } /* end tab security */ %></div><!-- end main-wrap -->



<!-- ══ CONFIRM EDIT MODAL ════════ -->


<!-- ══ APPROVAL MODAL ════════ -->
<div id="approvalModal" style="display:none;position:fixed;inset:0;z-index:11000;align-items:center;justify-content:center;">
  <div onclick="closeApprovalModal()" style="position:absolute;inset:0;background:rgba(15,23,42,.45);backdrop-filter:blur(6px);"></div>
  <div style="position:relative;background:#fff;border-radius:24px;padding:40px 36px 32px;width:420px;max-width:92vw;box-shadow:0 32px 80px rgba(0,0,0,.22);animation:notifyPop .28s cubic-bezier(.34,1.56,.64,1);text-align:center;">
    <div style="position:absolute;top:0;left:0;right:0;height:5px;border-radius:24px 24px 0 0;background:linear-gradient(90deg,#10b981,#059669);"></div>
    <div id="modalIcon" style="font-size:54px;margin-bottom:14px;line-height:1;"></div>
    <div id="modalTitle" style="font-size:20px;font-weight:800;color:#1a2332;margin-bottom:10px;"></div>
    <div id="modalSub" style="font-size:14px;color:#64748b;line-height:1.7;margin-bottom:28px;"></div>
    <form id="approvalForm" method="post">
      <input type="hidden" id="modalAction" name="action" value="">
      <input type="hidden" id="modalUserId" name="userId" value="">
      <input type="hidden" name="redirectTo" value="/dashboard?tab=pending-teachers">
      <div style="display:flex;gap:12px;justify-content:center;">
        <button type="button" onclick="closeApprovalModal()"
          style="flex:1;padding:12px 0;border-radius:12px;border:1.5px solid #e2e8f0;background:#fff;color:#64748b;font-size:14px;font-weight:700;cursor:pointer;font-family:'Nunito',sans-serif;">
          Hủy
        </button>
        <button id="modalConfirmBtn" type="submit"
          style="flex:1;padding:12px 0;border-radius:12px;border:none;background:#10b981;color:#fff;font-size:14px;font-weight:700;cursor:pointer;font-family:'Nunito',sans-serif;"
          onmouseenter="this.style.opacity='.88'" onmouseleave="this.style.opacity='1'">
          Xác nhận
        </button>
      </div>
    </form>
  </div>
</div>

<!-- ══ TOAST MODAL (Center Toast) ════════ -->
<div id="toastModal" style="display:none;position:fixed;inset:0;z-index:11000;align-items:center;justify-content:center;">
  <div onclick="closeToast()" style="position:absolute;inset:0;background:rgba(15,23,42,.35);backdrop-filter:blur(4px);"></div>
  <div style="position:relative;background:#fff;border-radius:24px;padding:40px 36px 32px;width:380px;max-width:92vw;box-shadow:0 32px 80px rgba(0,0,0,.22);animation:notifyPop .28s cubic-bezier(.34,1.56,.64,1);text-align:center;">
    <div id="toastIcon" style="font-size:54px;margin-bottom:14px;line-height:1;"></div>
    <div id="toastTitle" style="font-size:20px;font-weight:800;color:#1a2332;margin-bottom:10px;"></div>
    <div id="toastMessage" style="font-size:14px;color:#64748b;line-height:1.7;margin-bottom:28px;"></div>
    <button id="toastBtn" onclick="closeToast()"
      style="width:100%;padding:14px 0;border-radius:14px;border:none;color:#fff;font-size:15px;font-weight:700;cursor:pointer;font-family:'Nunito',sans-serif;transition:opacity .15s;"
      onmouseenter="this.style.opacity='.88'" onmouseleave="this.style.opacity='1'">
      ✓ Đã hiểu
    </button>
  </div>
</div>

<!-- ══ NOTIFY MODAL (Thông báo giữa màn hình) ════════ -->
<div id="notifyModal" style="display:none;position:fixed;inset:0;z-index:11000;align-items:center;justify-content:center;">
  <div onclick="closeNotifyModal()" style="position:absolute;inset:0;background:rgba(15,23,42,.45);backdrop-filter:blur(6px);"></div>
  <div id="notifyCard" style="position:relative;background:#fff;border-radius:24px;padding:44px 40px 36px;width:400px;max-width:92vw;box-shadow:0 32px 80px rgba(0,0,0,.22);animation:notifyPop .28s cubic-bezier(.34,1.56,.64,1);text-align:center;">
    <!-- top color bar -->
    <div id="notifyBar" style="position:absolute;top:0;left:0;right:0;height:5px;border-radius:24px 24px 0 0;background:linear-gradient(90deg,#10b981,#059669);"></div>
    <div id="notifyIcon" style="font-size:60px;margin-bottom:16px;line-height:1;"></div>
    <div id="notifyTitle" style="font-size:21px;font-weight:800;color:#1a2332;margin-bottom:10px;"></div>
    <div id="notifyMsg" style="font-size:14px;color:#64748b;line-height:1.7;margin-bottom:32px;"></div>
    <button onclick="closeNotifyModal()" id="notifyBtn"
      style="width:100%;padding:14px 0;border-radius:14px;border:none;color:#fff;font-size:15px;font-weight:700;cursor:pointer;transition:opacity .15s;letter-spacing:.3px;"
      onmouseenter="this.style.opacity='.88'" onmouseleave="this.style.opacity='1'">
      ✓ Đã hiểu
    </button>
  </div>
</div>

<!-- ── CHART.JS & DASHBOARD JS moved to head ── -->

</body>
</html>