package com.example.demo.service;

import com.example.demo.dto.DashboardDTO;
import com.example.demo.repository.CourseRepository;
import com.example.demo.repository.EnrollmentRepository;
import com.example.demo.repository.HomeworkRepository;
import com.example.demo.repository.TeacherReviewRepository;
import com.example.demo.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.*;

/**
 * Service แทนที่ DashboardDAO.java เดิม
 * Query ทุกตัวคัดลอกมาจาก DashboardDAO
 */
@Service
@RequiredArgsConstructor
public class DashboardService {

    private final UserRepository       userRepository;
    private final CourseRepository     courseRepository;
    private final EnrollmentRepository enrollmentRepository;
    private final HomeworkRepository   homeworkRepository;
    private final TeacherReviewRepository teacherReviewRepository;

    public DashboardDTO getDashboardData() {
        return DashboardDTO.builder()
                .totalStudents(userRepository.countStudents())
                .totalTeachers(userRepository.countTeachers())
                .totalCourses(courseRepository.count())
                .totalEnrollments(enrollmentRepository.count())
                .newStudentsToday(userRepository.countNewStudentsToday())
                .newCoursesThisMonth(courseRepository.countNewCoursesThisMonth())
                .pendingTeachers(userRepository.countPendingTeachers())
                .monthlyEnrollments(mapMonthlyEnrollments())
                .topCourses(mapTopCourses())
                .recentEnrollments(mapRecentEnrollments())
                .monthlyDetailedStats(mapMonthlyDetailedStats())
                .recentHomeworkSubmissions(mapRecentHomeworkSubmissions())
                .recentReviews(mapRecentReviews())
                .build();
    }

    /** getMonthlyEnrollments() เดิม */
    private List<Map<String, Object>> mapMonthlyEnrollments() {
        List<Map<String, Object>> result = new ArrayList<>();
        for (Object[] row : enrollmentRepository.findMonthlyEnrollments()) {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("month", row[0]);
            m.put("total", row[1]);
            result.add(m);
        }
        return result;
    }

    /** getTopCourses() เดิม */
    private List<Map<String, Object>> mapTopCourses() {
        List<Map<String, Object>> result = new ArrayList<>();
        for (Object[] row : courseRepository.findTopCourses()) {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("name",  row[0]);
            m.put("total", row[1]);
            result.add(m);
        }
        return result;
    }

    /** getRecentEnrollments() เดิม */
    private List<Map<String, Object>> mapRecentEnrollments() {
        List<Map<String, Object>> result = new ArrayList<>();
        for (Object[] row : enrollmentRepository.findRecentEnrollments()) {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("username",    row[0]);
            m.put("course",      row[1]);
            // BUG FIX: แปลง Timestamp → String ตรงนี้เลย ป้องกัน toString() ปีผิดใน JSP
            m.put("enrolled_at", formatDate(row[2]));
            result.add(m);
        }
        return result;
    }

    /** แปลง Object (java.sql.Timestamp / String / Date) เป็น yyyy-MM-dd อย่างปลอดภัย */
    private String formatDate(Object obj) {
        if (obj == null) return "";
        // Timestamp: แปลงผ่าน LocalDateTime เพื่อเก็บเวลาด้วย และหลีกเลี่ยง timezone bug
        if (obj instanceof java.sql.Timestamp) {
            return ((java.sql.Timestamp) obj).toLocalDateTime()
                    .format(java.time.format.DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
        }
        // java.sql.Date.toString() ใช้ Gregorian แต่บาง JDBC driver คืน Julian เมื่อปีน้อยกว่า 1582
        // → แปลงผ่าน toLocalDate() แทน toString() เสมอ
        if (obj instanceof java.sql.Date) {
            return ((java.sql.Date) obj).toLocalDate().toString();
        }
        // java.time.LocalDateTime หรือ String จาก ORM อื่น
        if (obj instanceof java.time.LocalDateTime) {
            return ((java.time.LocalDateTime) obj)
                    .format(java.time.format.DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
        }
        if (obj instanceof java.time.LocalDate) {
            return obj.toString();
        }
        // fallback: String raw — คืนทั้งหมด (JSP จะตัดเองถ้าจำเป็น)
        return obj.toString();
    }

    /** getMonthlyDetailedStats() — แปลง month_label จาก '2026-05-01' → 'May 2026' */
    private List<Map<String, Object>> mapMonthlyDetailedStats() {
        List<Map<String, Object>> result = new ArrayList<>();
        java.time.format.DateTimeFormatter inFmt  = java.time.format.DateTimeFormatter.ofPattern("yyyy-MM-dd");
        java.time.format.DateTimeFormatter outFmt = java.time.format.DateTimeFormatter.ofPattern("MMM yyyy",
                java.util.Locale.ENGLISH);
        for (Object[] row : enrollmentRepository.findMonthlyDetailedStats()) {
            Map<String, Object> m = new LinkedHashMap<>();
            // row[0] = '2026-05-01' string — แปลงเป็น 'May 2026'
            String rawLabel = row[0] != null ? row[0].toString() : "";
            String label = rawLabel;
            try {
                if (rawLabel.matches("\\d{4}-\\d{2}-\\d{2}")) {
                    label = java.time.LocalDate.parse(rawLabel, inFmt).format(outFmt);
                }
            } catch (Exception ignore) {}
            m.put("month_label",  label);
            m.put("month_key",    row[1]);
            m.put("enrollments",  row[2]);
            m.put("new_students", row[3]);
            m.put("new_teachers", row[4]);
            result.add(m);
        }
        return result;
    }

    /** การส่งการบ้านล่าสุด (10 รายการ) */
    private List<Map<String, Object>> mapRecentHomeworkSubmissions() {
        List<Map<String, Object>> result = new ArrayList<>();
        for (Object[] row : homeworkRepository.findRecentHomeworkSubmissions()) {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("username",     row[0]);
            m.put("course",       row[1]);
            m.put("title",        row[2]);
            m.put("status",       row[3]);
            // BUG FIX: แปลง Timestamp → String ป้องกันปีผิด
            m.put("submitted_at", formatDate(row[4]));
            // เพิ่ม file_path และ file_name สำหรับ admin ดาวน์โหลด
            m.put("file_path",    row.length > 5 ? row[5] : null);
            m.put("file_name",    row.length > 6 ? row[6] : null);
            result.add(m);
        }
        return result;
    }

    /** รีวิวครูล่าสุด (10 รายการ) */
    private List<Map<String, Object>> mapRecentReviews() {
        List<Map<String, Object>> result = new ArrayList<>();
        for (Object[] row : teacherReviewRepository.findRecentReviews()) {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("student_name", row[0]);
            m.put("teacher_name", row[1]);
            m.put("course_name",  row[2]);
            m.put("rating",       row[3]);
            m.put("comment",      row[4]);
            m.put("created_at",   row[5]);
            result.add(m);
        }
        return result;
    }
}