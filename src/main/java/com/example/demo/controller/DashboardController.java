package com.example.demo.controller;

import com.example.demo.dao.UserDAO;
import com.example.demo.dto.CourseDTO;
import com.example.demo.dto.DashboardDTO;
import com.example.demo.dto.HomeworkDTO;
import com.example.demo.dto.VideoDTO;
import com.example.demo.entity.User;
import com.example.demo.service.CourseService;
import com.example.demo.service.DashboardService;
import com.example.demo.service.EnrollmentService;
import com.example.demo.service.TeacherReviewService;
import com.example.demo.service.HomeworkService;
import com.example.demo.service.UserService;
import com.example.demo.service.VideoService;

import jakarta.servlet.http.HttpSession;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import java.util.*;

@Controller
@RequestMapping("/dashboard")
@RequiredArgsConstructor
public class DashboardController {

    private final DashboardService     dashboardService;
    private final UserService          userService;
    private final UserDAO              userDAO;
    private final CourseService        courseService;
    private final VideoService         videoService;
    private final HomeworkService      homeworkService;
    private final EnrollmentService    enrollmentService;
    private final TeacherReviewService teacherReviewService;

    @GetMapping
    public String showDashboard(HttpSession session, Model model) {
        User user = (User) session.getAttribute("user");
        if (user == null) return "redirect:/login";

        String role = user.getRole() != null ? user.getRole().toLowerCase() : "";
        if ("student".equals(role)) return "redirect:/home";

        populateModel(model, user, role);
        return "dashboard";
    }

    @PostMapping
    public String handleDashboardPost(
            @RequestParam(required = false) String adminAction,
            @RequestParam(required = false) String username,
            @RequestParam(required = false) String password,
            @RequestParam(required = false) String firstName,
            @RequestParam(required = false) String lastName,
            @RequestParam(required = false) String email,
            @RequestParam(required = false) String saRole,
            @RequestParam(required = false) Integer targetUserId,
            @RequestParam(required = false) String  userAction,
            @RequestParam(required = false) Integer userId,
            @RequestParam(required = false) String  newPassword,
            HttpSession session,
            Model model) {

        User user = (User) session.getAttribute("user");
        if (user == null) return "redirect:/login";

        String role = user.getRole() != null ? user.getRole().toLowerCase() : "";
        if ("student".equals(role)) return "redirect:/home";

        if (adminAction != null && "super_admin".equals(role)) {
            String msg = null;
            String err = null;

            if ("create".equals(adminAction)) {
                boolean valid = username != null && !username.trim().isEmpty()
                        && password != null && password.length() >= 8
                        && firstName != null && !firstName.trim().isEmpty()
                        && lastName  != null && !lastName.trim().isEmpty()
                        && email     != null && !email.trim().isEmpty();
                if (!valid) {
                    err = "Vui lòng điền đầy đủ thông tin (mật khẩu tối thiểu 8 ký tự)";
                } else if (userDAO.usernameExists(username.trim())) {
                    err = "Tên người dùng này đã tồn tại";
                } else if (userDAO.emailExists(email.trim())) {
                    err = "Email này đã được sử dụng";
                } else {
                    boolean ok;
                    if ("SUPER_ADMIN".equals(saRole)) {
                        ok = userDAO.createSuperAdmin(username.trim(), password,
                                firstName.trim(), lastName.trim(), email.trim());
                    } else {
                        ok = userDAO.registerFullUser(username.trim(), password,
                                firstName.trim(), lastName.trim(), email.trim(),
                                null, null, "ADMIN");
                    }
                    if (ok) msg = ("SUPER_ADMIN".equals(saRole) ? "Tạo Super Admin" : "Tạo Admin") + " thành công!";
                    else    err = "Không thể tạo tài khoản";
                }
            } else if ("delete".equals(adminAction) && targetUserId != null) {
                boolean ok = userDAO.deleteUser(targetUserId);
                if (ok) msg = "Xóa tài khoản thành công";
                else    err = "Không thể xóa tài khoản";
            }

            model.addAttribute("adminMsg", msg);
            model.addAttribute("adminErr", err);
        }

        if (userAction != null && ("admin".equals(role) || "super_admin".equals(role))) {
            String userSucc = null;
            String userErr  = null;

            if ("delete".equals(userAction) && userId != null) {
                boolean ok = userService.deleteUser(userId);
                if (ok) userSucc = "Xóa tài khoản thành công";
                else    userErr  = "Không thể xóa tài khoản (không tìm thấy hoặc là Super Admin)";

            } else if ("resetPassword".equals(userAction) && userId != null) {
                if (newPassword == null || newPassword.length() < 8) {
                    userErr = "Mật khẩu mới phải có ít nhất 8 ký tự";
                } else {
                    boolean ok = userService.resetPasswordByAdmin(userId, newPassword);
                    if (ok) userSucc = "Đặt lại mật khẩu thành công";
                    else    userErr  = "Không thể đặt lại mật khẩu (không tìm thấy người dùng)";
                }

            } else if ("toggleStatus".equals(userAction) && userId != null) {
                boolean ok = userService.toggleUserStatus(userId);
                if (ok) userSucc = "Cập nhật trạng thái tài khoản thành công";
                else    userErr  = "Không thể thay đổi trạng thái (không tìm thấy hoặc là Super Admin)";
            }

            if (userSucc != null) model.addAttribute("successParam", userSucc);
            if (userErr  != null) model.addAttribute("userErr",      userErr);
        }

        populateModel(model, user, role);
        return "dashboard";
    }

