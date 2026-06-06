package com.example.demo.controller;

import com.example.demo.dto.CourseDTO;
import com.example.demo.dto.HomeworkDTO;
import com.example.demo.entity.User;
import com.example.demo.service.CourseService;
import com.example.demo.service.EnrollmentService;
import com.example.demo.service.HomeworkService;

import jakarta.servlet.http.HttpSession;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.*;
import java.nio.file.*;
import java.util.Optional;
import java.util.UUID;

/**
 * HomeworkController — จัดการการส่งการบ้านของนักเรียน และอัปโหลดไฟล์การบ้านของครู
 *
 * action=submit         → นักเรียนส่งการบ้าน (พร้อมแนบไฟล์)
 * action=uploadTeacher  → teacher/admin อัปโหลดไฟล์การบ้านให้นักเรียน
 * action=markReviewed   → ครูตรวจการบ้าน + ให้คะแนน (ใหม่)
 * action=deleteHomework → ลบไฟล์การบ้าน
 */
@Controller
@RequestMapping("/homework")
public class HomeworkController {

    private static final String UPLOAD_DIR = "homework_uploads";

    @Value("${app.upload.base-dir:#{systemProperties['user.dir']}}")
    private String uploadBaseDir;

    @Autowired private HomeworkService   homeworkService;
    @Autowired private CourseService     courseService;
    @Autowired private EnrollmentService enrollmentService;

