package com.example.demo.controller;

import com.example.demo.service.UserService;
import com.example.demo.entity.User;

import jakarta.servlet.http.HttpSession;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.*;

import java.io.UnsupportedEncodingException;
import java.net.URLEncoder;

/**
 * TeacherApprovalController — จัดการการอนุมัติ / ปฏิเสธ ครูที่สมัครใหม่
 * เฉพาะ ADMIN และ SUPER_ADMIN เท่านั้น
 *
 * POST /teacher-approval
 *   action = approve | reject
 *   userId = <id>
 */
@Controller
@RequestMapping("/teacher-approval")
public class TeacherApprovalController {

    @Autowired
    private UserService userService;

    @PostMapping
    public String doApproval(@RequestParam(required = false) String  action,
                             @RequestParam(required = false) Integer userId,
                             HttpSession session) throws UnsupportedEncodingException {

        // ── ตรวจสิทธิ์ ────────────────────────────────────────────────────
        User currentUser = (User) session.getAttribute("user");
        if (currentUser == null) return "redirect:/login";

        String role = currentUser.getRole().toLowerCase();
        if (!role.equals("admin") && !role.equals("super_admin"))
            return "redirect:/dashboard?tab=approval&approvalErr=" + encode("Access denied");

        if (userId == null || userId <= 0)
            return "redirect:/dashboard?tab=approval&approvalErr=" + encode("ID người dùng không hợp lệ");

        // ── ดำเนินการ ─────────────────────────────────────────────────────
        boolean ok;
        String  successMsg;
        String  errorMsg;

        if ("approve".equals(action)) {
            ok = userService.approveTeacher(userId);
            successMsg = "Đã phê duyệt giảng viên thành công ✓";
            errorMsg   = "Không thể phê duyệt (có thể đã được xử lý trước đó)";

        } else if ("reject".equals(action)) {
            ok = userService.rejectTeacher(userId);
            successMsg = "Đã từ chối đơn đăng ký thành công";
            errorMsg   = "Không thể từ chối (có thể đã được xử lý trước đó)";

        } else {
            return "redirect:/dashboard?tab=approval&approvalErr=" + encode("Lệnh không hợp lệ");
        }

        if (ok) {
            return "redirect:/dashboard?tab=approval&success=" + encode(successMsg);
        } else {
            return "redirect:/dashboard?tab=approval&approvalErr=" + encode(errorMsg);
        }
    }

    private String encode(String value) throws UnsupportedEncodingException {
        return URLEncoder.encode(value, "UTF-8");
    }
}
