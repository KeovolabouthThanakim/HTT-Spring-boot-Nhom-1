package com.example.demo.controller;

import jakarta.servlet.http.HttpSession;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.*;

/**
 * Handles the contact / support form.
 *
 * Two modes depending on whether JavaMailSender is configured:
 *
 *   1. Email mode (production): add spring-boot-starter-mail to pom.xml and
 *      configure these properties:
 *        spring.mail.host=smtp.gmail.com
 *        spring.mail.port=587
 *        spring.mail.username=your@email.com
 *        spring.mail.password=${MAIL_PASSWORD}
 *        spring.mail.properties.mail.smtp.auth=true
 *        spring.mail.properties.mail.smtp.starttls.enable=true
 *        app.contact.recipient=support@yourdomain.com
 *        app.contact.mail-enabled=true
 *
 *   2. No-mail mode (default / development):
 *      JavaMailSender bean is absent → form accepted and logged only.
 *
 * JSP side: replace the dummy submitContactForm() JS with a real form POST:
 *   <form method="post" action="/contact">
 *     <input name="name" ...>
 *     <input name="email" ...>
 *     <select name="subject" ...>
 *     <textarea name="message" ...>
 *     <button type="submit">Gửi</button>
 *   </form>
 */
@Controller
public class ContactController {

    // Optional — null when spring-boot-starter-mail is absent or not configured
    @Autowired(required = false)
    private JavaMailSender mailSender;

    @Value("${app.contact.recipient:support@localhost}")
    private String contactRecipient;

    @Value("${app.contact.mail-enabled:false}")
    private boolean mailEnabled;

    @PostMapping("/contact")
    public String submitContact(
            @RequestParam String name,
            @RequestParam String email,
            @RequestParam String subject,
            @RequestParam String message,
            @RequestParam(required = false) String phone,
            @RequestParam(required = false, defaultValue = "/dashboard?tab=contact") String redirect,
            HttpSession session) {

        // Basic validation
        if (name.isBlank() || email.isBlank() || subject.isBlank() || message.isBlank()) {
            return "redirect:" + redirect + (redirect.contains("?") ? "&" : "?") + "err=emptyFields";
        }
        if (!email.matches("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$")) {
            return "redirect:" + redirect + (redirect.contains("?") ? "&" : "?") + "err=invalidEmail";
        }

        // Always log the submission
        System.out.printf("[Contact] from=%s <%s> phone=%s subject=%s%n", name, email, phone, subject);

        // Send email only when configured
        if (mailEnabled && mailSender != null) {
            try {
                SimpleMailMessage mail = new SimpleMailMessage();
                mail.setTo(contactRecipient);
                mail.setReplyTo(email);
                mail.setSubject("[LMS Contact] " + subject);
                String body = "From: " + name + " <" + email + ">" + (phone != null ? " Phone: " + phone : "") + "\n\n" + message;
                mail.setText(body);
                mailSender.send(mail);
            } catch (Exception ex) {
                System.err.println("[Contact] Mail send failed: " + ex.getMessage());
                return "redirect:" + redirect + (redirect.contains("?") ? "&" : "?") + "err=mailFailed";
            }
        }

        return "redirect:" + redirect + (redirect.contains("?") ? "&" : "?") + "success=sent";
    }
}