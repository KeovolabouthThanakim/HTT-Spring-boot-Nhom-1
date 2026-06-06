package com.example.demo.dao;

import com.example.demo.service.UserService;
import com.example.demo.repository.UserRepository;
import com.example.demo.entity.User;
import com.example.demo.dto.RegisterRequest;
import org.springframework.stereotype.Component;
import lombok.RequiredArgsConstructor;

@Component
@RequiredArgsConstructor
public class UserDAO {
    private final UserService userService;
    private final UserRepository userRepository;

    public boolean usernameExists(String username) {
        return userService.usernameExists(username);
    }

    public boolean emailExists(String email) {
        return userService.emailExists(email);
    }

    public boolean createSuperAdmin(String u, String p, String f, String l, String e) {
        return userService.createSuperAdmin(u, p, f, l, e);
    }

    public boolean createSuperAdmin(String u, String p) {
        return userService.createSuperAdmin(u, p);
    }

    public boolean registerFullUser(String u, String p, String f, String l, String e, String sid, String dep, String r) {
        RegisterRequest req = new RegisterRequest();
        req.setUsername(u);
        req.setPassword(p);
        req.setFirstName(f);
        req.setLastName(l);
        req.setEmail(e);
        req.setStudentId(sid);
        req.setDepartment(dep);
        req.setRole(r);
        return userService.register(req);
    }

    public boolean superAdminExists() {
        return userService.superAdminExists();
    }

    public boolean deleteAdminById(int id) {
        return userService.deleteUser(id);
    }

    public boolean toggleUserStatus(int id) {
        return userService.toggleUserStatus(id);
    }

    public boolean changePassword(int id, String pw) {
        return userRepository.findById(id).map(u -> {
            u.setPassword(new org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder().encode(pw));
            userRepository.save(u);
            return true;
        }).orElse(false);
    }

    public boolean deleteUser(int id) {
        return userService.deleteUser(id);
    }

    public boolean updateProfile(int userId, String firstName, String lastName, String email) {
        return userService.updateProfile(userId, firstName, lastName, email);
    }

    public boolean changePasswordVerified(int userId, String oldPassword, String newPassword) {
        return userService.changePasswordVerified(userId, oldPassword, newPassword);
    }
}