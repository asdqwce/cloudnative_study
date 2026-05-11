package com.medical.notification.controller;

import com.medical.notification.entity.Notification;
import com.medical.notification.repository.NotificationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/notifications")
@RequiredArgsConstructor
public class NotificationController {
    private final NotificationRepository notificationRepository;

    @GetMapping
    public List<Notification> getAllNotifications() {
        return notificationRepository.findAll();
    }

    @org.springframework.web.bind.annotation.PostMapping("/mock")
    public Notification createMockNotification(@org.springframework.web.bind.annotation.RequestBody Notification notification) {
        return notificationRepository.save(notification);
    }
}
