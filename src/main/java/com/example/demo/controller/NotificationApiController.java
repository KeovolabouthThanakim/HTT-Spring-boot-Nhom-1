package com.example.demo.controller;

import com.example.demo.entity.User;
import com.example.demo.repository.CourseRepository;
import com.example.demo.repository.HomeworkRepository;
import com.example.demo.repository.UserRepository;
import com.example.demo.repository.VideoRepository;
import com.example.demo.service.CourseService;
import com.example.demo.service.HomeworkService;
import jakarta.servlet.http.HttpSession;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.function.Function;

/**
 * REST API สำหรับ notification badge + dropdown
 *
 * GET  /api/notifications/count   → ดึงจำนวน/items หลัง lastSeen
 * POST /api/notifications/markSeen → อัพเดต lastSeen = ตอนนี้ → badge = 0
 */
@RestController
@RequestMapping("/api/notifications")
@RequiredArgsConstructor
public class NotificationApiController {

    private final HomeworkService    homeworkService;
    private final CourseService      courseService;
    private final HomeworkRepository homeworkRepository;
    private final VideoRepository    videoRepository;
    private final UserRepository     userRepository;
    private final CourseRepository   courseRepository;

    // session key สำหรับเก็บ lastSeen แยกตาม role
    private static final String SESSION_KEY = "_notifLastSeen";

    // ── MARK SEEN ─────────────────────────────────────────────────────────
    // เรียกเมื่อผู้ใช้เปิด dropdown → บันทึกเวลาปัจจุบัน → badge = 0
    @PostMapping("/markSeen")
    public ResponseEntity<?> markSeen(HttpSession session) {
        User user = (User) session.getAttribute("user");
        if (user == null) return ResponseEntity.status(401).body(Map.of("error","unauthorized"));
        session.setAttribute(SESSION_KEY, Timestamp.valueOf(LocalDateTime.now()));
        return ResponseEntity.ok(Map.of("ok", true));
    }

