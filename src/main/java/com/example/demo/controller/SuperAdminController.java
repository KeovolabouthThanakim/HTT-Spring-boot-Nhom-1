package com.example.demo.controller;

import com.example.demo.service.UserService;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

/**
 * SuperAdminController
 *
 * GET  /super-admin-setup  → แสดงหน้าตั้งค่า super_admin (เฉพาะครั้งแรกที่ยังไม่มี)
 * POST /super-admin-setup  → สร้าง super_admin (ทำได้เพียงครั้งเดียว)
 */
@Controller
@RequestMapping("/super-admin-setup")
public class SuperAdminController {

    @Autowired
    private UserService userService;

    // ─── GET: แสดงหน้า setup ───────────────────────────────────────────────
    @GetMapping
    public String showSetup() {
        if (userService.superAdminExists())
            return "redirect:/login";
        return "super-admin-setup"; // maps to /super-admin-setup.jsp
    }

    // ─── POST: สร้าง super_admin (ครั้งเดียว) ─────────────────────────────
    @PostMapping
    public String doSetup(@RequestParam(required = false) String username,
                          @RequestParam(required = false) String password,
                          @RequestParam(required = false) String confirmPassword,
                          Model model) {

        // Layer 1: ถ้ามี super_admin แล้ว — ปฏิเสธ
        if (userService.superAdminExists()) {
            model.addAttribute("error", "Super Admin đã được tạo, không thể tạo lại");
            return "super-admin-setup";
        }

        // Layer 2: ตรวจข้อมูล
        if (username == null || username.trim().isEmpty()
                || password == null || password.isEmpty()) {
            model.addAttribute("error", "Vui lòng điền đầy đủ thông tin");
            return "super-admin-setup";
        }
        if (!password.equals(confirmPassword)) {
            model.addAttribute("error", "Mật khẩu không khớp");
            return "super-admin-setup";
        }
        if (password.length() < 8) {
            model.addAttribute("error", "Mật khẩu phải có ít nhất 8 ký tự");
            return "super-admin-setup";
        }

        // Layer 3: สร้าง super_admin ผ่าน Service
        boolean success = userService.createSuperAdmin(username.trim(), password);
        if (success) {
            return "redirect:/login?setup=done";
        } else {
            model.addAttribute("error", "Không thể tạo Super Admin (có thể đã tồn tại trong hệ thống)");
            return "super-admin-setup";
        }
    }
}
