package com.example.demo.dto;

import lombok.*;

/** DTO แทน model/Course.java เดิม สำหรับส่งไปยัง View */
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class CourseDTO {
    private Integer id;
    private String  name;
    private String  description;
    private Integer teacherId;
    private String  teacherName;
    private String  teacherPhoto;
    private String  category;
    private String  status;
    private String  createdAt;
    private int     videoCount;
    private int     studentCount;

    public boolean isActive() { return "ACTIVE".equalsIgnoreCase(status); }

    public String getTeacherName() {
        return teacherName != null ? teacherName.trim() : "";
    }

    public String getCategory() {
        return category != null ? category : "General";
    }
}