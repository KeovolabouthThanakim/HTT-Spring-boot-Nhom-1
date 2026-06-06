package com.example.demo.service;

import com.example.demo.dto.CourseDTO;
import com.example.demo.entity.Course;
import com.example.demo.entity.User;
import com.example.demo.repository.CourseRepository;
import com.example.demo.repository.EnrollmentRepository;
import com.example.demo.repository.UserRepository;
import com.example.demo.repository.VideoRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

/**
 * Service layer for Course operations.
 *
 * Transactional strategy:
 *  - Write methods (@Transactional): rolled back atomically on failure.
 *  - Multi-step read methods (@Transactional(readOnly=true)):
 *      toDTO() calls videoRepository.countByCourse() and
 *      enrollmentRepository.countByCourse() — without a shared session these
 *      fire as separate transactions, which (a) increases connection churn and
 *      (b) risks LazyInitializationException if associations are ever added.
 *      readOnly=true keeps all counts within one session while telling the DB
 *      driver to skip write locks for better concurrency.
 */
@Service
@RequiredArgsConstructor
public class CourseService {

    private final CourseRepository     courseRepository;
    private final UserRepository       userRepository;
    private final VideoRepository      videoRepository;
    private final EnrollmentRepository enrollmentRepository;

    // ─── READ ──────────────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public List<CourseDTO> getAllCourses() {
        return courseRepository.findAllByOrderByCreatedAtDesc()
                .stream().map(this::toDTO).collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<CourseDTO> getCoursesByTeacher(int teacherId) {
        return userRepository.findById(teacherId)
                .map(t -> courseRepository.findByTeacherOrderByCreatedAtDesc(t)
                        .stream().map(this::toDTO).collect(Collectors.toList()))
                .orElse(List.of());
    }

    @Transactional(readOnly = true)
    public Optional<CourseDTO> getCourseById(int id) {
        return courseRepository.findById(id).map(this::toDTO);
    }

    @Transactional(readOnly = true)
    public Optional<Course> getCourseEntityById(int id) {
        return courseRepository.findById(id);
    }

    // ─── WRITE ─────────────────────────────────────────────────────────────

    /** Creates a new course and returns its generated ID, or 0 on failure. */
    @Transactional
    public int addCourse(String name, String description, String category,
                         String status, int teacherId) {
        User teacher = userRepository.findById(teacherId).orElse(null);
        if (teacher == null) {
            System.err.println("[CourseService] addCourse failed: teacher not found, teacherId=" + teacherId);
            return 0;
        }

        // ใช้ Builder เพื่อให้ @Builder.Default ทำงานถูกต้อง
        // new Course() + setter จะทำให้ videos/enrollments list เป็น null
        // ซึ่ง cascade/orphanRemoval อาจพัง และ category/status default ไม่ถูก apply
        Course c = Course.builder()
                .name(name)
                .description(description != null ? description : "")
                .category(category != null && !category.trim().isEmpty() ? category.trim() : "General")
                .status(status != null && !status.trim().isEmpty() ? status.trim() : "ACTIVE")
                .teacher(teacher)
                .createdAt(java.time.LocalDateTime.now())
                .build();

        Course saved = courseRepository.save(c);
        courseRepository.flush();
        if (saved == null || saved.getId() == null) return 0;
        return saved.getId();
    }

    /** Updates all five editable fields; returns false if course not found. */
    @Transactional
    public boolean updateCourse(int courseId, String name, String description,
                                String category, String status) {
        return courseRepository.findById(courseId).map(c -> {
            c.setName(name);
            c.setDescription(description != null ? description : "");
            c.setCategory(category != null && !category.trim().isEmpty() ? category.trim() : "General");
            c.setStatus(status   != null && !status.trim().isEmpty()   ? status.trim()   : "ACTIVE");
            courseRepository.save(c);
            return true;
        }).orElse(false);
    }

    /** Backward-compatible 3-parameter overload used by older call sites. */
    @Transactional
    public boolean updateCourse(int courseId, String name, String description) {
        return updateCourse(courseId, name, description, "General", "ACTIVE");
    }

    /** Deletes a course (cascade removes videos/enrollments via JPA). */
    @Transactional
    public boolean deleteCourse(int courseId) {
        return courseRepository.findById(courseId).map(c -> {
            courseRepository.delete(c);
            return true;
        }).orElse(false);
    }

    // ─── MAPPER ────────────────────────────────────────────────────────────

    public CourseDTO toDTO(Course c) {
        long videoCount   = videoRepository.countByCourse(c);
        long studentCount = enrollmentRepository.countByCourse(c);

        return CourseDTO.builder()
                .id(c.getId())
                .name(c.getName() != null ? c.getName() : "")
                .description(c.getDescription())
                .teacherId(c.getTeacher() != null ? c.getTeacher().getId() : null)
                .teacherName(c.getTeacherName())
                .teacherPhoto(c.getTeacher() != null ? c.getTeacher().getProfilePhoto() : null)
                .category(c.getCategory())
                .status(c.getStatus())
                .createdAt(c.getCreatedAt() != null ? c.getCreatedAt().toString() : "")
                .videoCount((int) videoCount)
                .studentCount((int) studentCount)
                .build();
    }
}