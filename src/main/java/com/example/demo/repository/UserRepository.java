package com.example.demo.repository;

import com.example.demo.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.sql.Timestamp;
import java.util.List;
import java.util.Optional;

/**
 * แทนที่ UserDAO.java เดิม
 * Spring Data JPA สร้าง SQL ให้อัตโนมัติจาก method name
 */
@Repository
public interface UserRepository extends JpaRepository<User, Integer> {

    Optional<User> findByUsername(String username);

    Optional<User> findByUsernameAndPassword(String username, String password);

    boolean existsByUsername(String username);

    boolean existsByEmail(String email);

    Optional<User> findByEmail(String email);

    List<User> findByRoleIgnoreCase(String role);

    List<User> findByRoleIgnoreCaseAndStatus(String role, String status);

    // นับ SUPER_ADMIN — ใช้ใน superAdminExists()
    @Query("SELECT COUNT(u) FROM User u WHERE LOWER(u.role) = 'super_admin'")
    long countSuperAdmins();

    // ครูรอการอนุมัติ — getPendingTeachers()
    @Query("SELECT u FROM User u WHERE LOWER(u.role) = 'teacher' AND u.status = 'PENDING' ORDER BY u.id")
    List<User> findPendingTeachers();

    // นับครูรอการอนุมัติ — countPendingTeachers()
    @Query("SELECT COUNT(u) FROM User u WHERE LOWER(u.role) = 'teacher' AND u.status = 'PENDING'")
    long countPendingTeachers();

    // นับนักเรียนทั้งหมด — DashboardDAO.countStudents()
    @Query("SELECT COUNT(u) FROM User u WHERE LOWER(u.role) = 'student'")
    long countStudents();

    // นับครูทั้งหมด — DashboardDAO.countTeachers()
    @Query("SELECT COUNT(u) FROM User u WHERE LOWER(u.role) = 'teacher'")
    long countTeachers();

    // นับนักเรียนใหม่วันนี้ — DashboardDAO.countNewStudentsToday()
    @Query(value = "SELECT COUNT(*) FROM users WHERE LOWER(role)='student' AND DATE(created_at)=CURDATE() AND YEAR(created_at) BETWEEN 2000 AND 2100",
            nativeQuery = true)
    long countNewStudentsToday();

    // นับครูรอการอนุมัติที่ register หลัง since
    @org.springframework.data.jpa.repository.Query(
            value = "SELECT COUNT(*) FROM users WHERE UPPER(role) = 'TEACHER' AND UPPER(status) = 'PENDING' AND created_at > :since",
            nativeQuery = true)
    long countPendingTeachersSince(@org.springframework.data.repository.query.Param("since") Timestamp since);
}