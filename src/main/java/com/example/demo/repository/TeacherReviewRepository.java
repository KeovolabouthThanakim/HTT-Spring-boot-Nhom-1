package com.example.demo.repository;

import com.example.demo.entity.Course;
import com.example.demo.entity.TeacherReview;
import com.example.demo.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

import org.springframework.stereotype.Repository;

@Repository
public interface TeacherReviewRepository extends JpaRepository<TeacherReview, Integer> {

    /** Lấy tất cả đánh giá của giảng viên, sắp xếp mới nhất trước */
    List<TeacherReview> findByTeacherOrderByCreatedAtDesc(User teacher);

    /** Lấy tất cả đánh giá của khóa học, sắp xếp mới nhất trước */
    List<TeacherReview> findByCourseOrderByCreatedAtDesc(Course course);

    /** Kiểm tra học viên đã đánh giá giảng viên trong khóa học này chưa */
    Optional<TeacherReview> findByStudentAndTeacherAndCourse(User student, User teacher, Course course);

    /** Điểm đánh giá trung bình của giảng viên */
    @Query("SELECT AVG(r.rating) FROM TeacherReview r WHERE r.teacher = :teacher")
    Double findAverageRatingByTeacher(@Param("teacher") User teacher);

    /** Tổng số đánh giá của giảng viên */
    long countByTeacher(User teacher);

    /** ดึงรีวิวล่าสุดทั้งระบบ (สำหรับ admin/super_admin notification center) */
    @Query(value = "SELECT s.username AS student_name, t.username AS teacher_name, " +
                   "c.name AS course_name, r.rating, r.comment, r.created_at " +
                   "FROM teacher_reviews r " +
                   "JOIN users s ON r.student_id = s.id " +
                   "JOIN users t ON r.teacher_id = t.id " +
                   "JOIN courses c ON r.course_id = c.id " +
                   "ORDER BY r.created_at DESC LIMIT 10",
           nativeQuery = true)
    List<Object[]> findRecentReviews();
}
