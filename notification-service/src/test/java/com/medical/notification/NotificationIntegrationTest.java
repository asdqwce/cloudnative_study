package com.medical.notification;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.medical.notification.dto.AppointmentEvent;
import com.medical.notification.entity.Notification;
import com.medical.notification.repository.NotificationRepository;
import com.medical.testsupport.AbstractIntegrationTest;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.time.Duration;
import java.util.concurrent.TimeUnit;

import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.is;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest(properties = {
        "eureka.client.enabled=false",
        "spring.cloud.discovery.enabled=false"
})
@AutoConfigureMockMvc
class NotificationIntegrationTest extends AbstractIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private KafkaTemplate<String, Object> kafkaTemplate;

    @Autowired
    private NotificationRepository notificationRepository;

    @BeforeEach
    void cleanNotifications() {
        notificationRepository.deleteAll();
    }

    @Test
    void createMockNotificationAndListNotifications() throws Exception {
        Notification notification = Notification.builder()
                .patientId(1L)
                .message("Appointment confirmed")
                .sentDate("2026-05-12T09:30:00")
                .build();

        mockMvc.perform(post("/notifications/mock")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(notification)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message", is("Appointment confirmed")));

        mockMvc.perform(get("/notifications"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(1)));
    }

    @Test
    void storeNotificationFromAppointmentConfirmedKafkaEvent() throws Exception {
        AppointmentEvent event = new AppointmentEvent();
        event.setAppointmentId(77L);
        event.setPatientId(42L);
        event.setStatus("CONFIRMED");

        kafkaTemplate.send(appointmentConfirmedTopic(), event).get(10, TimeUnit.SECONDS);

        Notification notification = waitForNotification(42L);

        mockMvc.perform(get("/notifications"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(1)))
                .andExpect(jsonPath("$[0].id", is(notification.getId().intValue())))
                .andExpect(jsonPath("$[0].patientId", is(42)))
                .andExpect(jsonPath("$[0].message", is("Your appointment (ID: 77) has been confirmed.")));
    }

    private Notification waitForNotification(Long patientId) throws InterruptedException {
        long deadline = System.nanoTime() + Duration.ofSeconds(10).toNanos();

        while (System.nanoTime() < deadline) {
            var notification = notificationRepository.findAll()
                    .stream()
                    .filter(candidate -> patientId.equals(candidate.getPatientId()))
                    .findFirst();

            if (notification.isPresent()) {
                return notification.get();
            }

            Thread.sleep(250);
        }

        throw new AssertionError("notification was not stored for patient " + patientId);
    }
}
