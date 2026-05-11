package com.medical.notification.dto;

import lombok.Data;

@Data
public class AppointmentEvent {
    private Long appointmentId;
    private Long patientId;
    private String status;
}
