package com.example.demo.controller;

import com.example.demo.dto.CourseDTO;
import com.example.demo.dto.RegisterRequest;
import com.example.demo.dto.TeacherReviewDTO;
import com.example.demo.entity.User;
import com.example.demo.service.CourseService;
import com.example.demo.service.EnrollmentService;
import com.example.demo.service.TeacherReviewService;
import com.example.demo.service.UserService;

import jakarta.servlet.http.HttpSession;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.List;

@Controller
public class HomeController {

    @Autowired private UserService          userService;
    @Autowired private CourseService        courseService;
    @Autowired private EnrollmentService    enrollmentService;
    @Autowired private TeacherReviewService reviewService;

    // ─── Root ─────────────────────────────────────────────────────────────
    @GetMapping("/")
    public String index(HttpSession session) {
        User user = (User) session.getAttribute("user");
        if (user == null) return "redirect:/home";
        String role = user.getRole() != null ? user.getRole().toLowerCase() : "";
        if ("student".equals(role)) return "redirect:/home";
        return "redirect:/dashboard";
    }

    // ─── Login ────────────────────────────────────────────────────────────
    // NOTE: POST /login จัดการโดย Spring Security อัตโนมัติ
    //       หลัง login สำเร็จ SessionSyncFilter จะ sync session["user"] ให้
    @GetMapping("/login")
    public String showLogin(@RequestParam(required = false) String error,
                            @RequestParam(required = false) String setup,
                            @RequestParam(required = false) String registered,
                            HttpSession session,
                            Model model) {
        // ถ้า login แล้วไม่ต้องแสดงหน้า login ซ้ำ
        User user = (User) session.getAttribute("user");
        if (user != null) {
            String role = user.getRole() != null ? user.getRole().toLowerCase() : "";
            return "student".equals(role) ? "redirect:/home" : "redirect:/dashboard";
        }

        if (error != null) {
            model.addAttribute("error", "Tên đăng nhập hoặc mật khẩu không đúng");
        }
        if ("done".equals(setup)) {
            model.addAttribute("success", "Tạo Super Admin thành công! Vui lòng đăng nhập.");
        }
        if ("1".equals(registered)) {
            model.addAttribute("success", "Đăng ký thành công! Vui lòng đăng nhập.");
        } else if ("2".equals(registered)) {
            model.addAttribute("success", "Đăng ký thành công! Tài khoản giáo viên đang chờ phê duyệt.");
        }

        return "login";
    }

    // ─── Register ─────────────────────────────────────────────────────────
    @GetMapping("/register")
    public String showRegister(HttpSession session) {
        User user = (User) session.getAttribute("user");
        if (user != null) return "redirect:/dashboard";
        return "register";
    }

    @PostMapping("/register")
    public String doRegister(@ModelAttribute RegisterRequest req, Model model) {
        if (req.getUsername() == null || req.getUsername().trim().isEmpty()
                || req.getPassword() == null || req.getPassword().isEmpty()) {
            model.addAttribute("error", "Vui lòng điền đầy đủ thông tin");
            return "register";
        }
        if (!req.getPassword().equals(req.getConfirmPassword())) {
            model.addAttribute("error", "Mật khẩu không khớp");
            return "register";
        }
        boolean ok = userService.register(req);
        if (!ok) {
            model.addAttribute("error", "Tên đăng nhập đã tồn tại");
            return "register";
        }
        String type = "TEACHER".equalsIgnoreCase(req.getRole()) ? "2" : "1";
        return "redirect:/login?registered=" + type;
    }

    // ─── Home (Landing Page) ──────────────────────────────────────────────
    @GetMapping("/home")
    public String home(HttpSession session, Model model) {
        User user = (User) session.getAttribute("user");
        model.addAttribute("user", user);

        List<CourseDTO> allCourses = courseService.getAllCourses();
        model.addAttribute("allCourses", allCourses);

        long activeCourseCount = allCourses.stream()
                .filter(CourseDTO::isActive).count();
        model.addAttribute("activeCourseCount", activeCourseCount);

        if (user != null && "STUDENT".equalsIgnoreCase(user.getRole())) {
            List<Integer> enrolledIds = enrollmentService.getEnrolledCourseIds(user.getId());
            List<CourseDTO> enrolledCourses = new ArrayList<>();
            for (CourseDTO c : allCourses) {
                if (enrolledIds.contains(c.getId())) enrolledCourses.add(c);
            }
            model.addAttribute("enrolledCourses", enrolledCourses);
            model.addAttribute("enrolledCount", enrolledCourses.size());

            List<TeacherReviewDTO> myReviews = new ArrayList<>();
            for (CourseDTO c : enrolledCourses) {
                List<TeacherReviewDTO> courseReviews = reviewService.getReviewsByCourse(c.getId());
                for (TeacherReviewDTO r : courseReviews) {
                    if (r.getStudentId() != null && r.getStudentId().equals(user.getId())) {
                        myReviews.add(r);
                    }
                }
            }
            model.addAttribute("myReviews", myReviews);
        }

        return "home";
    }
}