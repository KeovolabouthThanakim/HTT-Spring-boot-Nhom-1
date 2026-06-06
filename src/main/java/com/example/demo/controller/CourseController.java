package com.example.demo.controller;

import com.example.demo.dto.CourseDTO;
import com.example.demo.dto.HomeworkDTO;
import com.example.demo.dto.VideoDTO;
import com.example.demo.entity.User;
import com.example.demo.repository.UserRepository;
import com.example.demo.service.CourseService;
import com.example.demo.service.HomeworkService;
import com.example.demo.service.VideoService;

import jakarta.servlet.http.HttpSession;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.*;
import java.nio.file.*;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

@Controller
@RequestMapping("/course-manage")
public class CourseController {

    // ── Allowed file-type whitelists ───────────────────────────────────────
    /** Allowed extensions for video uploads */
    private static final Set<String> ALLOWED_VIDEO_EXTS =
            Set.of(".mp4", ".mov", ".avi", ".mkv", ".webm");

    /** Allowed extensions for homework/document uploads */
    private static final Set<String> ALLOWED_HW_EXTS =
            Set.of(".pdf", ".doc", ".docx", ".ppt", ".pptx", ".xls", ".xlsx",
                    ".txt", ".zip", ".jpg", ".jpeg", ".png");

    /** Maximum single-file size in bytes (5 MB — mirrors multipart config) */
    private static final long MAX_FILE_BYTES = 5L * 1024 * 1024;

    // ── Upload base directory (absolute, injected from application.properties) ─
    @Value("${app.upload.base-dir:#{systemProperties['user.home']}/lms-uploads}")
    private String uploadBaseDir;

    @Autowired private CourseService   courseService;
    @Autowired private VideoService    videoService;
    @Autowired private HomeworkService homeworkService;
    @Autowired private UserRepository  userRepository;

