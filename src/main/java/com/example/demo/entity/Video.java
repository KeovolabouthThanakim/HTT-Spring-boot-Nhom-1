package com.example.demo.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

/**
 * Entity แทน model/Video.java เดิม
 * ตาราง: videos (id, course_id, title, description, file_path, order_no, duration, created_at)
 */
@Entity
@Table(name = "videos")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor
@Builder
public class Video {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "course_id", nullable = false)
    private Course course;

    @Column(nullable = false, length = 255)
    private String title;

    @Column(columnDefinition = "TEXT")
    private String description;

    /** URL หรือ path ของวิดีโอ (YouTube / Drive / local) — DB column: file_path */
    @Column(name = "file_path", length = 500)
    private String filePath;

    @Column(name = "order_no")
    @Builder.Default
    private Integer orderNo = 1;

    @Column(length = 20)
    private String duration;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        if (createdAt == null) createdAt = LocalDateTime.now();
    }

    // alias เดิมจาก model/Video.java
    public String getVideoUrl() { return filePath; }
    public void   setVideoUrl(String url) { this.filePath = url; }

    public String getUploadedAt() { return createdAt != null ? createdAt.toString() : ""; }
}