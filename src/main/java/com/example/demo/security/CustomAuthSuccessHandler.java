package com.example.demo.security;

import com.example.demo.entity.User;
import com.example.demo.repository.UserRepository;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.security.web.authentication.AuthenticationSuccessHandler;
import org.springframework.stereotype.Component;

import java.io.IOException;

/**
 * หลัง Spring Security login สำเร็จ:
 *   1. โหลด User entity จาก DB ใส่ session["user"]
 *   2. Redirect ตาม role โดยตรง (ไม่ผ่าน "/" เพื่อกันวนซ้ำ)
 */
@Component
@RequiredArgsConstructor
public class CustomAuthSuccessHandler implements AuthenticationSuccessHandler {

    private final UserRepository userRepository;

    @Override
    public void onAuthenticationSuccess(HttpServletRequest request,
                                        HttpServletResponse response,
                                        Authentication authentication)
            throws IOException, ServletException {

        String username = authentication.getName();
        HttpSession session = request.getSession();

        // โหลด User entity และใส่เข้า session
        userRepository.findByUsername(username).ifPresent(user ->
                session.setAttribute("user", user)
        );

        User user = (User) session.getAttribute("user");
        if (user == null) {
            response.sendRedirect(request.getContextPath() + "/login?error=true");
            return;
        }

        // Redirect ตาม role โดยตรง (ไม่ใช้ "/" เพื่อป้องกัน redirect loop)
        String role = user.getRole() != null ? user.getRole().toLowerCase() : "";
        String redirectUrl = switch (role) {
            case "student"     -> "/home";
            case "teacher",
                 "admin",
                 "super_admin" -> "/dashboard";
            default            -> "/home";
        };

        response.sendRedirect(request.getContextPath() + redirectUrl);
    }
}