package com.example.demo.dto;

import lombok.*;

/** DTO แทน model/Video.java เดิม */
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class VideoDTO {
    private Integer id;
    private Integer courseId;
    private String  title;
    private String  description;
    private String  filePath;   // alias videoUrl
    private Integer orderNo;
    private String  duration;
    private String  createdAt;

    // alias เดิม
    public String getVideoUrl()             { return filePath; }
    public void   setVideoUrl(String url)   { this.filePath = url; }

    public String getDuration()  { return duration  != null ? duration  : ""; }
    public String getCreatedAt() { return createdAt != null ? createdAt : ""; }
    public String getFilePath()  { return filePath  != null ? filePath  : ""; }
}