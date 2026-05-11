package com.medical.notification.controller;

import com.medical.notification.entity.Notification;
import com.medical.notification.repository.NotificationRepository;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

@Tag("unit")
class NotificationControllerUnitTest {

    private final NotificationRepository notificationRepository = mock(NotificationRepository.class);
    private final NotificationController notificationController = new NotificationController(notificationRepository);

    @Test
    void getAllNotificationsReturnsRepositoryNotifications() {
        Notification notification = Notification.builder()
                .id(1L)
                .patientId(1L)
                .message("Appointment confirmed")
                .sentDate("2026-05-12T09:30:00")
                .build();
        when(notificationRepository.findAll()).thenReturn(List.of(notification));

        List<Notification> result = notificationController.getAllNotifications();

        assertThat(result).hasSize(1);
        assertThat(result.get(0).getMessage()).isEqualTo("Appointment confirmed");
    }
}
