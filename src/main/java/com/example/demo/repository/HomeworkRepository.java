package com.example.demo.repository;

import com.example.demo.entity.Course;
import com.example.demo.entity.Homework;
import com.example.demo.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.sql.Timestamp;
import java.util.List;

/**
 * แทนที่ HomeworkDAO.java เดิม
 */
@Repository
public interface HomeworkRepository extends JpaRepository<Homework, Integer> {

    // getByStudentAndCourse() เดิม
    List<Homework> findByStudentAndCourseOrderBySubmittedAtDesc(User student, Course course);

    // getStudentsByCourse() — นักเรียนทั้งหมดในคอร์ส (กรองเฉพาะ role=STUDENT เท่านั้น)
    @Query("SELECT h FROM Homework h " +
            "WHERE h.course.id = :courseId " +
            "AND UPPER(h.student.role) = 'STUDENT' " +
            "ORDER BY h.submittedAt DESC")
    List<Homework> findStudentsByCourseId(@Param("courseId") int courseId);

    // getAllTeacherFiles() เดิม — ไฟล์ที่ staff อัปโหลด
    @Query("SELECT h FROM Homework h " +
            "WHERE h.course.id = :courseId " +
            "AND UPPER(h.student.role) IN ('TEACHER','ADMIN','SUPER_ADMIN') " +
            "ORDER BY h.submittedAt DESC")
    List<Homework> findTeacherFilesByCourseId(@Param("courseId") int courseId);

    // getTeacherFiles() เดิม — ไฟล์ที่ teacher คนนั้นอัปโหลด
    List<Homework> findByCourseAndStudentOrderBySubmittedAtDesc(Course course, User teacher);

    // countByStudentAndCourse() เดิม
    long countByStudentAndCourse(User student, Course course);

    // นับบài PENDING ของนักเรียน (ไม่รวม staff) ในคอร์สหนึ่ง
    @Query("SELECT COUNT(h) FROM Homework h " +
            "WHERE h.course.id = :courseId " +
            "AND UPPER(h.student.role) = 'STUDENT' " +
            "AND UPPER(h.status) = 'PENDING'")
    long countPendingStudentsByCourseId(@Param("courseId") int courseId);

    // นับการบ้าน (teacher files) ใหม่ใน 7 วันล่าสุด สำหรับคอร์สที่นักเรียนลงทะเบียน
    @Query(value = "SELECT COUNT(*) FROM homework_submissions h " +
            "JOIN enrollments e ON e.course_id = h.course_id " +
            "JOIN users u ON h.student_id = u.id " +
            "WHERE e.student_id = :studentId " +
            "AND UPPER(u.role) IN ('TEACHER','ADMIN','SUPER_ADMIN') " +
            "AND h.submitted_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)",
            nativeQuery = true)
    long countNewHomeworkFilesForStudent(@Param("studentId") int studentId);

    // ดึง list การบ้าน/เอกสาร ใหม่จากครูใน 7 วัน: [title, courseName, submittedAt]
    @Query(value = "SELECT h.title, c.name AS course_name, h.submitted_at " +
            "FROM homework_submissions h " +
            "JOIN enrollments e ON e.course_id = h.course_id " +
            "JOIN courses c ON c.id = h.course_id " +
            "JOIN users u ON h.student_id = u.id " +
            "WHERE e.student_id = :studentId " +
            "AND UPPER(u.role) IN ('TEACHER','ADMIN','SUPER_ADMIN') " +
            "AND h.submitted_at >= DATE_SUB(NOW(), INTERVAL 7 DAY) " +
            "ORDER BY h.submitted_at DESC LIMIT 5",
            nativeQuery = true)
    List<Object[]> findNewHomeworkFilesForStudent(@Param("studentId") int studentId);

    // นับการลงทะเบียนใหม่ (ใน 7 วันล่าสุด) สำหรับคอร์สของครู
    @Query(value = "SELECT COUNT(*) FROM enrollments e " +
            "JOIN courses c ON e.course_id = c.id " +
            "WHERE c.teacher_id = :teacherId " +
            "AND e.enrolled_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)",
            nativeQuery = true)
    long countRecentEnrollmentsByTeacher(@Param("teacherId") int teacherId);

    // BUG FIX (admin): นับ homework PENDING ทั้งระบบ (ทุกครู ทุกคอร์ส)
    @Query(value = "SELECT COUNT(*) FROM homework_submissions h " +
            "JOIN users u ON h.student_id = u.id " +
            "WHERE UPPER(u.role) = 'STUDENT' " +
            "AND UPPER(h.status) = 'PENDING'",
            nativeQuery = true)
    long countAllPendingHomeworkSystem();

    // BUG FIX (admin): นับ PENDING ใหม่ทั้งระบบใน N ชั่วโมงล่าสุด
    @Query(value = "SELECT COUNT(*) FROM homework_submissions h " +
            "JOIN users u ON h.student_id = u.id " +
            "WHERE UPPER(u.role) = 'STUDENT' " +
            "AND UPPER(h.status) = 'PENDING' " +
            "AND h.submitted_at >= DATE_SUB(NOW(), INTERVAL :hours HOUR)",
            nativeQuery = true)
    long countNewPendingHomeworkSystem(@Param("hours") int hours);

