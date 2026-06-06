package com.example.demo.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.nio.file.Paths;

@Configuration
public class WebConfig implements WebMvcConfigurer {

    /**
     * Injected from application.properties: app.upload.base-dir
     * Defaults to ${user.home}/lms-uploads if not set.
     * Override via env var UPLOAD_BASE_DIR on the server.
     */
    @Value("${app.upload.base-dir:#{systemProperties['user.home']}/lms-uploads}")
    private String uploadBaseDir;

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        // Resolve base dir to an absolute path so it never depends on JVM working directory
        String base = Paths.get(uploadBaseDir).toAbsolutePath().normalize().toString();

        // Serve from configured base dir (production)
        String uploadsPath = "file:" + base + "/uploads/";
        // Also serve from working directory (development)
        String uploadsPathDev = "file:" + Paths.get(System.getProperty("user.dir")).toAbsolutePath().normalize().toString() + "/uploads/";
        registry.addResourceHandler("/uploads/**")
                .addResourceLocations(uploadsPath, uploadsPathDev);

        String hwPath    = "file:" + base + "/homework_uploads/";
// Also serve from working directory (same as how /uploads/** works)
        String hwPathDev = "file:" + Paths.get(System.getProperty("user.dir")).toAbsolutePath().normalize().toString() + "/homework_uploads/";
        registry.addResourceHandler("/homework_uploads/**")
                .addResourceLocations(hwPath, hwPathDev);
    }
}