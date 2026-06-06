package com.example.demo.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;
import java.util.*;

/**
 * Entity แทน model/Course.java เดิม
 * ตาราง: courses (id, name, description, teacher_id, category, status, created_at)
 */
@Entity
@Table(name = "courses")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor
@Builder
public class Course {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    /** DB column จริงคือ "title" — "name" เป็น generated column ที่ copy จาก title */
    @Column(name = "title", nullable = false, length = 200)
    private String name;

    @Column(columnDefinition = "TEXT")
    private String description;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "teacher_id")
    private User teacher;

    @Column(length = 100)
    @Builder.Default
    private String category = "General";

    @Column(nullable = false, length = 20)
    @Builder.Default
    private String status = "ACTIVE";

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @OneToMany(mappedBy = "course", cascade = CascadeType.ALL, orphanRemoval = true)
    @Builder.Default
    private List<Video> videos = new ArrayList<>();

    @OneToMany(mappedBy = "course", cascade = CascadeType.ALL, orphanRemoval = true)
    @Builder.Default
    private List<Enrollment> enrollments = new ArrayList<>();

    @PrePersist
    protected void onCreate() {
        if (createdAt == null) createdAt = LocalDateTime.now();
    }

    // helper เดิมจาก model/Course.java
    public boolean isActive() {
        return "ACTIVE".equalsIgnoreCase(status);
    }

    public String getTeacherName() {
        if (teacher == null) return "";
        return teacher.getFullName().trim();
    }

    public Integer getTeacherId() {
        return teacher != null ? teacher.getId() : null;
    }
}