    @PostMapping
    public String doPost(@RequestParam(required = false) String       action,
                         @RequestParam(required = false) Integer      courseId,
                         @RequestParam(required = false) Integer      videoId,
                         @RequestParam(required = false) Integer      hwId,
                         @RequestParam(required = false) String       hwTitle,
                         @RequestParam(required = false) String       hwDesc,
                         @RequestParam(required = false) String       teacherComment,
                         // ─── พารามิเตอร์ใหม่: คะแนน ───────────────────
                         @RequestParam(required = false) Integer      score,
                         @RequestParam(required = false) Integer      maxScore,
                         // ──────────────────────────────────────────────
                         @RequestParam(required = false) MultipartFile hwFile,
                         HttpSession session) throws IOException {

        User user = (User) session.getAttribute("user");
        if (user == null) return "redirect:/login";

        String  role      = user.getRole().toLowerCase();
        boolean isStudent = role.equals("student");
        boolean isStaff   = role.equals("teacher") || role.equals("admin") || role.equals("super_admin");

        int cId = courseId != null ? courseId : 0;
        int vId = videoId  != null ? videoId  : 0;
        String classroomBase = "redirect:/classroom?courseId=" + cId;

        // ── ครูตรวจการบ้าน → REVIEWED + feedback + คะแนน ────────────────
        if ("markReviewed".equals(action)) {
            if (!isStaff) {
                session.setAttribute("classroomError", "Chỉ dành cho giảng viên và quản trị viên");
                return classroomBase + "&tab=homework";
            }
            if (hwId == null || hwId <= 0) {
                session.setAttribute("classroomError", "Không tìm thấy bài tập cần chấm");
                return classroomBase + "&tab=homework";
            }

            // validate คะแนน (ถ้าครูกรอกมา)
            if (score != null) {
                int mx = (maxScore != null && maxScore > 0) ? maxScore : 100;
                if (score < 0 || score > mx) {
                    session.setAttribute("classroomError",
                            "Điểm không hợp lệ: phải từ 0 đến " + mx);
                    return classroomBase + "&tab=homework";
                }
            }

            boolean ok = homeworkService.markReviewed(hwId, teacherComment, score,
                    maxScore != null && maxScore > 0 ? maxScore : 100);

            if (ok) {
                String msg = "Đã chấm xong bài tập ✓";
                if (score != null) {
                    int mx = maxScore != null && maxScore > 0 ? maxScore : 100;
                    msg += "  —  Điểm: " + score + "/" + mx;
                }
                session.setAttribute("classroomSuccess", msg);
            } else {
                session.setAttribute("classroomError", "Không thể lưu");
            }
            return classroomBase + "&tab=homework";
        }

        // ── ลบไฟล์การบ้าน ────────────────────────────────────────────────
        if ("deleteHomework".equals(action)) {
            if (!isStaff) {
                session.setAttribute("classroomError", "Không có quyền xóa tệp bài tập");
                return classroomBase + "&tab=homework";
            }
            if (hwId == null || hwId <= 0) {
                session.setAttribute("classroomError", "Không tìm thấy tệp bài tập cần xóa");
                return classroomBase + "&tab=homework";
            }
            Optional<HomeworkDTO> existing = homeworkService.getById(hwId);
            if (existing.isPresent() && existing.get().getFilePath() != null && !existing.get().getFilePath().isEmpty()) {
                try { Files.deleteIfExists(Paths.get(existing.get().getFilePath()).toAbsolutePath().normalize()); } catch (Exception ignored) {}
            }
            boolean ok = homeworkService.deleteHomework(hwId);
            session.setAttribute(ok ? "classroomSuccess" : "classroomError",
                    ok ? "Đã xóa tệp bài tập thành công" : "Không thể xóa tệp bài tập");
            return classroomBase + "&tab=homework";
        }

        // ── ครู/admin อัปโหลดไฟล์การบ้านให้นักเรียน ─────────────────────
        if ("uploadTeacher".equals(action)) {
            if (!isStaff) {
                session.setAttribute("classroomError", "Chỉ giảng viên và quản trị viên mới có thể tải lên tệp bài tập");
                return classroomBase + "&tab=homework";
            }
            if (cId <= 0) return "redirect:/dashboard?tab=courses&err=invalidCourse";

            Optional<CourseDTO> courseOpt = courseService.getCourseById(cId);
            boolean isOwner = courseOpt.isPresent() && (
                    role.equals("admin") || role.equals("super_admin") ||
                    (courseOpt.get().getTeacherId() != null && courseOpt.get().getTeacherId().equals(user.getId()))
            );
            if (!isOwner) {
                session.setAttribute("classroomError", "Bạn không có quyền quản lý bài tập của khóa học này");
                return classroomBase + "&tab=homework";
            }
            if (hwTitle == null || hwTitle.trim().isEmpty()) {
                session.setAttribute("classroomError", "Vui lòng chỉ định tiêu đề tệp bài tập");
                return classroomBase + "&tab=homework";
            }

            String savedPath = null;
            String origName  = null;
            if (hwFile != null && !hwFile.isEmpty()) {
                origName  = hwFile.getOriginalFilename();
                savedPath = saveFile(hwFile);
            }

            boolean ok = homeworkService.submitHomework(user.getId(), cId, vId > 0 ? vId : 0,
                    hwTitle.trim(), hwDesc != null ? hwDesc.trim() : "", savedPath, origName);

            session.setAttribute(ok ? "classroomSuccess" : "classroomError",
                    ok ? "Đã tải lên tệp bài tập \"" + hwTitle.trim() + "\" thành công! 📂"
                       : "Không thể tải lên tệp bài tập, vui lòng thử lại");
            return classroomBase + "&tab=homework";
        }

        // ── นักเรียนส่งการบ้าน ────────────────────────────────────────────
        if (!isStudent) {
            session.setAttribute("classroomError", "Chỉ học viên mới có thể nộp bài tập");
            return classroomBase + "&tab=homework";
        }
        if (cId <= 0) return "redirect:/dashboard?tab=courses&err=invalidCourse";

        if (!enrollmentService.isEnrolled(user.getId(), cId)) {
            session.setAttribute("classroomError", "Bạn chưa đăng ký khóa học này");
            return classroomBase + (vId > 0 ? "&videoId=" + vId : "");
        }

        String redirectUrl = classroomBase + (vId > 0 ? "&videoId=" + vId : "") + "&tab=homework";

        if ("submit".equals(action)) {
            if (hwTitle == null || hwTitle.trim().isEmpty()) {
                session.setAttribute("classroomError", "Vui lòng chỉ định tiêu đề bài tập");
                return redirectUrl;
            }

            String savedPath = null;
            String origName  = null;
            if (hwFile != null && !hwFile.isEmpty()) {
                origName  = hwFile.getOriginalFilename();
                savedPath = saveFile(hwFile);
            }

            boolean ok = homeworkService.submitHomework(user.getId(), cId, vId,
                    hwTitle.trim(), hwDesc != null ? hwDesc.trim() : "", savedPath, origName);

            session.setAttribute(ok ? "classroomSuccess" : "classroomError",
                    ok ? "Đã nộp bài tập \"" + hwTitle.trim() + "\" thành công! 🎉"
                       : "Không thể nộp bài tập, vui lòng thử lại");
        }

        return redirectUrl;
    }

    private String saveFile(MultipartFile file) throws IOException {
        String original = file.getOriginalFilename() != null ? file.getOriginalFilename() : "file";
        String ext = original.contains(".") ? original.substring(original.lastIndexOf('.')).toLowerCase() : "";
        ext = ext.replaceAll("[^a-zA-Z0-9.]", "");
        String unique = UUID.randomUUID().toString().replace("-", "") + ext;

        Path destDir = Paths.get(uploadBaseDir, UPLOAD_DIR).toAbsolutePath().normalize();
        if (!Files.exists(destDir)) {
            Files.createDirectories(destDir);
        }

        Path destFile = destDir.resolve(unique);
        file.transferTo(destFile.toFile());

        return UPLOAD_DIR + "/" + unique;
    }
}
