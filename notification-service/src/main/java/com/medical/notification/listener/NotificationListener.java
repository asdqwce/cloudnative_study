package com.medical.notification.listener;

import com.medical.notification.dto.AppointmentEvent;
import com.medical.notification.entity.Notification;
import com.medical.notification.repository.NotificationRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
@Slf4j
@org.springframework.boot.autoconfigure.condition.ConditionalOnProperty(name = "spring.kafka.bootstrap-servers")
public class NotificationListener {
    private final NotificationRepository notificationRepository;

    @KafkaListener(topics = "appointment-confirmed", groupId = "notification-group")
    public void handleAppointmentConfirmed(AppointmentEvent event) {
        log.info("Received appointment confirmed event: {}", event);
        
        Notification notification = Notification.builder()
                .patientId(event.getPatientId())
                .message("Your appointment (ID: " + event.getAppointmentId() + ") has been confirmed.")
                .sentDate(LocalDateTime.now().toString())
                .build();
        
        notificationRepository.save(notification);
        log.info("Notification sent to patient: {}", event.getPatientId());
    }
}
