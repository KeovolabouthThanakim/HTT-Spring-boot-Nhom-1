package com.example.demo.dto;

import lombok.*;

/** DTO สำหรับแสดงข้อมูล User (ไม่รวม password) */
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class UserDTO {
    private Integer id;
    private String  username;
    private String  firstName;
    private String  lastName;
    private String  email;
    private String  studentId;
    private String  department;
    private String  role;
    private String  status;

    public String getFullName() {
        if (firstName != null && lastName != null) return firstName + " " + lastName;
        if (firstName != null) return firstName;
        return username != null ? username : "";
    }

    public boolean isActive() { return "ACTIVE".equalsIgnoreCase(status); }
}