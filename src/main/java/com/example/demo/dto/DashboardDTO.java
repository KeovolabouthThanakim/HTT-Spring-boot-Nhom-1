package com.example.demo.dto;

import lombok.*;
import java.util.List;
import java.util.Map;

/** DTO รวมสถิติทั้งหมดสำหรับ Dashboard — แทน DashboardDAO เดิม */
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class DashboardDTO {
    private long totalStudents;
    private long totalTeachers;
    private long totalCourses;
    private long totalEnrollments;
    private long newStudentsToday;
    private long newCoursesThisMonth;
    private long pendingTeachers;
    private List<Map<String,Object>> monthlyEnrollments;
    private List<Map<String,Object>> topCourses;
    private List<Map<String,Object>> recentEnrollments;
    private List<Map<String,Object>> monthlyDetailedStats;
    private List<Map<String,Object>> recentHomeworkSubmissions;
    private List<Map<String,Object>> recentReviews;
}