    @PostMapping
    public String doPost(@RequestParam(required = false) String courseAction,
                         @RequestParam(required = false) Integer courseId,
                         @RequestParam(required = false) String  courseName,
                         @RequestParam(required = false) String  courseDesc,
                         @RequestParam(required = false) String  courseCategory,
                         @RequestParam(required = false) String  courseStatus,
                         // video params
                         @RequestParam(required = false) Integer videoId,
                         @RequestParam(required = false) String  videoTitle,
                         @RequestParam(required = false) String  videoDesc,
                         @RequestParam(required = false) String  videoUrl,
                         @RequestParam(required = false) MultipartFile videoFile,
                         // homework params
                         @RequestParam(required = false) Integer hwId,
                         @RequestParam(required = false) String  hwTitle,
                         @RequestParam(required = false) String  hwDesc,
                         @RequestParam(required = false) MultipartFile hwFile,
                         HttpSession session) throws IOException {

        User user = (User) session.getAttribute("user");
        if (user == null) return "redirect:/login";

        String  role       = user.getRole() != null ? user.getRole().toLowerCase() : "";
        boolean canManage  = role.equals("teacher") || role.equals("admin") || role.equals("super_admin");
        if (!canManage) return "redirect:/dashboard?tab=manage-courses&err=noPermission";

        String redirectBase = "redirect:/dashboard?tab=manage-courses";

        try {
            // ── เพิ่มคอร์ส ────────────────────────────────────────────────
            if ("addCourse".equals(courseAction)) {
                if (courseName == null || courseName.trim().isEmpty())
                    return redirectBase + "&err=nameRequired";

                // Reload user fresh from DB — session อาจเก็บ detached entity
                // ที่ ID ถูกต้องแต่ Hibernate ไม่รู้จักแล้ว ทำให้ userRepository.findById() คืน empty
                Integer userId = user.getId();
                if (userId == null || userId <= 0)
                    return redirectBase + "&err=invalidUser";

                User freshUser = userRepository.findById(userId).orElse(null);
                if (freshUser == null)
                    return redirectBase + "&err=invalidUser";

                // รีเฟรช session ด้วย user ใหม่จาก DB
                session.setAttribute("user", freshUser);

                int newId = courseService.addCourse(courseName.trim(),
                        courseDesc != null ? courseDesc.trim() : "",
                        notEmpty(courseCategory, "General"),
                        notEmpty(courseStatus, "ACTIVE"),
                        freshUser.getId());

                if (newId > 0) {
                    return redirectBase + "&success=courseAdded&openCourse=" + newId;
                } else {
                    return redirectBase + "&err=addFailed";
                }

                // ── แก้ไขคอร์ส ────────────────────────────────────────────────
            } else if ("editCourse".equals(courseAction)) {
                if (courseId == null || courseId <= 0 || courseName == null || courseName.trim().isEmpty())
                    return redirectBase + "&err=invalidInput";

                boolean ok = courseService.updateCourse(courseId, courseName.trim(),
                        courseDesc != null ? courseDesc.trim() : "",
                        notEmpty(courseCategory, "General"),
                        notEmpty(courseStatus, "ACTIVE"));
                return redirectBase + (ok ? "&success=courseUpdated" : "&err=updateFailed");

                // ── ลบคอร์ส ───────────────────────────────────────────────────
            } else if ("deleteCourse".equals(courseAction)) {
                if (courseId == null || courseId <= 0)
                    return redirectBase + "&err=invalidId";

                String videoDir = resolveDir("uploads/videos");
                List<VideoDTO> videos = videoService.getVideosByCourse(courseId);
                for (VideoDTO v : videos) {
                    deleteFileIfLocal(v.getFilePath(), videoDir);
                }
                boolean ok = courseService.deleteCourse(courseId);
                return redirectBase + (ok ? "&success=courseDeleted" : "&err=deleteFailed");

                // ── อัปโหลดวิดีโอ ─────────────────────────────────────────────
            } else if ("uploadVideo".equals(courseAction)) {
                if (courseId == null || courseId <= 0 || videoTitle == null || videoTitle.trim().isEmpty())
                    return redirectBase + "&err=videoInputRequired&openCourse=" + courseId;

                String resolvedUrl;
                if (videoFile != null && !videoFile.isEmpty()) {
                    String extErr = validateFile(videoFile, ALLOWED_VIDEO_EXTS);
                    if (extErr != null) return redirectBase + "&err=" + extErr + "&openCourse=" + courseId;
                    resolvedUrl = saveFile(videoFile, "uploads/videos");
                } else {
                    if (videoUrl == null || videoUrl.trim().isEmpty())
                        return redirectBase + "&err=noVideoSource&openCourse=" + courseId;
                    resolvedUrl = videoUrl.trim();
                }

                boolean ok = videoService.addVideo(courseId, videoTitle.trim(),
                        videoDesc != null ? videoDesc.trim() : "", resolvedUrl);
                return redirectBase + (ok ? "&success=videoUploaded" : "&err=videoFailed") + "&openCourse=" + courseId;

                // ── แก้ไขวิดีโอ ───────────────────────────────────────────────
            } else if ("editVideo".equals(courseAction)) {
                if (videoId == null || videoId <= 0 || videoTitle == null || videoTitle.trim().isEmpty())
                    return redirectBase + "&err=videoInputRequired&openCourse=" + courseId;

                boolean ok = videoService.updateVideo(videoId, videoTitle.trim(),
                        videoDesc != null ? videoDesc.trim() : "",
                        videoUrl  != null ? videoUrl.trim()  : "");
                return redirectBase + (ok ? "&success=videoUpdated" : "&err=videoUpdateFailed") + "&openCourse=" + courseId;

                // ── ลบวิดีโอ ──────────────────────────────────────────────────
            } else if ("deleteVideo".equals(courseAction)) {
                if (videoId == null || videoId <= 0)
                    return redirectBase + "&err=invalidVideoId";

                String videoDir = resolveDir("uploads/videos");
                Optional<VideoDTO> vOpt = videoService.getVideoById(videoId);
                vOpt.ifPresent(v -> deleteFileIfLocal(v.getFilePath(), videoDir));

                boolean ok = videoService.deleteVideo(videoId);
                return redirectBase + (ok ? "&success=videoDeleted" : "&err=videoDeleteFailed") + "&openCourse=" + courseId;

                // ── ครู/Admin อัปโหลดไฟล์การบ้าน ─────────────────────────────
            } else if ("uploadHomework".equals(courseAction)) {
                if (courseId == null || courseId <= 0 || hwTitle == null || hwTitle.trim().isEmpty())
                    return redirectBase + "&err=hwInvalidData";

                String savedPath = null;
                String origName  = null;
                if (hwFile != null && !hwFile.isEmpty()) {
                    String extErr = validateFile(hwFile, ALLOWED_HW_EXTS);
                    if (extErr != null) return redirectBase + "&err=" + extErr;
                    origName  = hwFile.getOriginalFilename();
                    savedPath = saveFile(hwFile, "homework_uploads");
                }

                boolean ok = homeworkService.submitHomework(user.getId(), courseId, 0,
                        hwTitle.trim(), hwDesc != null ? hwDesc.trim() : "", savedPath, origName);
                return redirectBase + (ok ? "&success=hwUploaded" : "&err=hwFailed");

                // ── แก้ไขการบ้าน ──────────────────────────────────────────────
            } else if ("editHomework".equals(courseAction)) {
                if (hwId == null || hwId <= 0 || hwTitle == null || hwTitle.trim().isEmpty())
                    return redirectBase + "&err=hwInvalidData";

                Optional<HomeworkDTO> existingOpt = homeworkService.getById(hwId);
                if (existingOpt.isEmpty()) return redirectBase + "&err=hwNotFound";

                String savedPath = null;
                String origName  = null;
                if (hwFile != null && !hwFile.isEmpty()) {
                    String extErr = validateFile(hwFile, ALLOWED_HW_EXTS);
                    if (extErr != null) return redirectBase + "&err=" + extErr + "&openCourse=" + courseId;
                    origName = hwFile.getOriginalFilename();
                    // Delete the old file before saving the replacement
                    HomeworkDTO existing = existingOpt.get();
                    if (existing.getFilePath() != null && !existing.getFilePath().isEmpty()) {
                        try { Files.deleteIfExists(Paths.get(existing.getFilePath()).toAbsolutePath().normalize()); }
                        catch (Exception ignored) {}
                    }
                    savedPath = saveFile(hwFile, "homework_uploads");
                }

                boolean ok = homeworkService.updateHomework(hwId, hwTitle.trim(),
                        hwDesc != null ? hwDesc.trim() : "", savedPath, origName);
                return redirectBase + (ok ? "&success=hwEdited" : "&err=hwEditFailed") + "&openCourse=" + courseId;

                // ── ลบการบ้าน ─────────────────────────────────────────────────
            } else if ("deleteHomework".equals(courseAction)) {
                if (hwId == null || hwId <= 0) return redirectBase + "&err=hwInvalidData";

                Optional<HomeworkDTO> existingOpt = homeworkService.getById(hwId);
                existingOpt.ifPresent(hw -> {
                    if (hw.getFilePath() != null && !hw.getFilePath().isEmpty()) {
                        try { Files.deleteIfExists(Paths.get(hw.getFilePath()).toAbsolutePath().normalize()); }
                        catch (Exception ignored) {}
                    }
                });
                boolean ok = homeworkService.deleteHomework(hwId);
                return redirectBase + (ok ? "&success=hwDeleted" : "&err=hwDeleteFailed") + "&openCourse=" + courseId;

                // ── คัดลอกคอร์ส ──────────────────────────────────────────────
            } else if ("copyCourse".equals(courseAction)) {
                if (courseId == null || courseId <= 0) return redirectBase + "&err=invalidId";
                Optional<CourseDTO> srcOpt = courseService.getCourseById(courseId);
                if (srcOpt.isEmpty()) return redirectBase + "&err=notFound";

                Integer copyUserId = user.getId();
                if (copyUserId == null) return redirectBase + "&err=invalidUser";
                User copyUser = userRepository.findById(copyUserId).orElse(null);
                if (copyUser == null) return redirectBase + "&err=invalidUser";

                CourseDTO src = srcOpt.get();
                int newId = courseService.addCourse("[Sao chép] " + src.getName(),
                        src.getDescription(),
                        src.getCategory(),
                        "INACTIVE",
                        copyUser.getId());

                return newId > 0
                        ? redirectBase + "&success=courseCopied&openCourse=" + newId
                        : redirectBase + "&err=copyFailed";
            }

        } catch (Exception ex) {
            ex.printStackTrace();
            return redirectBase + "&err=serverError";
        }

        return redirectBase;
    }

