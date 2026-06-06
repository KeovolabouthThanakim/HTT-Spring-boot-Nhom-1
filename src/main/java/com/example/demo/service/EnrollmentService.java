package com.example.demo.service;

import com.example.demo.entity.Course;
import com.example.demo.entity.Enrollment;
import com.example.demo.entity.User;
import com.example.demo.repository.CourseRepository;
import com.example.demo.repository.EnrollmentRepository;
import com.example.demo.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

/**
 * Service แทนที่ EnrollmentDAO.java เดิม
 */
@Service
@RequiredArgsConstructor
public class EnrollmentService {

    private final EnrollmentRepository enrollmentRepository;
    private final UserRepository       userRepository;
    private final CourseRepository     courseRepository;

    /** enroll() เดิม — ถ้าลงแล้วไม่ทำซ้ำ */
    @Transactional
    public boolean enroll(int studentId, int courseId) {
        User student = userRepository.findById(studentId).orElse(null);
        Course course = courseRepository.findById(courseId).orElse(null);
        if (student == null || course == null) return false;
        if (enrollmentRepository.existsByStudentAndCourse(student, course)) return false;

        enrollmentRepository.save(Enrollment.builder()
                .student(student).course(course).build());
        return true;
    }

    /** isEnrolled() เดิม */
    public boolean isEnrolled(int studentId, int courseId) {
        User student = userRepository.findById(studentId).orElse(null);
        Course course = courseRepository.findById(courseId).orElse(null);
        if (student == null || course == null) return false;
        return enrollmentRepository.existsByStudentAndCourse(student, course);
    }

    /** getEnrolledCourseIds() เดิม */
    public List<Integer> getEnrolledCourseIds(int studentId) {
        return userRepository.findById(studentId)
                .map(s -> enrollmentRepository.findByStudent(s).stream()
                        .map(e -> e.getCourse().getId())
                        .collect(Collectors.toList()))
                .orElse(List.of());
    }

    /** countEnrollmentsByCourse() เดิม */
    public int countEnrollmentsByCourse(int courseId) {
        return courseRepository.findById(courseId)
                .map(c -> (int) enrollmentRepository.countByCourse(c))
                .orElse(0);
    }

    /** unenroll() เดิม */
    @Transactional
    public boolean unenroll(int studentId, int courseId) {
        User student = userRepository.findById(studentId).orElse(null);
        Course course = courseRepository.findById(courseId).orElse(null);
        if (student == null || course == null) return false;
        return enrollmentRepository.findByStudentAndCourse(student, course)
                .map(e -> { enrollmentRepository.delete(e); return true; })
                .orElse(false);
    }
}