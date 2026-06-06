package com.example.demo.controller;

import com.example.demo.entity.User;
import com.example.demo.service.CourseService;
import com.example.demo.service.EnrollmentService;
import com.example.demo.service.TeacherReviewService;

import jakarta.servlet.http.HttpSession;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.*;

/**
 * TeacherReviewController — Quản lý đánh giá giảng viên
 *
 * POST /teacher-review
 *   action=submit  → Học viên gửi đánh giá
 *   action=delete  → Xóa đánh giá của chính mình
 */
@Controller
@RequestMapping("/teacher-review")
public class TeacherReviewController {

    @Autowired private TeacherReviewService reviewService;
    @Autowired private CourseService        courseService;
    @Autowired private EnrollmentService    enrollmentService;

    @PostMapping
    public String doPost(@RequestParam(required = false) String  action,
                         @RequestParam(required = false) Integer courseId,
                         @RequestParam(required = false) Integer teacherId,
                         @RequestParam(required = false) Integer rating,
                         @RequestParam(required = false) String  comment,
                         @RequestParam(required = false) Integer reviewId,
                         HttpSession session) {

        User user = (User) session.getAttribute("user");
        if (user == null) return "redirect:/login";

        String role        = user.getRole().toLowerCase();
        String redirectBase = "redirect:/classroom?courseId=" + (courseId != null ? courseId : 0) + "&tab=review";

        // ── Gửi đánh giá ─────────────────────────────────────────────────
        if ("submit".equals(action)) {
            if (!role.equals("student")) {
                session.setAttribute("classroomError", "Chỉ học viên mới có thể đánh giá giảng viên");
                return redirectBase;
            }
            if (courseId == null || courseId <= 0 || teacherId == null || teacherId <= 0) {
                session.setAttribute("classroomError", "Thông tin không hợp lệ, vui lòng thử lại");
                return redirectBase;
            }
            // Phải đăng ký khóa học trước
            if (!enrollmentService.isEnrolled(user.getId(), courseId)) {
                session.setAttribute("classroomError", "Bạn phải đăng ký khóa học trước khi đánh giá");
                return redirectBase;
            }
            if (rating == null || rating < 1 || rating > 5) {
                session.setAttribute("classroomError", "Vui lòng chọn số sao từ 1 đến 5");
                return redirectBase;
            }

            boolean ok = reviewService.submitReview(user.getId(), teacherId, courseId, rating, comment);
            session.setAttribute(ok ? "classroomSuccess" : "classroomError",
                    ok ? "Cảm ơn bạn đã đánh giá giảng viên! ⭐"
                       : "Không thể lưu đánh giá, vui lòng thử lại");
            return redirectBase;
        }

        // ── Xóa đánh giá ─────────────────────────────────────────────────
        if ("delete".equals(action)) {
            if (reviewId == null || reviewId <= 0) {
                session.setAttribute("classroomError", "Không tìm thấy đánh giá cần xóa");
                return redirectBase;
            }
            boolean ok = reviewService.deleteReview(reviewId, user.getId());
            session.setAttribute(ok ? "classroomSuccess" : "classroomError",
                    ok ? "Đã xóa đánh giá thành công"
                       : "Không thể xóa đánh giá, vui lòng thử lại");
            return redirectBase;
        }

        return redirectBase;
    }
}
