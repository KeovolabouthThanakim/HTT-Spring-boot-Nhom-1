package com.example.demo.repository;

import com.example.demo.entity.Course;
import com.example.demo.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.sql.Timestamp;
import java.util.List;

/**
 * แทนที่ CourseDAO.java เดิม
 */
@Repository
public interface CourseRepository extends JpaRepository<Course, Integer> {

    // getAllCourses() เดิม — เรียงตาม created_at DESC
    List<Course> findAllByOrderByCreatedAtDesc();

    // getCoursesByTeacher() เดิม
    List<Course> findByTeacherOrderByCreatedAtDesc(User teacher);

    // นับคอร์สใหม่เดือนนี้ — DashboardDAO.countNewCoursesThisMonth()
    // รองรับทั้งปี พ.ศ. (BE) และ ค.ศ. (AD) โดยเช็ค +- 543 ปี
    @Query(value = "SELECT COUNT(*) FROM courses " +
                   "WHERE MONTH(created_at) = MONTH(CURDATE()) " +
                   "AND (YEAR(created_at) = YEAR(CURDATE()) " +
                   "     OR YEAR(created_at) = YEAR(CURDATE()) + 543 " +
                   "     OR YEAR(created_at) = YEAR(CURDATE()) - 543)",
           nativeQuery = true)
    long countNewCoursesThisMonth();

    // top 5 คอร์สยอดนิยม — DashboardDAO.getTopCourses()
    @Query(value = "SELECT c.name, COUNT(e.id) AS total " +
                   "FROM courses c LEFT JOIN enrollments e ON c.id=e.course_id " +
                   "GROUP BY c.id, c.name ORDER BY total DESC LIMIT 5",
           nativeQuery = true)
    List<Object[]> findTopCourses();

    // ดึงคอร์สล่าสุดพร้อมชื่อครู สำหรับแสดงใน admin notifications
    @Query(value = "SELECT c.id, c.name, c.category, c.created_at, " +
                   "u.username AS teacher_username, " +
                   "CONCAT(COALESCE(u.first_name,''), ' ', COALESCE(u.last_name,'')) AS teacher_fullname " +
                   "FROM courses c JOIN users u ON c.teacher_id = u.id " +
                   "ORDER BY c.created_at DESC LIMIT :limit",
           nativeQuery = true)
    List<Object[]> findRecentCoursesWithTeacher(@org.springframework.data.repository.query.Param("limit") int limit);

    // นับคอร์สใหม่ใน N วันล่าสุด
    @Query(value = "SELECT COUNT(*) FROM courses WHERE created_at >= DATE_SUB(NOW(), INTERVAL :days DAY)",
           nativeQuery = true)
    long countNewCoursesInDays(@org.springframework.data.repository.query.Param("days") int days);

    // นับคอร์สใหม่ที่เพิ่งเปิด (N วัน) และ student คนนี้ยังไม่ได้ลงทะเบียน
    @Query(value = "SELECT COUNT(*) FROM courses c " +
                   "WHERE c.created_at >= DATE_SUB(NOW(), INTERVAL :days DAY) " +
                   "AND c.id NOT IN (SELECT e.course_id FROM enrollments e WHERE e.student_id = :studentId)",
           nativeQuery = true)
    long countNewCoursesNotEnrolledByStudent(
            @org.springframework.data.repository.query.Param("studentId") int studentId,
            @org.springframework.data.repository.query.Param("days") int days);

    // ดึง list คอร์สใหม่ที่ยังไม่ได้ลงทะเบียน: [name, category, createdAt]
    @Query(value = "SELECT c.name, c.category, c.created_at " +
                   "FROM courses c " +
                   "WHERE c.created_at >= DATE_SUB(NOW(), INTERVAL :days DAY) " +
                   "AND c.id NOT IN (SELECT e.course_id FROM enrollments e WHERE e.student_id = :studentId) " +
                   "ORDER BY c.created_at DESC LIMIT 5",
           nativeQuery = true)
    List<Object[]> findNewCoursesNotEnrolledByStudent(
            @org.springframework.data.repository.query.Param("studentId") int studentId,
            @org.springframework.data.repository.query.Param("days") int days);

    // นับคอร์สใหม่หลัง since ที่ student ยังไม่ลงทะเบียน
    @Query(value = "SELECT COUNT(*) FROM courses c " +
                   "WHERE c.created_at > :since " +
                   "AND c.id NOT IN (SELECT e.course_id FROM enrollments e WHERE e.student_id = :studentId)",
           nativeQuery = true)
    long countNewCoursesNotEnrolledByStudentSince(
            @org.springframework.data.repository.query.Param("studentId") int studentId,
            @org.springframework.data.repository.query.Param("since") Timestamp since);

    // ดึง list คอร์สใหม่หลัง since ที่ยังไม่ลงทะเบียน: [name, category, createdAt]
    @Query(value = "SELECT c.name, c.category, c.created_at " +
                   "FROM courses c " +
                   "WHERE c.created_at > :since " +
                   "AND c.id NOT IN (SELECT e.course_id FROM enrollments e WHERE e.student_id = :studentId) " +
                   "ORDER BY c.created_at DESC LIMIT 10",
           nativeQuery = true)
    List<Object[]> findNewCoursesNotEnrolledByStudentSince(
            @org.springframework.data.repository.query.Param("studentId") int studentId,
            @org.springframework.data.repository.query.Param("since") Timestamp since);
}
