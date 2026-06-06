package com.example.demo.security;

import com.example.demo.entity.User;
import com.example.demo.repository.UserRepository;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.*;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.web.authentication.SimpleUrlAuthenticationFailureHandler;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.Optional;

/**
 * จัดการ error message เมื่อ login ผิด
 * แยกแยะระหว่าง:
 *   - รหัสผ่านผิด
 *   - บัญชีรอการอนุมัติ (PENDING)
 *   - บัญชีถูกปฏิเสธ (REJECTED)
 *   - บัญชีถูกปิดใช้งาน (INACTIVE)
 */
@Component
@RequiredArgsConstructor
public class CustomAuthFailureHandler extends SimpleUrlAuthenticationFailureHandler {

    private final UserRepository userRepository;

    @Override
    public void onAuthenticationFailure(HttpServletRequest request,
                                        HttpServletResponse response,
                                        AuthenticationException exception)
            throws IOException, ServletException {

        String errorMsg = "Tên đăng nhập hoặc mật khẩu không đúng";

        if (exception instanceof DisabledException) {
            // User.status = INACTIVE หรือ PENDING
            String username = request.getParameter("username");
            Optional<User> userOpt = userRepository.findByUsername(username);
            if (userOpt.isPresent()) {
                String status = userOpt.get().getStatus();
                if ("PENDING".equalsIgnoreCase(status)) {
                    errorMsg = "Tài khoản đang chờ phê duyệt";
                } else {
                    errorMsg = "Tài khoản đã bị vô hiệu hóa";
                }
            }
        } else if (exception instanceof LockedException) {
            errorMsg = "Tài khoản đã bị từ chối";
        } else if (exception instanceof BadCredentialsException) {
            errorMsg = "Tên đăng nhập hoặc mật khẩu không đúng";
        }

        String encoded = URLEncoder.encode(errorMsg, StandardCharsets.UTF_8);
        getRedirectStrategy().sendRedirect(request, response, "/login?errorMsg=" + encoded);
    }
}