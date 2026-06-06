package com.example.demo.service;

import com.example.demo.dto.HomeworkDTO;
import com.example.demo.entity.Course;
import com.example.demo.entity.Homework;
import com.example.demo.entity.User;
import com.example.demo.repository.CourseRepository;
import com.example.demo.repository.HomeworkRepository;
import com.example.demo.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class HomeworkService {

    private final HomeworkRepository homeworkRepository;
    private final UserRepository     userRepository;
    private final CourseRepository   courseRepository;

    // ─── WRITE ────────────────────────────────────────────────────────────

    @Transactional
    public boolean submitHomework(int studentId, int courseId, int videoId,
                                  String title, String description,
                                  String filePath, String fileName) {
        User student = userRepository.findById(studentId).orElse(null);
        Course course = courseRepository.findById(courseId).orElse(null);
        if (student == null || course == null) return false;

        homeworkRepository.save(Homework.builder()
                .student(student).course(course).videoId(videoId)
                .title(title)
                .description(description != null ? description : "")
                .filePath(filePath).fileName(fileName)
                .status("PENDING")
                .build());
        return true;
    }

    /**
     * markReviewed() — อัปเดตสถานะ + feedback + คะแนน (ถ้ามี)
     *
     * @param hwId           ID ของการบ้าน
     * @param comment        ความคิดเห็นครู (null = ไม่มี)
     * @param score          คะแนนที่ให้ (null = ไม่ให้คะแนน)
     * @param maxScore       คะแนนเต็ม (null = ใช้ค่าเดิมของ entity หรือ 100)
     */
    @Transactional
    public boolean markReviewed(int hwId, String comment, Integer score, Integer maxScore) {
        return homeworkRepository.findById(hwId).map(h -> {
            h.setStatus("REVIEWED");
            h.setTeacherComment(comment != null ? comment : "");
            if (score != null) {
                h.setScore(score);
                h.setMaxScore(maxScore != null ? maxScore : (h.getMaxScore() != null ? h.getMaxScore() : 100));
            }
            homeworkRepository.save(h);
            return true;
        }).orElse(false);
    }

    /** overload สำหรับ backward-compat — ไม่ให้คะแนน */
    @Transactional
    public boolean markReviewed(int hwId, String comment) {
        return markReviewed(hwId, comment, null, null);
    }

    @Transactional
    public boolean updateHomework(int hwId, String title, String description,
                                  String newFilePath, String newFileName) {
        return homeworkRepository.findById(hwId).map(h -> {
            h.setTitle(title);
            h.setDescription(description != null ? description : "");
            if (newFilePath != null && !newFilePath.isEmpty()) {
                h.setFilePath(newFilePath);
                h.setFileName(newFileName);
            }
            homeworkRepository.save(h);
            return true;
        }).orElse(false);
    }

    @Transactional
    public boolean deleteHomework(int hwId) {
        return homeworkRepository.findById(hwId).map(h -> {
            homeworkRepository.delete(h);
            return true;
        }).orElse(false);
    }

    // ─── READ ─────────────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public List<HomeworkDTO> getByStudentAndCourse(int studentId, int courseId) {
        User student = userRepository.findById(studentId).orElse(null);
        Course course = courseRepository.findById(courseId).orElse(null);
        if (student == null || course == null) return List.of();
        return homeworkRepository.findByStudentAndCourseOrderBySubmittedAtDesc(student, course)
                .stream().map(this::toDTO).collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<HomeworkDTO> getStudentsByCourse(int courseId, int teacherId) {
        // กรองตาม role=STUDENT เท่านั้น ป้องกัน staff (teacher/admin/super_admin)
        // ทุกคนโผล่ในตารางนักเรียน ไม่ใช่แค่ครูเจ้าของคอร์ส
        return homeworkRepository.findStudentsByCourseId(courseId)
                .stream().map(this::toDTO).collect(Collectors.toList());
    }

    public long countPendingByCourse(int courseId) {
        return homeworkRepository.countPendingStudentsByCourseId(courseId);
    }

    public long countAllPendingForTeacher(int teacherId) {
        return homeworkRepository.countAllPendingHomeworkForTeacher(teacherId);
    }

    public long countNewPendingForTeacher(int teacherId, int hours) {
        return homeworkRepository.countNewPendingHomeworkForTeacher(teacherId, hours);
    }

    public long countRecentEnrollmentsByTeacher(int teacherId) {
        return homeworkRepository.countRecentEnrollmentsByTeacher(teacherId);
    }

    @Transactional(readOnly = true)
    public List<HomeworkDTO> getAllTeacherFiles(int courseId) {
        return homeworkRepository.findTeacherFilesByCourseId(courseId)
                .stream().map(this::toDTO).collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<HomeworkDTO> getTeacherFiles(int courseId, int teacherId) {
        Course course = courseRepository.findById(courseId).orElse(null);
        User teacher = userRepository.findById(teacherId).orElse(null);
        if (course == null || teacher == null) return List.of();
        return homeworkRepository.findByCourseAndStudentOrderBySubmittedAtDesc(course, teacher)
                .stream().map(this::toDTO).collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public long countByStudentAndCourse(int studentId, int courseId) {
        User student = userRepository.findById(studentId).orElse(null);
        Course course = courseRepository.findById(courseId).orElse(null);
        if (student == null || course == null) return 0;
        return homeworkRepository.countByStudentAndCourse(student, course);
    }

    public Optional<HomeworkDTO> getById(int id) {
        return homeworkRepository.findById(id).map(this::toDTO);
    }

    public Optional<Homework> getEntityById(int id) {
        return homeworkRepository.findById(id);
    }

    // ─── MAPPER ───────────────────────────────────────────────────────────

    public HomeworkDTO toDTO(Homework h) {
        String studentName = h.getStudent() != null ? h.getStudent().getFullName() : "";

        return HomeworkDTO.builder()
                .id(h.getId())
                .studentId(h.getStudent() != null ? h.getStudent().getId() : null)
                .studentName(studentName)
                .courseId(h.getCourse() != null ? h.getCourse().getId() : null)
                .videoId(h.getVideoId())
                .title(h.getTitle())
                .description(h.getDescription())
                .filePath(h.getFilePath())
                .fileName(h.getFileName())
                .submittedAt(h.getSubmittedAt() != null ? h.getSubmittedAt().toString() : "")
                .status(h.getStatus())
                .teacherComment(h.getTeacherComment())
                .score(h.getScore())
                .maxScore(h.getMaxScore() != null ? h.getMaxScore() : 100)
                .build();
    }
}