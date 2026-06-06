package com.example.demo.dto;

import lombok.*;

/** DTO cho thông tin đánh giá giảng viên */
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class TeacherReviewDTO {
    private Integer id;
    private Integer studentId;
    private String  studentName;
    private Integer teacherId;
    private String  teacherName;
    private Integer courseId;
    private String  courseName;
    private Integer rating;
    private String  comment;
    private String  createdAt;

    public String getComment()     { return comment     != null ? comment     : ""; }
    public String getStudentName() { return studentName != null ? studentName : ""; }
    public String getTeacherName() { return teacherName != null ? teacherName : ""; }
    public String getCourseName()  { return courseName  != null ? courseName  : ""; }
    public String getCreatedAt()   { return createdAt   != null ? createdAt   : ""; }
}