    // ── Helpers ────────────────────────────────────────────────────────────

    /**
     * Validates a file upload against a whitelist of allowed extensions and a
     * max-size guard.  Returns an error-code string on failure, or null on success.
     */
    private String validateFile(MultipartFile file, Set<String> allowedExts) {
        String original = file.getOriginalFilename() != null ? file.getOriginalFilename() : "";
        String ext = original.contains(".")
                ? original.substring(original.lastIndexOf('.')).toLowerCase()
                : "";
        if (!allowedExts.contains(ext)) {
            return "invalidFileType";   // caller appends this to redirect URL
        }
        if (file.getSize() > MAX_FILE_BYTES) {
            return "fileTooLarge";
        }
        return null; // OK
    }

    /**
     * Saves an uploaded file to {@code <uploadBaseDir>/<subDir>/} using a
     * UUID-generated filename so the original name never reaches the filesystem.
     * Returns the stored relative path for persisting in the database.
     */
    private String saveFile(MultipartFile file, String subDir) throws IOException {
        String original = file.getOriginalFilename() != null ? file.getOriginalFilename() : "file";
        String ext      = original.contains(".")
                ? original.substring(original.lastIndexOf('.')).toLowerCase()
                : "";
        String unique   = UUID.randomUUID().toString().replace("-", "") + ext;

        Path destDir = resolveAbsolutePath(subDir);
        if (!Files.exists(destDir)) {
            Files.createDirectories(destDir);
        }

        Path destFile = destDir.resolve(unique);
        file.transferTo(destFile);

        return subDir + "/" + unique;
    }

    /** Resolves a sub-directory name against the configured absolute base dir. */
    private Path resolveAbsolutePath(String subDir) {
        return Paths.get(uploadBaseDir).toAbsolutePath().normalize().resolve(subDir);
    }

    /** Returns the absolute Path of a sub-directory as String (for comparisons). */
    private String resolveDir(String subDir) {
        return resolveAbsolutePath(subDir).toString();
    }

    /** Deletes a file if its absolute path starts within the expected directory. */
    private void deleteFileIfLocal(String filePath, String expectedDirAbsolute) {
        if (filePath == null || filePath.isBlank()) return;
        try {
            Path target = Paths.get(filePath).toAbsolutePath().normalize();
            // Only delete files that actually live inside the expected directory
            if (target.startsWith(expectedDirAbsolute)) {
                Files.deleteIfExists(target);
            }
        } catch (Exception ignored) {}
    }

    private String notEmpty(String val, String defaultVal) {
        return (val != null && !val.trim().isEmpty()) ? val.trim() : defaultVal;
    }
}