    // ── Private helpers ──────────────────────────────────────────────────────

    private void populateModel(Model model, User user, String role) {
        model.addAttribute("user", user);
        model.addAttribute("role", role);

        // Dashboard summary stats
        DashboardDTO dashData = dashboardService.getDashboardData();
        model.addAttribute("dashboardData", dashData);

        // ── FIX: Build chart data in Java (safe, no JSP scriptlet needed) ──
        model.addAttribute("chartCLabels",   buildCLabels(dashData));
        model.addAttribute("chartCData",     buildCData(dashData));
        model.addAttribute("chartDLabels",   buildDLabels(dashData));
        model.addAttribute("chartDData",     buildDData(dashData));
        model.addAttribute("chartJsMonths",  buildJsMonths(dashData));
        model.addAttribute("chartJsEnroll",  buildJsEnroll(dashData));
        model.addAttribute("chartJsStudents",buildJsStudents(dashData));
        model.addAttribute("chartJsTeachers",buildJsTeachers(dashData));

        // Courses
        List<CourseDTO> courses;
        if ("admin".equals(role) || "super_admin".equals(role)) {
            courses = courseService.getAllCourses();
            model.addAttribute("allUsers", userService.getAllUsers());
        } else {
            courses = courseService.getCoursesByTeacher(user.getId());
        }
        model.addAttribute("courses", courses);

        // Per-course videos and homework
        if (courses != null) {
            for (CourseDTO c : courses) {
                int cid = c.getId();
                int effectiveTeacherId = (c.getTeacherId() != null && c.getTeacherId() > 0)
                        ? c.getTeacherId() : user.getId();
                List<VideoDTO>    videos  = videoService.getVideosByCourse(cid);
                List<HomeworkDTO> hwList  = homeworkService.getStudentsByCourse(cid, effectiveTeacherId);
                List<HomeworkDTO> myFiles = homeworkService.getTeacherFiles(cid, effectiveTeacherId);
                model.addAttribute("videos_"   + cid, videos);
                model.addAttribute("hwList_"   + cid, hwList);
                model.addAttribute("myFiles_"  + cid, myFiles);
            }
        }

        // Teacher review stats
        if ("teacher".equals(role)) {
            model.addAttribute("teacherReviews",     teacherReviewService.getReviewsByTeacher(user.getId()));
            model.addAttribute("teacherAvgRating",   teacherReviewService.getAverageRating(user.getId()));
            model.addAttribute("teacherReviewCount", teacherReviewService.getReviewCount(user.getId()));
        }
    }

