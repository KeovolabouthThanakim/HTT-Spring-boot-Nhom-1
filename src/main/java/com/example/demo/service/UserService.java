package com.example.demo.service;

import com.example.demo.dto.RegisterRequest;
import com.example.demo.dto.UserDTO;
import com.example.demo.entity.User;
import com.example.demo.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.MessageDigest;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

/**
 * User service with BCrypt password hashing.
 *
 * Migration strategy for existing MD5 passwords in the database:
 *   - login()              : tries BCrypt first, then falls back to MD5.
 *                            On successful MD5 login the password is
 *                            automatically re-hashed to BCrypt (lazy migration).
 *   - register()           : always stores BCrypt.
 *   - createSuperAdmin()   : always stores BCrypt.
 *   - changePasswordVerified(): verifies old password with BCrypt-or-MD5 fallback,
 *                            then stores new password as BCrypt.
 *
 * This means no batch migration script is needed — passwords upgrade
 * transparently on first login after the deployment.
 */
@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;

    // Single PasswordEncoder instance — BCrypt with default strength (10)
    private static final PasswordEncoder PASSWORD_ENCODER = new BCryptPasswordEncoder();

    // ─── LOGIN ────────────────────────────────────────────────────────────

    @Transactional
    public User login(String username, String password) {
        // Look up by username only, then verify password manually
        Optional<User> opt = userRepository.findByUsername(username);
        if (opt.isEmpty()) return null;

        User u = opt.get();

        boolean matched = false;
        boolean isMd5   = false;

        // 1. Try BCrypt (new passwords)
        if (u.getPassword() != null && u.getPassword().startsWith("$2")) {
            matched = PASSWORD_ENCODER.matches(password, u.getPassword());
        }

        // 2. Fallback: try MD5 (legacy passwords)
        if (!matched) {
            String md5 = md5(password);
            if (md5.equals(u.getPassword())) {
                matched = true;
                isMd5   = true;
            }
        }

        if (!matched) return null;

        // Lazy migration: re-hash MD5 passwords to BCrypt on first login
        if (isMd5) {
            u.setPassword(PASSWORD_ENCODER.encode(password));
            userRepository.save(u);
        }

        String status = u.getStatus() != null ? u.getStatus().toUpperCase() : "";
        if ("ACTIVE".equals(status)) return u;

        // Sentinel: username=null, status carries the reason
        User blocked = new User();
        blocked.setStatus(status);
        return blocked;
    }

    public Optional<User> findById(int id) {
        return userRepository.findById(id);
    }

    public Optional<User> findByUsername(String username) {
        return userRepository.findByUsername(username);
    }

    // ─── SUPER ADMIN ──────────────────────────────────────────────────────

    public boolean superAdminExists() {
        return userRepository.countSuperAdmins() > 0;
    }

    @Transactional
    public boolean createSuperAdmin(String username, String password,
                                    String firstName, String lastName, String email) {
        if (userRepository.existsByUsername(username)) return false;
        if (email != null && !email.isBlank() && userRepository.existsByEmail(email)) return false;

        userRepository.save(User.builder()
                .username(username.trim())
                .password(PASSWORD_ENCODER.encode(password))   // BCrypt
                .firstName(firstName.trim())
                .lastName(lastName.trim())
                .email(email.trim())
                .role("SUPER_ADMIN")
                .status("ACTIVE")
                .build());
        return true;
    }

    @Transactional
    public boolean createSuperAdmin(String username, String password) {
        return createSuperAdmin(username, password, "Super", "Admin", username + "@system.local");
    }

    public boolean isSuperAdmin(int userId) {
        return userRepository.findById(userId)
                .map(u -> "SUPER_ADMIN".equalsIgnoreCase(u.getRole()))
                .orElse(false);
    }

    // ─── REGISTRATION ─────────────────────────────────────────────────────

    @Transactional
    public boolean register(RegisterRequest req) {
        if ("SUPER_ADMIN".equalsIgnoreCase(req.getRole())) return false;
        if (userRepository.existsByUsername(req.getUsername())) return false;
        if (req.getEmail() != null && !req.getEmail().isBlank()
                && userRepository.existsByEmail(req.getEmail())) return false;

        String status = "TEACHER".equalsIgnoreCase(req.getRole()) ? "PENDING" : "ACTIVE";

        userRepository.save(User.builder()
                .username(req.getUsername())
                .password(PASSWORD_ENCODER.encode(req.getPassword()))  // BCrypt
                .firstName(req.getFirstName())
                .lastName(req.getLastName())
                .email(req.getEmail())
                .studentId(req.getStudentId() != null && !req.getStudentId().isBlank() ? req.getStudentId() : null)
                .department(req.getDepartment() != null && !req.getDepartment().isBlank() ? req.getDepartment() : null)
                .role(req.getRole().toUpperCase())
                .status(status)
                .build());
        return true;
    }

    public boolean usernameExists(String username) {
        return userRepository.existsByUsername(username);
    }

    public boolean emailExists(String email) {
        return userRepository.existsByEmail(email);
    }

    // ─── USER MANAGEMENT ──────────────────────────────────────────────────

    public List<UserDTO> getAllUsers() {
        return userRepository.findAll().stream().map(this::toDTO).collect(Collectors.toList());
    }

    public List<UserDTO> getUsersByRole(String role) {
        return userRepository.findByRoleIgnoreCase(role).stream()
                .map(this::toDTO).collect(Collectors.toList());
    }

    @Transactional
    public boolean updateUserRole(int userId, String newRole) {
        if ("SUPER_ADMIN".equalsIgnoreCase(newRole)) return false;
        return userRepository.findById(userId).map(u -> {
            if ("SUPER_ADMIN".equalsIgnoreCase(u.getRole())) return false;
            u.setRole(newRole.toUpperCase());
            userRepository.save(u);
            return true;
        }).orElse(false);
    }

    @Transactional
    public boolean deleteUser(int userId) {
        if (isSuperAdmin(userId)) return false;
        return userRepository.findById(userId).map(u -> {
            userRepository.delete(u);
            return true;
        }).orElse(false);
    }

    @Transactional
    public boolean toggleUserStatus(int userId) {
        if (isSuperAdmin(userId)) return false;
        return userRepository.findById(userId).map(u -> {
            u.setStatus("ACTIVE".equalsIgnoreCase(u.getStatus()) ? "INACTIVE" : "ACTIVE");
            userRepository.save(u);
            return true;
        }).orElse(false);
    }

    // ─── PROFILE ──────────────────────────────────────────────────────────

    /**
     * Updates firstName, lastName, email.
     * Caller (ProfileController) is responsible for reloading the session user
     * after a successful update via userService.findById().
     */
    @Transactional
    public boolean updateProfile(int userId, String firstName, String lastName, String email) {
        return userRepository.findById(userId).map(u -> {
            // Check email ซ้ำกับ user อื่น
            if (email != null && !email.isBlank()) {
                String trimmedEmail = email.trim();
                boolean emailTakenByOther = userRepository.findByEmail(trimmedEmail)
                        .map(other -> other.getId() != userId)
                        .orElse(false);
                if (emailTakenByOther) return false;
                u.setEmail(trimmedEmail);
            } else {
                u.setEmail(null);
            }
            u.setFirstName(firstName != null ? firstName.trim() : null);
            u.setLastName(lastName   != null ? lastName.trim()  : null);
            userRepository.save(u);
            return true;
        }).orElse(false);
    }

    /**
     * Admin resets a user's password directly (no old password required).
     * Cannot reset a SUPER_ADMIN's password.
     */
    @Transactional
    public boolean resetPasswordByAdmin(int userId, String newPassword) {
        if (isSuperAdmin(userId)) return false;
        return userRepository.findById(userId).map(u -> {
            u.setPassword(PASSWORD_ENCODER.encode(newPassword));
            userRepository.save(u);
            return true;
        }).orElse(false);
    }

    /**
     * Verifies oldPassword (BCrypt or MD5 fallback), then saves newPassword as BCrypt.
     */
    @Transactional
    public boolean changePasswordVerified(int userId, String oldPassword, String newPassword) {
        return userRepository.findById(userId).map(u -> {
            boolean oldMatches;
            if (u.getPassword() != null && u.getPassword().startsWith("$2")) {
                // BCrypt stored
                oldMatches = PASSWORD_ENCODER.matches(oldPassword, u.getPassword());
            } else {
                // MD5 legacy
                oldMatches = md5(oldPassword).equals(u.getPassword());
            }
            if (!oldMatches) return false;

            u.setPassword(PASSWORD_ENCODER.encode(newPassword));  // Always store as BCrypt
            userRepository.save(u);
            return true;
        }).orElse(false);
    }

    // ─── TEACHER APPROVAL ─────────────────────────────────────────────────

    public List<UserDTO> getPendingTeachers() {
        return userRepository.findPendingTeachers().stream()
                .map(this::toDTO).collect(Collectors.toList());
    }

    public long countPendingTeachers() {
        return userRepository.countPendingTeachers();
    }

    @Transactional
    public boolean approveTeacher(int userId) {
        return userRepository.findById(userId).map(u -> {
            if (!"TEACHER".equalsIgnoreCase(u.getRole())) return false;
            if (!"PENDING".equalsIgnoreCase(u.getStatus())) return false;
            u.setStatus("ACTIVE");
            userRepository.save(u);
            return true;
        }).orElse(false);
    }

    @Transactional
    public boolean rejectTeacher(int userId) {
        return userRepository.findById(userId).map(u -> {
            if (!"TEACHER".equalsIgnoreCase(u.getRole())) return false;
            if (!"PENDING".equalsIgnoreCase(u.getStatus())) return false;
            u.setStatus("REJECTED");
            userRepository.save(u);
            return true;
        }).orElse(false);
    }

    // ─── MAPPER ───────────────────────────────────────────────────────────

    public UserDTO toDTO(User u) {
        return UserDTO.builder()
                .id(u.getId()).username(u.getUsername())
                .firstName(u.getFirstName()).lastName(u.getLastName())
                .email(u.getEmail()).studentId(u.getStudentId())
                .department(u.getDepartment()).role(u.getRole()).status(u.getStatus())
                .build();
    }

    @Transactional
    public boolean updateProfilePhoto(int userId, String photoPath) {
        return userRepository.findById(userId).map(u -> {
            u.setProfilePhoto(photoPath);
            userRepository.save(u);
            return true;
        }).orElse(false);
    }

    // ─── MD5 (kept for legacy password migration only) ────────────────────

    public static String md5(String input) {
        try {
            MessageDigest md = MessageDigest.getInstance("MD5");
            byte[] bytes = md.digest(input.getBytes("UTF-8"));
            StringBuilder sb = new StringBuilder();
            for (byte b : bytes) sb.append(String.format("%02x", b));
            return sb.toString();
        } catch (Exception e) {
            throw new RuntimeException("MD5 error", e);
        }
    }
}