package com.example.demo.service;

import com.example.demo.dto.TeacherReviewDTO;
import com.example.demo.entity.Course;
import com.example.demo.entity.TeacherReview;
import com.example.demo.entity.User;
import com.example.demo.repository.CourseRepository;
import com.example.demo.repository.TeacherReviewRepository;
import com.example.demo.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class TeacherReviewService {

    private final TeacherReviewRepository reviewRepository;
    private final UserRepository          userRepository;
    private final CourseRepository        courseRepository;

    // ─── GHI ─────────────────────────────────────────────────────────────

    /**
     * Gửi đánh giá — nếu đã đánh giá trước đó thì cập nhật thay vì tạo mới.
     */
    @Transactional
    public boolean submitReview(int studentId, int teacherId, int courseId, int rating, String comment) {
        if (rating < 1 || rating > 5) return false;

        User   student = userRepository.findById(studentId).orElse(null);
        User   teacher = userRepository.findById(teacherId).orElse(null);
        Course course  = courseRepository.findById(courseId).orElse(null);
        if (student == null || teacher == null || course == null) return false;

        Optional<TeacherReview> existing =
                reviewRepository.findByStudentAndTeacherAndCourse(student, teacher, course);
        if (existing.isPresent()) {
            // Cập nhật đánh giá cũ
            TeacherReview r = existing.get();
            r.setRating(rating);
            r.setComment(comment != null ? comment.trim() : "");
            reviewRepository.save(r);
        } else {
            reviewRepository.save(TeacherReview.builder()
                    .student(student).teacher(teacher).course(course)
                    .rating(rating)
                    .comment(comment != null ? comment.trim() : "")
                    .build());
        }
        return true;
    }

    /**
     * Xóa đánh giá — chỉ chủ sở hữu mới được xóa.
     */
    @Transactional
    public boolean deleteReview(int reviewId, int requesterId) {
        return reviewRepository.findById(reviewId).map(r -> {
            if (r.getStudent().getId().equals(requesterId)) {
                reviewRepository.delete(r);
                return true;
            }
            return false;
        }).orElse(false);
    }

    // ─── ĐỌC ─────────────────────────────────────────────────────────────

    /** Lấy tất cả đánh giá của giảng viên */
    @Transactional(readOnly = true)
    public List<TeacherReviewDTO> getReviewsByTeacher(int teacherId) {
        User teacher = userRepository.findById(teacherId).orElse(null);
        if (teacher == null) return List.of();
        return reviewRepository.findByTeacherOrderByCreatedAtDesc(teacher)
                .stream().map(this::toDTO).collect(Collectors.toList());
    }

    /** Lấy tất cả đánh giá của khóa học */
    @Transactional(readOnly = true)
    public List<TeacherReviewDTO> getReviewsByCourse(int courseId) {
        Course course = courseRepository.findById(courseId).orElse(null);
        if (course == null) return List.of();
        return reviewRepository.findByCourseOrderByCreatedAtDesc(course)
                .stream().map(this::toDTO).collect(Collectors.toList());
    }

    /** Điểm trung bình của giảng viên (làm tròn 1 chữ số thập phân) */
    public double getAverageRating(int teacherId) {
        User teacher = userRepository.findById(teacherId).orElse(null);
        if (teacher == null) return 0.0;
        Double avg = reviewRepository.findAverageRatingByTeacher(teacher);
        return avg != null ? Math.round(avg * 10.0) / 10.0 : 0.0;
    }

    /** Tổng số đánh giá của giảng viên */
    public long getReviewCount(int teacherId) {
        User teacher = userRepository.findById(teacherId).orElse(null);
        if (teacher == null) return 0;
        return reviewRepository.countByTeacher(teacher);
    }

    /** Kiểm tra học viên đã đánh giá trong khóa học này chưa */
    @Transactional(readOnly = true)
    public boolean hasReviewed(int studentId, int teacherId, int courseId) {
        User   student = userRepository.findById(studentId).orElse(null);
        User   teacher = userRepository.findById(teacherId).orElse(null);
        Course course  = courseRepository.findById(courseId).orElse(null);
        if (student == null || teacher == null || course == null) return false;
        return reviewRepository.findByStudentAndTeacherAndCourse(student, teacher, course).isPresent();
    }

    // ─── MAPPER ───────────────────────────────────────────────────────────

    private TeacherReviewDTO toDTO(TeacherReview r) {
        return TeacherReviewDTO.builder()
                .id(r.getId())
                .studentId(r.getStudent()  != null ? r.getStudent().getId()    : null)
                .studentName(r.getStudent() != null ? r.getStudent().getFullName() : "")
                .teacherId(r.getTeacher()  != null ? r.getTeacher().getId()    : null)
                .teacherName(r.getTeacher() != null ? r.getTeacher().getFullName() : "")
                .courseId(r.getCourse()    != null ? r.getCourse().getId()     : null)
                .courseName(r.getCourse()   != null ? r.getCourse().getName()   : "")
                .rating(r.getRating())
                .comment(r.getComment())
                .createdAt(r.getCreatedAt() != null ? r.getCreatedAt().toString() : "")
                .build();
    }
}
