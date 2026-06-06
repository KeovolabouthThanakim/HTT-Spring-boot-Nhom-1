package com.example.demo.repository;

import com.example.demo.entity.Course;
import com.example.demo.entity.Enrollment;
import com.example.demo.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface EnrollmentRepository extends JpaRepository<Enrollment, Integer> {

    boolean existsByStudentAndCourse(User student, Course course);
    Optional<Enrollment> findByStudentAndCourse(User student, Course course);
    List<Enrollment> findByStudent(User student);
    long countByCourse(Course course);

    @Query(value = "SELECT u.username, c.name AS course, e.enrolled_at " +
            "FROM enrollments e " +
            "JOIN users u ON e.student_id=u.id " +
            "JOIN courses c ON e.course_id=c.id " +
            "ORDER BY e.enrolled_at DESC LIMIT 10",
            nativeQuery = true)
    List<Object[]> findRecentEnrollments();

    @Query(value = "SELECT u.username, c.name AS course, e.enrolled_at " +
            "FROM enrollments e " +
            "JOIN users u ON e.student_id = u.id " +
            "JOIN courses c ON e.course_id = c.id " +
            "WHERE c.teacher_id = :teacherId " +
            "AND e.enrolled_at >= DATE_SUB(NOW(), INTERVAL :days DAY) " +
            "ORDER BY e.enrolled_at DESC",
            nativeQuery = true)
    List<Object[]> findRecentEnrollmentsForTeacher(@Param("teacherId") int teacherId,
                                                   @Param("days") int days);

    @Query(value =
            "SELECT DATE_FORMAT(months_seq.mdate, '%b %y') AS month, " +
            "       COALESCE(enroll_sub.cnt, 0) AS total " +
            "FROM (" +
            "  SELECT DATE_FORMAT(DATE_SUB(DATE_FORMAT(CURDATE(),'%Y-%m-01'), INTERVAL n MONTH), '%Y-%m-01') AS mdate" +
            "  FROM (SELECT 0 AS n UNION ALL SELECT 1 UNION ALL SELECT 2 " +
            "    UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) seq_n" +
            ") months_seq " +
            "LEFT JOIN (" +
            "  SELECT DATE_FORMAT(enrolled_at, '%Y-%m-01') AS mdate, COUNT(*) AS cnt " +
            "  FROM enrollments " +
            "  WHERE enrolled_at IS NOT NULL AND YEAR(enrolled_at) BETWEEN 2000 AND 3000 " +
            "  GROUP BY DATE_FORMAT(enrolled_at, '%Y-%m-01')" +
            ") enroll_sub ON enroll_sub.mdate = months_seq.mdate " +
            "ORDER BY months_seq.mdate ASC",
            nativeQuery = true)
    List<Object[]> findMonthlyEnrollments();

    // ใช้ชื่อ alias ไม่ซ้ำกัน: subquery ชื่อ months_seq, enroll_sub, student_sub, teacher_sub
    @Query(value =
            "SELECT months_seq.mdate AS month_label," +
                    "  months_seq.mdate AS month_key," +
                    "  COALESCE(enroll_sub.cnt, 0) AS enrollments," +
                    "  COALESCE(student_sub.cnt, 0) AS new_students," +
                    "  COALESCE(teacher_sub.cnt, 0) AS new_teachers " +
                    "FROM (" +
                    "  SELECT DATE_FORMAT(DATE_SUB(DATE_FORMAT(CURDATE(),'%Y-%m-01'), INTERVAL n MONTH), '%Y-%m-01') AS mdate" +
                    "  FROM (SELECT 0 AS n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3" +
                    "    UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7" +
                    "    UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11) seq_n" +
                    ") months_seq " +
                    "LEFT JOIN (" +
                    "  SELECT DATE_FORMAT(enrolled_at, '%Y-%m-01') AS mdate, COUNT(*) AS cnt" +
                    "  FROM enrollments" +
                    "  WHERE enrolled_at IS NOT NULL AND YEAR(enrolled_at) BETWEEN 2000 AND 3000" +
                    "  GROUP BY DATE_FORMAT(enrolled_at, '%Y-%m-01')" +
                    ") enroll_sub ON enroll_sub.mdate = months_seq.mdate " +
                    "LEFT JOIN (" +
                    "  SELECT DATE_FORMAT(created_at, '%Y-%m-01') AS mdate, COUNT(*) AS cnt" +
                    "  FROM users" +
                    "  WHERE LOWER(role) = 'student' AND created_at IS NOT NULL AND YEAR(created_at) BETWEEN 2000 AND 3000" +
                    "  GROUP BY DATE_FORMAT(created_at, '%Y-%m-01')" +
                    ") student_sub ON student_sub.mdate = months_seq.mdate " +
                    "LEFT JOIN (" +
                    "  SELECT DATE_FORMAT(created_at, '%Y-%m-01') AS mdate, COUNT(*) AS cnt" +
                    "  FROM users" +
                    "  WHERE LOWER(role) = 'teacher' AND created_at IS NOT NULL AND YEAR(created_at) BETWEEN 2000 AND 3000" +
                    "  GROUP BY DATE_FORMAT(created_at, '%Y-%m-01')" +
                    ") teacher_sub ON teacher_sub.mdate = months_seq.mdate " +
                    "ORDER BY months_seq.mdate ASC",
            nativeQuery = true)
    List<Object[]> findMonthlyDetailedStats();

    @Query(value = "SELECT COUNT(*) FROM homework_submissions hs " +
            "JOIN courses c ON hs.course_id = c.id " +
            "WHERE c.teacher_id = :teacherId AND hs.status = 'PENDING'",
            nativeQuery = true)
    long countAllPendingHomeworkForTeacher(@Param("teacherId") int teacherId);
}