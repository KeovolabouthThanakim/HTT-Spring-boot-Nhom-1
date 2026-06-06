package com.example.demo.security;

import com.example.demo.entity.User;
import com.example.demo.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.*;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * เชื่อม User entity ของโปรเจกต์กับ Spring Security
 *
 * Spring Security จะเรียก loadUserByUsername() ทุกครั้งที่มีการ login
 * เพื่อโหลด user จาก DB และตรวจสอบ password + role
 */
@Service
@RequiredArgsConstructor
public class CustomUserDetailsService implements UserDetailsService {

    private final UserRepository userRepository;

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new UsernameNotFoundException("ไม่พบผู้ใช้: " + username));

        // ตรวจสอบสถานะ account
        boolean enabled    = "ACTIVE".equalsIgnoreCase(user.getStatus());
        boolean nonLocked  = !"REJECTED".equalsIgnoreCase(user.getStatus());

        // แปลง role เป็น Spring Security format (ต้องขึ้นต้นด้วย ROLE_)
        String role = "ROLE_" + (user.getRole() != null ? user.getRole().toUpperCase() : "STUDENT");

        return org.springframework.security.core.userdetails.User.builder()
                .username(user.getUsername())
                .password(user.getPassword())          // BCrypt hash จาก DB
                .authorities(List.of(new SimpleGrantedAuthority(role)))
                .disabled(!enabled)
                .accountLocked(!nonLocked)
                .build();
    }
}