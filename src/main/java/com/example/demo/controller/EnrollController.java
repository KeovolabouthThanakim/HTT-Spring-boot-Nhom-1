package com.example.demo.controller;

import com.example.demo.service.EnrollmentService;
import com.example.demo.entity.User;

import jakarta.servlet.http.HttpSession;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.*;

@Controller
@RequestMapping("/enroll")
public class EnrollController {

    @Autowired
    private EnrollmentService enrollmentService;

    @RequestMapping(method = {RequestMethod.GET, RequestMethod.POST})
    public String enroll(@RequestParam(required = false) Integer courseId,
                         HttpSession session) {

        User user = (User) session.getAttribute("user");
        if (user == null) return "redirect:/login";

        if (courseId == null || courseId <= 0)
            return "redirect:/home";

        boolean ok = enrollmentService.enroll(user.getId(), courseId);
        if (ok) {
            return "redirect:/classroom?courseId=" + courseId;
        } else {
            return "redirect:/dashboard?tab=courses&err=alreadyEnrolled";
        }
    }
}
