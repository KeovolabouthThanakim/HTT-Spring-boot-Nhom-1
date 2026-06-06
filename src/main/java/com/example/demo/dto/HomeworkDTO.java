package com.example.demo.dto;

import lombok.*;

/** DTO แทน model/Homework.java เดิม — เพิ่ม score / maxScore */
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class HomeworkDTO {
    private Integer id;
    private Integer studentId;
    private String  studentName;
    private Integer courseId;
    private Integer videoId;
    private String  title;
    private String  description;
    private String  filePath;
    private String  fileName;
    private String  submittedAt;
    private String  status;
    private String  teacherComment;

    // ─── ฟีเจอร์ใหม่: คะแนน ──────────────────────────────────────────────
    /** null = ยังไม่ได้ให้คะแนน */
    private Integer score;
    /** คะแนนเต็ม ค่าเริ่มต้น 100 */
    @Builder.Default
    private Integer maxScore = 100;

    // ─── Null-safe getters ─────────────────────────────────────────────────
    public String  getTitle()          { return title          != null ? title          : ""; }
    public String  getDescription()    { return description    != null ? description    : ""; }
    public String  getFileName()       { return fileName       != null ? fileName       : ""; }
    public String  getSubmittedAt()    { return submittedAt    != null ? submittedAt    : ""; }
    public String  getStatus()         { return status         != null ? status         : "PENDING"; }
    public String  getTeacherComment() { return teacherComment != null ? teacherComment : ""; }
    public String  getStudentName()    { return studentName    != null ? studentName    : ""; }
    public Integer getMaxScore()       { return maxScore       != null ? maxScore       : 100; }

    /** คืนค่า "score / maxScore" เช่น "85/100" — ถ้ายังไม่ให้คะแนนคืน null */
    public String getScoreDisplay() {
        if (score == null) return null;
        return score + "/" + getMaxScore();
    }

    /** true ถ้าครูให้คะแนนแล้ว */
    public boolean isScored() {
        return score != null;
    }
}
