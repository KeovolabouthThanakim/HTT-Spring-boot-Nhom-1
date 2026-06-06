package com.example.demo.service;

import com.example.demo.dto.VideoDTO;
import com.example.demo.entity.Course;
import com.example.demo.entity.Video;
import com.example.demo.repository.CourseRepository;
import com.example.demo.repository.VideoRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

/**
 * Service แทนที่ VideoDAO.java เดิม
 */
@Service
@RequiredArgsConstructor
public class VideoService {

    private final VideoRepository videoRepository;
    private final CourseRepository courseRepository;

    // ─── READ (จาก VideoDAO) ───────────────────────────────────────

    public Optional<VideoDTO> getVideoById(int videoId) {
        return videoRepository.findById(videoId).map(this::toDTO);
    }

    public Optional<Video> getVideoEntityById(int videoId) {
        return videoRepository.findById(videoId);
    }

    /** getVideosByCourse() เดิม */
    public List<VideoDTO> getVideosByCourse(int courseId) {
        return courseRepository.findById(courseId)
                .map(c -> videoRepository.findByCourseOrderByOrderNoAsc(c)
                        .stream().map(this::toDTO).collect(Collectors.toList()))
                .orElse(List.of());
    }

    // ─── WRITE (จาก VideoDAO) ──────────────────────────────────────

    /** addVideo() เดิม */
    @Transactional
    public boolean addVideo(int courseId, String title, String description, String videoUrl) {
        return courseRepository.findById(courseId).map(c -> {
            int nextOrder = videoRepository.findNextOrderNo(courseId);
            Video v = Video.builder()
                    .course(c)
                    .title(title)
                    .description(description != null ? description : "")
                    .filePath(videoUrl != null ? videoUrl : "")
                    .orderNo(nextOrder)
                    .build();
            videoRepository.save(v);
            return true;
        }).orElse(false);
    }

    /** updateVideo() เดิม */
    @Transactional
    public boolean updateVideo(int videoId, String title, String description, String videoUrl) {
        return videoRepository.findById(videoId).map(v -> {
            v.setTitle(title);
            v.setDescription(description != null ? description : "");
            v.setFilePath(videoUrl != null ? videoUrl : "");
            videoRepository.save(v);
            return true;
        }).orElse(false);
    }

    /** deleteVideo() เดิม */
    @Transactional
    public boolean deleteVideo(int videoId) {
        return videoRepository.findById(videoId).map(v -> {
            videoRepository.delete(v);
            return true;
        }).orElse(false);
    }

    /** countVideosByCourse() เดิม */
    public int countVideosByCourse(int courseId) {
        return courseRepository.findById(courseId)
                .map(c -> (int) videoRepository.countByCourse(c))
                .orElse(0);
    }

    // ─── MAPPER ───────────────────────────────────────────────────

    public VideoDTO toDTO(Video v) {
        return VideoDTO.builder()
                .id(v.getId())
                .courseId(v.getCourse() != null ? v.getCourse().getId() : null)
                .title(v.getTitle())
                .description(v.getDescription())
                .filePath(v.getFilePath())
                .orderNo(v.getOrderNo())
                .duration(v.getDuration())
                .createdAt(v.getCreatedAt() != null ? v.getCreatedAt().toString() : "")
                .build();
    }
}