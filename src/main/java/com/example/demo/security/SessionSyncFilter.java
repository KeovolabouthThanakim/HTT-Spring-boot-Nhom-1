package com.example.demo.security;

import com.example.demo.entity.User;
import com.example.demo.repository.UserRepository;
import jakarta.servlet.*;
import jakarta.servlet.http.*;
import lombok.RequiredArgsConstructor;
import org.springframework.core.annotation.Order;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

import java.io.IOException;

/**
 * หลังจาก Spring Security ยืนยันตัวตนสำเร็จ
 * Filter นี้จะโหลด User entity จาก DB แล้วใส่เข้า session["user"]
 * เพื่อให้ Controller ทุกตัวที่ใช้ session.getAttribute("user") ยังทำงานได้ปกติ
 *
 * วิธีนี้ทำให้ไม่ต้องแก้ไข Controller ทุกตัวเลย
 */
@Component
@Order(2)
@RequiredArgsConstructor
public class SessionSyncFilter implements Filter {

    private final UserRepository userRepository;

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest  req     = (HttpServletRequest) request;
        HttpSession         session = req.getSession(false);

        Authentication auth = SecurityContextHolder.getContext().getAuthentication();

        // ถ้า Spring Security login แล้ว แต่ session["user"] ยังว่าง → sync
        if (auth != null && auth.isAuthenticated()
                && !"anonymousUser".equals(auth.getPrincipal())
                && session != null
                && session.getAttribute("user") == null) {

            String username = auth.getName();
            userRepository.findByUsername(username).ifPresent(user ->
                    session.setAttribute("user", user)
            );
        }

        chain.doFilter(request, response);
    }
}