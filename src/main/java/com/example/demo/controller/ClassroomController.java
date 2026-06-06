package com.example.demo.controller;

import com.example.demo.dto.CourseDTO;
import com.example.demo.dto.HomeworkDTO;
import com.example.demo.dto.TeacherReviewDTO;
import com.example.demo.dto.VideoDTO;
import com.example.demo.entity.User;
import com.example.demo.service.CourseService;
import com.example.demo.service.EnrollmentService;
import com.example.demo.service.HomeworkService;
import com.example.demo.service.TeacherReviewService;
import com.example.demo.service.VideoService;
import com.example.demo.service.UserService;

import jakarta.servlet.http.HttpSession;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

/**
 * ClassroomController — ห้องเรียนสำหรับดูวิดีโอในคอร์ส
 * URL: /classroom?courseId=X[&videoId=Y]
 *
 * GET  → แสดงหน้าห้องเรียนพร้อมเล่นวิดีโอ
 * POST → จัดการวิดีโอโดย teacher/admin (addVideo, editVideo, deleteVideo)
 */
@Controller
@RequestMapping("/classroom")
public class ClassroomController {

    @Autowired private CourseService      courseService;
    @Autowired private UserService         userService;
    @Autowired private VideoService       videoService;
    @Autowired private EnrollmentService  enrollmentService;
    @Autowired private HomeworkService    homeworkService;
    @Autowired private TeacherReviewService reviewService;

    // ─────────────────────────── GET ───────────────────────────────────────

    @GetMapping
    public String doGet(@RequestParam(required = false) Integer courseId,
                        @RequestParam(required = false) Integer videoId,
                        HttpSession session,
                        Model model) {

        // ── ตรวจ Session ──────────────────────────────────────────────────
        User user = (User) session.getAttribute("user");
        if (user == null) return "redirect:/login";

        // ── ตรวจ courseId ─────────────────────────────────────────────────
        if (courseId == null || courseId <= 0)
            return "redirect:/dashboard?tab=courses&err=invalidCourse";

        Optional<CourseDTO> courseOpt = courseService.getCourseById(courseId);
        if (courseOpt.isEmpty())
            return "redirect:/dashboard?tab=courses&err=notFound";

        CourseDTO course = courseOpt.get();

        // ── ตรวจสิทธิ์ ────────────────────────────────────────────────────
        String  role     = user.getRole().toLowerCase();
        boolean isStaff  = role.equals("teacher") || role.equals("admin") || role.equals("super_admin");
        boolean enrolled = enrollmentService.isEnrolled(user.getId(), courseId);

        // Remove the redirect to dashboard for un-enrolled students
        // classroom.jsp already handles showing an enroll button for them.

        boolean isOwner = isStaff && (
                role.equals("admin") || role.equals("super_admin") ||
                        (course.getTeacherId() != null && course.getTeacherId().equals(user.getId()))
        );

        // ── ดึงรายการวิดีโอ ──────────────────────────────────────────────
        List<VideoDTO> videos = videoService.getVideosByCourse(courseId);

        // ── เลือกวิดีโอที่จะเล่น ─────────────────────────────────────────
        VideoDTO currentVideo = null;
        if (videoId != null && videoId > 0) {
            for (VideoDTO v : videos) {
                if (v.getId().equals(videoId)) { currentVideo = v; break; }
            }
        }
        if (currentVideo == null && !videos.isEmpty()) {
            currentVideo = videos.get(0);
        }

        // ── Flash messages จาก Post-Redirect-Get ─────────────────────────
        String flashSuccess = (String) session.getAttribute("classroomSuccess");
        String flashError   = (String) session.getAttribute("classroomError");
        session.removeAttribute("classroomSuccess");
        session.removeAttribute("classroomError");

        // ── ดึงการบ้าน ────────────────────────────────────────────────────
        List<HomeworkDTO> myHomeworks  = new ArrayList<>();
        List<HomeworkDTO> allHomeworks = new ArrayList<>();
        List<HomeworkDTO> teacherFiles = new ArrayList<>();

        int teacherId = course.getTeacherId() != null ? course.getTeacherId() : 0;

        if (enrolled && !isStaff) {
            myHomeworks  = homeworkService.getByStudentAndCourse(user.getId(), courseId);
            teacherFiles = homeworkService.getAllTeacherFiles(courseId);
        }
        if (isOwner) {
            teacherFiles = homeworkService.getTeacherFiles(courseId, user.getId());
            allHomeworks = homeworkService.getStudentsByCourse(courseId, teacherId);
        } else if (isStaff) {
            teacherFiles = homeworkService.getAllTeacherFiles(courseId);
            allHomeworks = homeworkService.getStudentsByCourse(courseId, teacherId);
        }

        int enrollCount = enrollmentService.countEnrollmentsByCourse(courseId);

        // ── ดึงข้อมูลรีวิวครู ─────────────────────────────────────────────
        int teacherIdForReview = course.getTeacherId() != null ? course.getTeacherId() : 0;
        java.util.List<TeacherReviewDTO> courseReviews = reviewService.getReviewsByCourse(courseId);
        double avgRating = teacherIdForReview > 0 ? reviewService.getAverageRating(teacherIdForReview) : 0.0;
        long reviewCount = teacherIdForReview > 0 ? reviewService.getReviewCount(teacherIdForReview) : 0;
        boolean alreadyReviewed = enrolled && !isStaff && teacherIdForReview > 0
                ? reviewService.hasReviewed(user.getId(), teacherIdForReview, courseId)
                : false;

        model.addAttribute("course",       course);
        model.addAttribute("videos",       videos);
        model.addAttribute("currentVideo", currentVideo);
        model.addAttribute("enrolled",     enrolled);
        model.addAttribute("isStaff",      isStaff);
        model.addAttribute("isOwner",      isOwner);
        model.addAttribute("enrollCount",  enrollCount);
        model.addAttribute("myHomeworks",  myHomeworks);
        model.addAttribute("allHomeworks", allHomeworks);
        model.addAttribute("teacherFiles", teacherFiles);
        model.addAttribute("user",         user);
        model.addAttribute("flashSuccess", flashSuccess);
        model.addAttribute("flashError",   flashError);
        model.addAttribute("courseReviews",    courseReviews);
        model.addAttribute("avgRating",        avgRating);
        model.addAttribute("reviewCount",      reviewCount);
        model.addAttribute("alreadyReviewed",  alreadyReviewed);
        model.addAttribute("teacherIdForReview", teacherIdForReview);

        // ── ดึงรูปโปรไฟล์ครู ─────────────────────────────────────────────
        String teacherPhoto = "";
        if (teacherIdForReview > 0) {
            java.util.Optional<User> teacherOpt = userService.findById(teacherIdForReview);
            if (teacherOpt.isPresent() && teacherOpt.get().getProfilePhoto() != null) {
                teacherPhoto = teacherOpt.get().getProfilePhoto();
            }
        }
        model.addAttribute("teacherPhoto", teacherPhoto);

        return "classroom"; // maps to /classroom.jsp
    }

