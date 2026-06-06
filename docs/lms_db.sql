-- MySQL dump 10.13  Distrib 8.0.46, for macos15 (x86_64)
--
-- Host: localhost    Database: lms_db
-- ------------------------------------------------------
-- Server version	9.7.0

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
SET @MYSQLDUMP_TEMP_LOG_BIN = @@SESSION.SQL_LOG_BIN;
SET @@SESSION.SQL_LOG_BIN= 0;

--
-- GTID state at the beginning of the backup 
--

SET @@GLOBAL.GTID_PURGED=/*!80000 '+'*/ '1a94c028-47dd-11f1-9613-1a71ec4aaf8d:1-607';

--
-- Table structure for table `courses`
--

DROP TABLE IF EXISTS `courses`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `courses` (
  `id` int NOT NULL AUTO_INCREMENT,
  `title` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `category` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `duration_hours` int DEFAULT '0',
  `teacher_id` int NOT NULL,
  `status` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci GENERATED ALWAYS AS (`title`) STORED,
  PRIMARY KEY (`id`),
  KEY `teacher_id` (`teacher_id`),
  KEY `idx_courses_created_at` (`created_at`),
  CONSTRAINT `courses_ibfk_1` FOREIGN KEY (`teacher_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `courses`
--

LOCK TABLES `courses` WRITE;
/*!40000 ALTER TABLE `courses` DISABLE KEYS */;
INSERT INTO `courses` (`id`, `title`, `description`, `category`, `duration_hours`, `teacher_id`, `status`, `created_at`) VALUES (1,'IT','4 Tinhoc','ทั่วไป',0,1,'ACTIVE','2026-05-07 05:35:40'),(2,'Tiếng Anh','4 Tinhoc','General',0,1,'ACTIVE','2026-05-07 05:40:55'),(3,'Java','Java','General',0,1,'ACTIVE','2569-05-30 23:18:19');
/*!40000 ALTER TABLE `courses` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `enrollments`
--

DROP TABLE IF EXISTS `enrollments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `enrollments` (
  `id` int NOT NULL AUTO_INCREMENT,
  `student_id` int NOT NULL,
  `course_id` int NOT NULL,
  `enrolled_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_enroll` (`student_id`,`course_id`),
  UNIQUE KEY `UKi0g6mfijtuh199nj653nva6j5` (`student_id`,`course_id`),
  KEY `course_id` (`course_id`),
  KEY `idx_enrollments_enrolled_at` (`enrolled_at`),
  CONSTRAINT `enrollments_ibfk_1` FOREIGN KEY (`student_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `enrollments_ibfk_2` FOREIGN KEY (`course_id`) REFERENCES `courses` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `enrollments`
--

LOCK TABLES `enrollments` WRITE;
/*!40000 ALTER TABLE `enrollments` DISABLE KEYS */;
INSERT INTO `enrollments` VALUES (1,10,2,'2026-05-07 05:43:30'),(2,1,2,'2026-05-12 21:19:01'),(3,6,2,'2026-05-20 01:22:36'),(4,10,1,'2026-05-22 06:15:07'),(5,10,3,'2569-05-31 02:28:12');
/*!40000 ALTER TABLE `enrollments` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `homework_submissions`
--

DROP TABLE IF EXISTS `homework_submissions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `homework_submissions` (
  `id` int NOT NULL AUTO_INCREMENT,
  `student_id` int NOT NULL,
  `course_id` int NOT NULL,
  `video_id` int NOT NULL DEFAULT '0',
  `title` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `file_path` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `file_name` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `submitted_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `status` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT 'PENDING',
  `teacher_comment` text COLLATE utf8mb4_unicode_ci,
  PRIMARY KEY (`id`),
  KEY `student_id` (`student_id`),
  KEY `course_id` (`course_id`),
  CONSTRAINT `homework_submissions_ibfk_1` FOREIGN KEY (`student_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `homework_submissions_ibfk_2` FOREIGN KEY (`course_id`) REFERENCES `courses` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `homework_submissions`
--

LOCK TABLES `homework_submissions` WRITE;
/*!40000 ALTER TABLE `homework_submissions` DISABLE KEYS */;
INSERT INTO `homework_submissions` VALUES (1,1,2,0,'อออ','อออ','homework_uploads/39a8c8eae01c480081d53f9ea4022946.docx','3_11_Mau-quyển báo cáo Thực tập Chuyên ngành.docx','2026-05-27 15:35:52','PENDING',NULL),(2,10,2,3,'vv','vv','homework_uploads/b9863c0e778741a28d2f33d6f8d1be86.docx','3_11_Mau-quyển báo cáo Thực tập Chuyên ngành.docx','2026-05-28 17:43:23','REVIEWED',NULL),(3,10,2,3,'vv','vv','homework_uploads/19e63b425d6d445cb094e333324d084b.docx','3_11_Mau-quyển báo cáo Thực tập Chuyên ngành.docx','2569-05-30 18:34:54','PENDING',NULL);
/*!40000 ALTER TABLE `homework_submissions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `teacher_reviews`
--

DROP TABLE IF EXISTS `teacher_reviews`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `teacher_reviews` (
  `id` int NOT NULL AUTO_INCREMENT,
  `comment` text COLLATE utf8mb4_unicode_ci,
  `created_at` datetime(6) DEFAULT NULL,
  `rating` int NOT NULL,
  `course_id` int NOT NULL,
  `student_id` int NOT NULL,
  `teacher_id` int NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `UKd671xny6rx0tc2uxg5qqjleyo` (`student_id`,`teacher_id`,`course_id`),
  KEY `FKjs2rc043aatda1ec2l4135cx2` (`course_id`),
  KEY `FK7p591eat4srwe9795h4wc1g9t` (`teacher_id`),
  CONSTRAINT `FK7p591eat4srwe9795h4wc1g9t` FOREIGN KEY (`teacher_id`) REFERENCES `users` (`id`),
  CONSTRAINT `FKa6dkegdm3lmb3hkla7n8lb75s` FOREIGN KEY (`student_id`) REFERENCES `users` (`id`),
  CONSTRAINT `FKjs2rc043aatda1ec2l4135cx2` FOREIGN KEY (`course_id`) REFERENCES `courses` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `teacher_reviews`
--

LOCK TABLES `teacher_reviews` WRITE;
/*!40000 ALTER TABLE `teacher_reviews` DISABLE KEYS */;
/*!40000 ALTER TABLE `teacher_reviews` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `id` int NOT NULL AUTO_INCREMENT,
  `username` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `password` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'MD5 hash',
  `first_name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `last_name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `student_id` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `department` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `role` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `status` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `profile_photo` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Relative path under uploads/',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `username` (`username`),
  UNIQUE KEY `email` (`email`),
  KEY `idx_users_created_at` (`created_at`)
) ENGINE=InnoDB AUTO_INCREMENT=18 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES (1,'Superadmin01','$2a$10$CXLVz0dFguyTt01one//8egrLlr/Yh/5sm2qB463yP7FAtX6tnF86','Jingleed','Jingleed','Jingleed@gmail.com',NULL,NULL,'SUPER_ADMIN','ACTIVE','profile/user_1_0a8b1ae8.jpg','2026-05-05 01:04:30'),(3,'Superadmin02','a9dfc5ff819a6e4ef2b4b0f5167618b7','Sonya','Vayakone','Superadmin02@gmail.com',NULL,NULL,'SUPER_ADMIN','ACTIVE',NULL,'2026-05-05 01:36:37'),(6,'Link','3f524bb624968e463bb9d74646568286','Link','Link','Link@gmail.com',NULL,NULL,'TEACHER','ACTIVE',NULL,'2026-05-05 03:28:52'),(10,'Sonyar','$2a$10$RLrTP9mcsuOyR4iGQT3xdOwLUKJLyerUs/QlRPJEDCG/iIlfhMolC','Sonyar','Sonyar','Sonya@gmail.com','23ATT149','IT','STUDENT','ACTIVE','profile/user_10_810cd43e.jpg','2026-05-05 04:01:30'),(11,'Admin01','e64b78fc3bc91bcbc7dc232ba8ec59e0','Admin01','Admin01','Admin01@gmail.com',NULL,NULL,'ADMIN','ACTIVE',NULL,'2026-05-05 23:21:14'),(12,'Admin02','e64b78fc3bc91bcbc7dc232ba8ec59e0','Nguyen','Nguyen','Nguyen@gmail.com',NULL,NULL,'ADMIN','ACTIVE',NULL,'2026-05-11 00:13:52'),(13,'Admin03','e64b78fc3bc91bcbc7dc232ba8ec59e0','Admin03','Admin03','Admin03@gmail.com',NULL,NULL,'ADMIN','ACTIVE',NULL,'2026-05-26 19:48:22'),(14,'Thanakim','fc2612f198b25f4cff4d72cf13e94710','keovolabouth','Thanakim','thanakim@gmail.com',NULL,NULL,'TEACHER','ACTIVE',NULL,'2026-05-29 00:32:11'),(16,'Thanakim01','19a83ffaa5d7e39f09666cd9f290b124','Thanakim','Thanakim','thanakim01@gmail.com',NULL,NULL,'TEACHER','ACTIVE',NULL,'2026-05-29 14:14:20'),(17,'Xang','39448baa436d9b90ed2af8203e5391bb','Xang','Xangkham','xang@gmail.com',NULL,NULL,'TEACHER','ACTIVE',NULL,'2569-05-30 18:30:28');
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `videos`
--

DROP TABLE IF EXISTS `videos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `videos` (
  `id` int NOT NULL AUTO_INCREMENT,
  `course_id` int NOT NULL,
  `order_no` int DEFAULT '0',
  `title` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `file_path` varchar(500) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'relative path on server',
  `order_num` int DEFAULT '0',
  `duration` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'HH:MM:SS',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_videos_course_id` (`course_id`),
  CONSTRAINT `videos_ibfk_1` FOREIGN KEY (`course_id`) REFERENCES `courses` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `videos`
--

LOCK TABLES `videos` WRITE;
/*!40000 ALTER TABLE `videos` DISABLE KEYS */;
INSERT INTO `videos` VALUES (3,2,1,'Vi du1','','https://youtu.be/_P5pfYvCSO4?si=SSjS7BMlaxcKiryl',0,NULL,'2026-05-22 06:10:04'),(4,3,1,'java','java','https://youtu.be/RJZIJdYMsYg?si=o65vofFe8oM3YcFI',0,NULL,'2569-05-31 02:27:34');
/*!40000 ALTER TABLE `videos` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping events for database 'lms_db'
--

--
-- Dumping routines for database 'lms_db'
--
SET @@SESSION.SQL_LOG_BIN = @MYSQLDUMP_TEMP_LOG_BIN;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-05-31 16:47:32
