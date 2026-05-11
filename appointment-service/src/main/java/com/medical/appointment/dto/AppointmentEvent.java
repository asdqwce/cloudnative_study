package com.medical.appointment.dto;

import lombok.*;

@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class AppointmentEvent {
    private Long appointmentId;
    private Long patientId;
    private String status;
}