    // ─────────────────────────── POST ──────────────────────────────────────

    @PostMapping
    public String doPost(@RequestParam(required = false) Integer courseId,
                         @RequestParam(required = false) String  videoAction,
                         @RequestParam(required = false) Integer videoId,
                         @RequestParam(required = false) String  videoTitle,
                         @RequestParam(required = false) String  videoDesc,
                         @RequestParam(required = false) String  videoUrl,
                         HttpSession session) {

        User user = (User) session.getAttribute("user");
        if (user == null) return "redirect:/login";

        String  role    = user.getRole().toLowerCase();
        boolean isStaff = role.equals("teacher") || role.equals("admin") || role.equals("super_admin");
        if (!isStaff)
            return "redirect:/dashboard?tab=courses&err=noPermission";

        if (courseId == null || courseId <= 0)
            return "redirect:/dashboard?tab=courses&err=invalidCourse";

        Optional<CourseDTO> courseOpt = courseService.getCourseById(courseId);
        if (courseOpt.isEmpty())
            return "redirect:/dashboard?tab=courses&err=notFound";

        CourseDTO course = courseOpt.get();
        boolean isOwner = role.equals("admin") || role.equals("super_admin")
                || (course.getTeacherId() != null && course.getTeacherId().equals(user.getId()));

        if (!isOwner) {
            session.setAttribute("classroomError", "Bạn không có quyền quản lý bài giảng của khóa học này");
            return "redirect:/classroom?courseId=" + courseId;
        }

        String redirectUrl = "redirect:/classroom?courseId=" + courseId;

        try {
            if ("addVideo".equals(videoAction)) {
                if (videoTitle == null || videoTitle.trim().isEmpty()) {
                    session.setAttribute("classroomError", "Vui lòng nhập tên bài học");
                    return redirectUrl;
                }
                if (videoUrl == null || videoUrl.trim().isEmpty()) {
                    session.setAttribute("classroomError", "Vui lòng nhập URL video");
                    return redirectUrl;
                }
                boolean ok = videoService.addVideo(courseId, videoTitle.trim(),
                        videoDesc != null ? videoDesc.trim() : "", videoUrl.trim());
                session.setAttribute(ok ? "classroomSuccess" : "classroomError",
                        ok ? "Thêm bài học \"" + videoTitle.trim() + "\" thành công!"
                                : "Không thể thêm bài học, vui lòng thử lại");

            } else if ("editVideo".equals(videoAction)) {
                if (videoId == null || videoId <= 0 || videoTitle == null || videoTitle.trim().isEmpty()
                        || videoUrl == null || videoUrl.trim().isEmpty()) {
                    session.setAttribute("classroomError", "Thông tin không đầy đủ");
                    return redirectUrl + (videoId != null ? "&videoId=" + videoId : "");
                }
                boolean ok = videoService.updateVideo(videoId, videoTitle.trim(),
                        videoDesc != null ? videoDesc.trim() : "", videoUrl.trim());
                session.setAttribute(ok ? "classroomSuccess" : "classroomError",
                        ok ? "Sửa bài học thành công!" : "Không thể sửa bài học");
                return redirectUrl + "&videoId=" + videoId;

            } else if ("deleteVideo".equals(videoAction)) {
                if (videoId == null || videoId <= 0) {
                    session.setAttribute("classroomError", "Không tìm thấy bài học cần xóa");
                    return redirectUrl;
                }
                boolean ok = videoService.deleteVideo(videoId);
                session.setAttribute(ok ? "classroomSuccess" : "classroomError",
                        ok ? "Xóa bài học thành công!" : "Không thể xóa bài học");
            }

        } catch (Exception ex) {
            ex.printStackTrace();
            session.setAttribute("classroomError", "Đã xảy ra lỗi hệ thống, vui lòng thử lại");
        }

        return redirectUrl;
    }
}