    // ── COUNT ──────────────────────────────────────────────────────────────
    @GetMapping("/count")
    public ResponseEntity<?> getNotificationCount(HttpSession session) {
        User user = (User) session.getAttribute("user");
        if (user == null) return ResponseEntity.status(401).body(Map.of("error","unauthorized"));

        // lastSeen logic:
        // - ยังไม่มี (login ครั้งแรก) → init = 7 วันที่แล้ว เพื่อให้เห็นข้อมูลที่มีอยู่
        // - มีแล้ว + เป็นวันก่อนหน้า (daily reset) → reset = 00:00 วันนี้ → badge นับใหม่ทั้งวัน
        // - มีแล้ว + วันนี้ → ใช้ค่าเดิม (นับหลังที่ดูล่าสุด)
        Timestamp lastSeen = (Timestamp) session.getAttribute(SESSION_KEY);
        if (lastSeen == null) {
            // ครั้งแรก: ย้อนหลัง 7 วัน ให้เห็นข้อมูลที่มีอยู่
            lastSeen = Timestamp.valueOf(LocalDateTime.now().minusDays(7));
            session.setAttribute(SESSION_KEY, lastSeen);
        } else {
            // daily reset: ถ้า lastSeen เป็นวันก่อนหน้า → reset = 00:00 วันนี้
            java.time.LocalDate lastSeenDate = lastSeen.toLocalDateTime().toLocalDate();
            java.time.LocalDate today        = java.time.LocalDate.now();
            if (lastSeenDate.isBefore(today)) {
                lastSeen = Timestamp.valueOf(today.atStartOfDay());
                session.setAttribute(SESSION_KEY, lastSeen);
            }
        }

        String role = user.getRole() != null ? user.getRole().toLowerCase() : "";

        // formatter สำหรับแสดง timestamp ใน items
        DateTimeFormatter fmt = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm");
        Function<Object, String> fmtDate = (obj) -> {
            if (obj == null) return "";
            if (obj instanceof Timestamp)
                return ((Timestamp) obj).toLocalDateTime().format(fmt);
            if (obj instanceof LocalDateTime)
                return ((LocalDateTime) obj).format(fmt);
            String s = obj.toString().replace("T", " ");
            try {
                if (s.length() >= 16)
                    return LocalDateTime.parse(
                        s.length() >= 19 ? s.substring(0,19) : s,
                        DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")).format(fmt);
            } catch (Exception ignore) {}
            return s.length() > 16 ? s.substring(0,16) : s;
        };

        // ── TEACHER ───────────────────────────────────────────────────────
        if ("teacher".equals(role)) {
            long newHw      = homeworkRepository.countNewPendingHomeworkForTeacherSince(user.getId(), lastSeen);
            long newEnrolls = homeworkRepository.countRecentEnrollmentsByTeacherSince(user.getId(), lastSeen);
            long total      = newHw + newEnrolls;

            Map<String, Object> result = new HashMap<>();
            result.put("pendingHw",  newHw);
            result.put("newEnrolls", newEnrolls);
            result.put("total",      total);

            List<Map<String,String>> items = new ArrayList<>();
            if (newHw > 0) {
                Map<String,String> m = new HashMap<>();
                m.put("text", "📝 Có " + newHw + " bài tập mới nộp chờ chấm điểm");
                m.put("href", "/dashboard?tab=notifications");
                items.add(m);
            }
            if (newEnrolls > 0) {
                Map<String,String> m = new HashMap<>();
                m.put("text", "🎓 Có " + newEnrolls + " học sinh đăng ký mới");
                m.put("href", "/dashboard?tab=courses");
                items.add(m);
            }
            result.put("items", items);
            return ResponseEntity.ok(result);
        }

        // ── STUDENT ───────────────────────────────────────────────────────
        if ("student".equals(role)) {
            long newCourses  = courseRepository.countNewCoursesNotEnrolledByStudentSince(user.getId(), lastSeen);
            long newVideos   = videoRepository.countNewVideosForStudentSince(user.getId(), lastSeen);
            long newHomework = homeworkRepository.countNewHomeworkFilesForStudentSince(user.getId(), lastSeen);
            long total       = newCourses + newVideos + newHomework;

            Map<String, Object> result = new HashMap<>();
            result.put("newCourses",  newCourses);
            result.put("newVideos",   newVideos);
            result.put("newHomework", newHomework);
            result.put("total",       total);

            List<Map<String,String>> items = new ArrayList<>();

            // 🏫 คอร์สใหม่ที่ยังไม่ได้ลงทะเบียน
            if (newCourses > 0) {
                Map<String,String> header = new HashMap<>();
                header.put("type",  "header");
                header.put("text",  "🏫 Khóa học mới");
                header.put("badge", String.valueOf(newCourses));
                items.add(header);
                for (Object[] row : courseRepository.findNewCoursesNotEnrolledByStudentSince(user.getId(), lastSeen)) {
                    Map<String,String> m = new HashMap<>();
                    String cname = row[0] != null ? row[0].toString() : "—";
                    String cat   = row[1] != null ? row[1].toString() : "";
                    String dt    = fmtDate.apply(row[2]);
                    m.put("type", "item");
                    m.put("icon", "🏫");
                    m.put("text", cname + (cat.isEmpty() ? "" : " · " + cat));
                    m.put("time", dt);
                    m.put("href", "/home?tab=khoa-hoc");
                    items.add(m);
                }
            }

            // 🎬 บทเรียนใหม่ในคอร์สที่ลงทะเบียน
            if (newVideos > 0) {
                Map<String,String> header = new HashMap<>();
                header.put("type",  "header");
                header.put("text",  "🎬 Bài học mới");
                header.put("badge", String.valueOf(newVideos));
                items.add(header);
                for (Object[] row : videoRepository.findNewVideosForStudentSince(user.getId(), lastSeen)) {
                    Map<String,String> m = new HashMap<>();
                    String vTitle = row[0] != null ? row[0].toString() : "—";
                    String cname  = row[1] != null ? row[1].toString() : "";
                    String dt     = fmtDate.apply(row[2]);
                    m.put("type", "item");
                    m.put("icon", "🎬");
                    m.put("text", vTitle + (cname.isEmpty() ? "" : " · " + cname));
                    m.put("time", dt);
                    m.put("href", "/home?tab=khoa-hoc-cua-toi");
                    items.add(m);
                }
            }

            // 📋 การบ้าน/เอกสารใหม่จากครู
            if (newHomework > 0) {
                Map<String,String> header = new HashMap<>();
                header.put("type",  "header");
                header.put("text",  "📋 Bài tập / Tài liệu mới");
                header.put("badge", String.valueOf(newHomework));
                items.add(header);
                for (Object[] row : homeworkRepository.findNewHomeworkFilesForStudentSince(user.getId(), lastSeen)) {
                    Map<String,String> m = new HashMap<>();
                    String hwTitle = row[0] != null ? row[0].toString() : "—";
                    String cname   = row[1] != null ? row[1].toString() : "";
                    String dt      = fmtDate.apply(row[2]);
                    m.put("type", "item");
                    m.put("icon", "📋");
                    m.put("text", hwTitle + (cname.isEmpty() ? "" : " · " + cname));
                    m.put("time", dt);
                    m.put("href", "/home?tab=khoa-hoc-cua-toi");
                    items.add(m);
                }
            }

            result.put("items", items);
            return ResponseEntity.ok(result);
        }

        // ── ADMIN / SUPER_ADMIN ───────────────────────────────────────────
        if ("admin".equals(role) || "super_admin".equals(role)) {
            long newTeachers = userRepository.countPendingTeachersSince(lastSeen);
            long newHw       = homeworkRepository.countNewPendingHomeworkSystemSince(lastSeen);
            long total       = newTeachers + newHw;

            Map<String, Object> result = new HashMap<>();
            result.put("pendingTeachers", newTeachers);
            result.put("pendingHwAll",    newHw);
            result.put("total",           total);

            List<Map<String,String>> items = new ArrayList<>();
            if (newTeachers > 0) {
                Map<String,String> m = new HashMap<>();
                m.put("text", "⏳ Có " + newTeachers + " giáo viên mới chờ phê duyệt");
                m.put("href", "/dashboard?tab=approval");
                items.add(m);
            }
            if (newHw > 0) {
                Map<String,String> m = new HashMap<>();
                m.put("text", "📝 Có " + newHw + " bài tập mới nộp chờ chấm điểm");
                m.put("href", "/dashboard?tab=approval");
                items.add(m);
            }
            result.put("items", items);
            return ResponseEntity.ok(result);
        }

        return ResponseEntity.ok(Map.of("total", 0, "items", List.of()));
    }
}
