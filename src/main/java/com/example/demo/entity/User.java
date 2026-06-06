package com.example.demo.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

/**
 * Entity แทน model/User.java เดิม
 * ตาราง: users (id, username, password, first_name, last_name, email,
 *               student_id, department, role, status, created_at)
 */
@Entity
@Table(name = "users")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor
@Builder
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(nullable = false, unique = true, length = 100)
    private String username;

    @Column(nullable = false)
    private String password;

    @Column(name = "first_name", length = 100)
    private String firstName;

    @Column(name = "last_name", length = 100)
    private String lastName;

    @Column(unique = true, length = 150)
    private String email;

    @Column(name = "student_id", length = 50)
    private String studentId;

    @Column(length = 100)
    private String department;

    /** STUDENT / TEACHER / ADMIN / SUPER_ADMIN */
    @Column(nullable = false, length = 20)
    @Builder.Default
    private String role = "STUDENT";

    /** ACTIVE / INACTIVE / PENDING / REJECTED */
    @Column(nullable = false, length = 20)
    @Builder.Default
    private String status = "ACTIVE";

    @Column(name = "profile_photo", length = 500)
    private String profilePhoto;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        if (createdAt == null) createdAt = LocalDateTime.now();
    }

    // ─── helper methods เดิมจาก model/User.java ───────────────────

    public boolean isActive() {
        return "ACTIVE".equalsIgnoreCase(status);
    }

    public String getFullName() {
        if (firstName != null && lastName != null) return firstName + " " + lastName;
        if (firstName != null) return firstName;
        return username;
    }
}