package com.example.demo.controller;

import com.example.demo.entity.User;
import com.example.demo.service.UserService;
import jakarta.servlet.http.HttpSession;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.UUID;

@Controller
@RequiredArgsConstructor
public class ProfileController {

    private final UserService userService;

    // ── POST /profile ─────────────────────────────────────────────────────
    @PostMapping("/profile")
    public String updateProfile(
            @RequestParam(required = false) String firstName,
            @RequestParam(required = false) String lastName,
            @RequestParam(required = false) String email,
            @RequestParam(required = false) String redirectTo,
            HttpSession session) {

        User user = (User) session.getAttribute("user");
        if (user == null) return "redirect:/login";

        if (firstName == null || firstName.isBlank() ||
                lastName  == null || lastName.isBlank()) {
            String tab = "student".equalsIgnoreCase(user.getRole()) ? "profile" : "profile";
            return "redirect:" + buildRedirect(user.getRole(), tab, "err=emptyFields");
        }

        // Check email ซ้ำล่วงหน้า (จะถูก double-check ใน service ด้วย)
        boolean ok = userService.updateProfile(user.getId(), firstName, lastName, email);
        if (!ok) {
            return "redirect:" + buildRedirect(user.getRole(), "profile", "err=emailTaken");
        }

        userService.findById(user.getId()).ifPresent(updated ->
                session.setAttribute("user", updated)
        );

        String back = (redirectTo != null && !redirectTo.isBlank()) ? redirectTo : null;
        if (back != null) return "redirect:" + back + "?success=profileUpdated";
        return "redirect:" + buildRedirect(user.getRole(), "profile", "success=profileUpdated");
    }

    // ── POST /profile/photo ───────────────────────────────────────────────
    @PostMapping("/profile/photo")
    public String uploadPhoto(
            @RequestParam("photo") MultipartFile photo,
            @RequestParam(required = false) String redirectTo,
            HttpSession session) {

        User user = (User) session.getAttribute("user");
        if (user == null) return "redirect:/login";

        if (photo == null || photo.isEmpty()) {
            return "redirect:" + buildRedirect(user.getRole(), "profile", "err=noFile");
        }

        // Validate: chỉ chấp nhận ảnh
        String contentType = photo.getContentType();
        if (contentType == null || !contentType.startsWith("image/")) {
            return "redirect:" + buildRedirect(user.getRole(), "profile", "err=invalidFile");
        }

        // Validate: max 2MB
        if (photo.getSize() > 2 * 1024 * 1024) {
            return "redirect:" + buildRedirect(user.getRole(), "profile", "err=fileTooLarge");
        }

        try {
            // Lấy phần mở rộng file
            String originalName = photo.getOriginalFilename();
            String ext = (originalName != null && originalName.contains("."))
                    ? originalName.substring(originalName.lastIndexOf(".")).toLowerCase()
                    : ".jpg";

            // Lưu vào thư mục uploads/profile/
            String uploadDir = System.getProperty("user.dir") + "/uploads/profile/";
            Path dirPath = Paths.get(uploadDir);
            if (!Files.exists(dirPath)) Files.createDirectories(dirPath);

            String fileName = "user_" + user.getId() + "_" + UUID.randomUUID().toString().substring(0, 8) + ext;
            Path filePath = dirPath.resolve(fileName);
            photo.transferTo(filePath.toFile());

            // Lưu đường dẫn vào DB
            String photoPath = "profile/" + fileName;
            boolean ok = userService.updateProfilePhoto(user.getId(), photoPath);
            if (ok) {
                userService.findById(user.getId()).ifPresent(updated ->
                        session.setAttribute("user", updated)
                );
            }
        } catch (IOException e) {
            return "redirect:" + buildRedirect(user.getRole(), "profile", "err=uploadFailed");
        }

        String back = (redirectTo != null && !redirectTo.isBlank()) ? redirectTo : null;
        if (back != null) {
            // ถ้า redirectTo มี ? อยู่แล้ว ให้ต่อด้วย & แทน ?
            String sep = back.contains("?") ? "&" : "?";
            return "redirect:" + back + sep + "success=photoUpdated";
        }
        return "redirect:" + buildRedirect(user.getRole(), "profile", "success=photoUpdated");
    }

    // ── POST /security ────────────────────────────────────────────────────
    @PostMapping("/security")
    public String changePassword(
            @RequestParam String oldPassword,
            @RequestParam String newPassword,
            @RequestParam String confirmPassword,
            HttpSession session) {

        User user = (User) session.getAttribute("user");
        if (user == null) return "redirect:/login";

        if (newPassword == null || newPassword.length() < 8) {
            return "redirect:" + buildRedirect(user.getRole(), "security", "err=passwordTooShort");
        }
        if (!newPassword.equals(confirmPassword)) {
            return "redirect:" + buildRedirect(user.getRole(), "security", "err=passwordMismatch");
        }

        boolean ok = userService.changePasswordVerified(user.getId(), oldPassword, newPassword);
        if (!ok) {
            return "redirect:" + buildRedirect(user.getRole(), "security", "err=wrongOldPassword");
        }

        return "redirect:" + buildRedirect(user.getRole(), "security", "success=passwordChanged");
    }

    // ── Helper ────────────────────────────────────────────────────────────
    private String buildRedirect(String role, String tab, String param) {
        if ("student".equalsIgnoreCase(role)) {
            return "/home?tab=ho-so&" + param;
        }
        return "/dashboard?tab=" + tab + "&" + param;
    }
}
