package com.example.demo.repository;

import com.example.demo.entity.Course;
import com.example.demo.entity.Video;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.sql.Timestamp;
import java.util.List;

/**
 * แทนที่ VideoDAO.java เดิม
 */
@Repository
public interface VideoRepository extends JpaRepository<Video, Integer> {

    // getVideosByCourse() เดิม — ORDER BY order_no ASC
    List<Video> findByCourseOrderByOrderNoAsc(Course course);

    // countVideosByCourse() เดิม
    long countByCourse(Course course);

    // นับบทเรียนใหม่ใน 7 วันล่าสุด สำหรับคอร์สที่นักเรียนลงทะเบียน
    @Query(value = "SELECT COUNT(*) FROM videos v " +
                   "JOIN enrollments e ON e.course_id = v.course_id " +
                   "WHERE e.student_id = :studentId " +
                   "AND v.created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)",
           nativeQuery = true)
    long countNewVideosForStudent(@Param("studentId") int studentId);

    // ดึง list บทเรียนใหม่ใน 7 วัน: [title, courseName, createdAt]
    @Query(value = "SELECT v.title, c.name AS course_name, v.created_at " +
                   "FROM videos v " +
                   "JOIN courses c ON c.id = v.course_id " +
                   "JOIN enrollments e ON e.course_id = v.course_id " +
                   "WHERE e.student_id = :studentId " +
                   "AND v.created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY) " +
                   "ORDER BY v.created_at DESC LIMIT 5",
           nativeQuery = true)
    List<Object[]> findNewVideosForStudent(@Param("studentId") int studentId);

    // getNextOrderNo() เดิม
    @Query("SELECT COALESCE(MAX(v.orderNo), 0) + 1 FROM Video v WHERE v.course.id = :courseId")
    int findNextOrderNo(@Param("courseId") int courseId);

    // นับบทเรียนใหม่หลัง since สำหรับ student
    @Query(value = "SELECT COUNT(*) FROM videos v " +
                   "JOIN enrollments e ON e.course_id = v.course_id " +
                   "WHERE e.student_id = :studentId " +
                   "AND v.created_at > :since",
           nativeQuery = true)
    long countNewVideosForStudentSince(@Param("studentId") int studentId,
                                       @Param("since") Timestamp since);

    // ดึง list บทเรียนใหม่หลัง since: [title, courseName, createdAt]
    @Query(value = "SELECT v.title, c.name AS course_name, v.created_at " +
                   "FROM videos v " +
                   "JOIN courses c ON c.id = v.course_id " +
                   "JOIN enrollments e ON e.course_id = v.course_id " +
                   "WHERE e.student_id = :studentId " +
                   "AND v.created_at > :since " +
                   "ORDER BY v.created_at DESC LIMIT 10",
           nativeQuery = true)
    List<Object[]> findNewVideosForStudentSince(@Param("studentId") int studentId,
                                                @Param("since") Timestamp since);
}
