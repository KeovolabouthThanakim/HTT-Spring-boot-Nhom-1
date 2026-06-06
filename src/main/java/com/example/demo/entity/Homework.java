package com.example.demo.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

/**
 * Entity แทน model/Homework.java เดิม
 * ตาราง: homework_submissions
 * (id, student_id, course_id, video_id, title, description,
 *  file_path, file_name, submitted_at, status, teacher_comment,
 *  score, max_score)   ← เพิ่มใหม่
 */
@Entity
@Table(name = "homework_submissions")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor
@Builder
public class Homework {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "student_id", nullable = false)
    private User student;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "course_id", nullable = false)
    private Course course;

    /** บทเรียนที่ส่งการบ้านนี้ (0 = ทั้งคอร์ส) */
    @Column(name = "video_id")
    @Builder.Default
    private Integer videoId = 0;

    @Column(nullable = false, length = 255)
    private String title;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(name = "file_path", length = 500)
    private String filePath;

    @Column(name = "file_name", length = 255)
    private String fileName;

    @Column(name = "submitted_at")
    private LocalDateTime submittedAt;

    /** PENDING / REVIEWED */
    @Column(length = 20)
    @Builder.Default
    private String status = "PENDING";

    @Column(name = "teacher_comment", columnDefinition = "TEXT")
    private String teacherComment;

    // ─── ฟีเจอร์ใหม่: คะแนน ──────────────────────────────────────────────

    /** คะแนนที่ครูให้ — null หมายถึงยังไม่ได้ให้คะแนน */
    @Column(name = "score")
    private Integer score;

    /** คะแนนเต็ม ค่าเริ่มต้น 100 */
    @Column(name = "max_score")
    @Builder.Default
    private Integer maxScore = 100;

    @PrePersist
    protected void onCreate() {
        if (submittedAt == null) submittedAt = LocalDateTime.now();
    }
}
