package com.example.demo.dto;

import jakarta.validation.constraints.*;
import lombok.*;

/** DTO รับข้อมูลจากฟอร์มสมัครสมาชิก — เทียบกับ RegisterServlet.doPost() เดิม */
@Getter @Setter @NoArgsConstructor @AllArgsConstructor
public class RegisterRequest {

    @NotBlank(message = "Vui lòng nhập Username")
    private String username;

    @NotBlank(message = "Vui lòng nhập Password")
    @Size(min = 6, message = "Mật khẩu phải có ít nhất 6 ký tự")
    private String password;

    private String confirmPassword;
    private String firstName;
    private String lastName;

    @Email(message = "Định dạng Email không hợp lệ")
    private String email;

    private String studentId;
    private String department;

    @NotBlank(message = "Vui lòng chọn Role")
    private String role; // STUDENT หรือ TEACHER
}