    // ── Chart data builders ──────────────────────────────────────────────────

    /** ["Th1","Th2",...] labels for bar chart (monthly enrollments) */
    private String buildCLabels(DashboardDTO dd) {
        List<Map<String, Object>> monthly = dd.getMonthlyEnrollments();
        if (monthly == null || monthly.isEmpty())
            return "\"Th1\",\"Th2\",\"Th3\",\"Th4\",\"Th5\",\"Th6\"";
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < monthly.size(); i++) {
            if (i > 0) sb.append(",");
            Object val = monthly.get(i).get("month");
            sb.append("\"").append(val != null ? escapeJs(val.toString()) : "").append("\"");
        }
        return sb.toString();
    }

    /** [0,5,3,...] data for bar chart */
    private String buildCData(DashboardDTO dd) {
        List<Map<String, Object>> monthly = dd.getMonthlyEnrollments();
        if (monthly == null || monthly.isEmpty()) return "0,0,0,0,0,0";
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < monthly.size(); i++) {
            if (i > 0) sb.append(",");
            Object val = monthly.get(i).get("total");
            sb.append(val != null ? val : 0);
        }
        return sb.toString();
    }

    /** ["Course A","Course B",...] labels for donut chart */
    private String buildDLabels(DashboardDTO dd) {
        List<Map<String, Object>> top = dd.getTopCourses();
        if (top == null || top.isEmpty()) return "\"Không có dữ liệu\"";
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < top.size(); i++) {
            if (i > 0) sb.append(",");
            Object nameObj = top.get(i).get("name");
            String n = nameObj != null ? nameObj.toString() : "";
            if (n.length() > 18) n = n.substring(0, 18) + "…";
            sb.append("\"").append(escapeJs(n)).append("\"");
        }
        return sb.toString();
    }

    /** [10,8,...] data for donut chart */
    private String buildDData(DashboardDTO dd) {
        List<Map<String, Object>> top = dd.getTopCourses();
        if (top == null || top.isEmpty()) return "1";
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < top.size(); i++) {
            if (i > 0) sb.append(",");
            Object val = top.get(i).get("total");
            sb.append(val != null ? val : 0);
        }
        return sb.toString();
    }

    /** ["Jan 2026","Feb 2026",...] month labels for line/bar charts */
    private String buildJsMonths(DashboardDTO dd) {
        List<Map<String, Object>> ds = dd.getMonthlyDetailedStats();
        if (ds == null || ds.isEmpty()) return "\"T1\",\"T2\",\"T3\",\"T4\",\"T5\",\"T6\"";
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < ds.size(); i++) {
            if (i > 0) sb.append(",");
            Object val = ds.get(i).get("month_label");
            sb.append("\"").append(val != null ? escapeJs(val.toString()) : "").append("\"");
        }
        return sb.toString();
    }

    private String buildJsEnroll(DashboardDTO dd) {
        return buildNumericArray(dd.getMonthlyDetailedStats(), "enrollments", "0,0,0,0,0,0");
    }

    private String buildJsStudents(DashboardDTO dd) {
        return buildNumericArray(dd.getMonthlyDetailedStats(), "new_students", "0,0,0,0,0,0");
    }

    private String buildJsTeachers(DashboardDTO dd) {
        return buildNumericArray(dd.getMonthlyDetailedStats(), "new_teachers", "0,0,0,0,0,0");
    }

    private String buildNumericArray(List<Map<String, Object>> list, String key, String fallback) {
        if (list == null || list.isEmpty()) return fallback;
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < list.size(); i++) {
            if (i > 0) sb.append(",");
            Object val = list.get(i).get(key);
            sb.append(val != null ? val : 0);
        }
        return sb.toString();
    }

    /** Escape single quotes and backslashes for safe JS string embedding */
    private String escapeJs(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("'", "\\'").replace("\"", "\\\"").replace("\n", " ").replace("\r", "");
    }
}