    // BUG FIX: นับ homework PENDING ใหม่ของนักเรียนสำหรับคอร์สของครู ใน N ชั่วโมงที่ผ่านมา
    @Query(value = "SELECT COUNT(*) FROM homework_submissions h " +
            "JOIN courses c ON h.course_id = c.id " +
            "JOIN users u ON h.student_id = u.id " +
            "WHERE c.teacher_id = :teacherId " +
            "AND UPPER(u.role) = 'STUDENT' " +
            "AND UPPER(h.status) = 'PENDING' " +
            "AND h.submitted_at >= DATE_SUB(NOW(), INTERVAL :hours HOUR)",
            nativeQuery = true)
    long countNewPendingHomeworkForTeacher(@Param("teacherId") int teacherId,
                                           @Param("hours") int hours);

    // นับ homework PENDING ทั้งหมดของครู (ทุก course ที่ตัวเองสอน)
    @Query(value = "SELECT COUNT(*) FROM homework_submissions h " +
            "JOIN courses c ON h.course_id = c.id " +
            "JOIN users u ON h.student_id = u.id " +
            "WHERE c.teacher_id = :teacherId " +
            "AND UPPER(u.role) = 'STUDENT' " +
            "AND UPPER(h.status) = 'PENDING'",
            nativeQuery = true)
    long countAllPendingHomeworkForTeacher(@Param("teacherId") int teacherId);

    /** ดึงรายการส่งการบ้านล่าสุด 20 รายการ พร้อม file_path สำหรับดาวน์โหลด */
    @Query(value = "SELECT u.username, c.name AS course, h.title, h.status, h.submitted_at, h.file_path, h.file_name " +
            "FROM homework_submissions h " +
            "JOIN users u ON h.student_id = u.id " +
            "JOIN courses c ON h.course_id = c.id " +
            "WHERE UPPER(u.role) = 'STUDENT' " +
            "ORDER BY h.submitted_at DESC LIMIT 20",
            nativeQuery = true)
    List<Object[]> findRecentHomeworkSubmissions();

    // นับ teacher files ใหม่หลัง since สำหรับ student
    @Query(value = "SELECT COUNT(*) FROM homework_submissions h " +
            "JOIN enrollments e ON e.course_id = h.course_id " +
            "JOIN users u ON h.student_id = u.id " +
            "WHERE e.student_id = :studentId " +
            "AND UPPER(u.role) IN ('TEACHER','ADMIN','SUPER_ADMIN') " +
            "AND h.submitted_at > :since",
            nativeQuery = true)
    long countNewHomeworkFilesForStudentSince(@Param("studentId") int studentId,
                                              @Param("since") Timestamp since);

    // ดึง list teacher files ใหม่หลัง since
    @Query(value = "SELECT h.title, c.name AS course_name, h.submitted_at " +
            "FROM homework_submissions h " +
            "JOIN enrollments e ON e.course_id = h.course_id " +
            "JOIN courses c ON c.id = h.course_id " +
            "JOIN users u ON h.student_id = u.id " +
            "WHERE e.student_id = :studentId " +
            "AND UPPER(u.role) IN ('TEACHER','ADMIN','SUPER_ADMIN') " +
            "AND h.submitted_at > :since " +
            "ORDER BY h.submitted_at DESC LIMIT 10",
            nativeQuery = true)
    List<Object[]> findNewHomeworkFilesForStudentSince(@Param("studentId") int studentId,
                                                       @Param("since") Timestamp since);

    // นับ enrollment ใหม่หลัง since สำหรับครู
    @Query(value = "SELECT COUNT(*) FROM enrollments e " +
            "JOIN courses c ON e.course_id = c.id " +
            "WHERE c.teacher_id = :teacherId " +
            "AND e.enrolled_at > :since",
            nativeQuery = true)
    long countRecentEnrollmentsByTeacherSince(@Param("teacherId") int teacherId,
                                              @Param("since") Timestamp since);

    // นับ homework pending ใหม่หลัง since สำหรับครู
    @Query(value = "SELECT COUNT(*) FROM homework_submissions h " +
            "JOIN courses c ON h.course_id = c.id " +
            "JOIN users u ON h.student_id = u.id " +
            "WHERE c.teacher_id = :teacherId " +
            "AND UPPER(u.role) = 'STUDENT' " +
            "AND UPPER(h.status) = 'PENDING' " +
            "AND h.submitted_at > :since",
            nativeQuery = true)
    long countNewPendingHomeworkForTeacherSince(@Param("teacherId") int teacherId,
                                                @Param("since") Timestamp since);

    // นับ homework pending ใหม่ทั้งระบบหลัง since (admin)
    @Query(value = "SELECT COUNT(*) FROM homework_submissions h " +
            "JOIN users u ON h.student_id = u.id " +
            "WHERE UPPER(u.role) = 'STUDENT' " +
            "AND UPPER(h.status) = 'PENDING' " +
            "AND h.submitted_at > :since",
            nativeQuery = true)
    long countNewPendingHomeworkSystemSince(@Param("since") Timestamp since);
}