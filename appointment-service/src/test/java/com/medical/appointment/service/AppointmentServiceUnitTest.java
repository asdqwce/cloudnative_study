package com.medical.appointment.service;

import com.medical.appointment.entity.Appointment;
import com.medical.appointment.repository.AppointmentRepository;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

@Tag("unit")
class AppointmentServiceUnitTest {

    private final AppointmentRepository appointmentRepository = mock(AppointmentRepository.class);
    private final AppointmentService appointmentService = new AppointmentService(appointmentRepository);

    @Test
    void createAppointmentMarksAppointmentRequested() {
        Appointment appointment = Appointment.builder()
                .patientId(1L)
                .appointmentDate("2026-05-12T09:30:00")
                .build();
        when(appointmentRepository.save(any(Appointment.class))).thenAnswer(invocation -> invocation.getArgument(0));

        Appointment result = appointmentService.createAppointment(appointment);

        assertThat(result.getStatus()).isEqualTo("REQUESTED");
    }

    @Test
    void confirmAppointmentMarksAppointmentConfirmed() {
        Appointment appointment = Appointment.builder()
                .id(10L)
                .patientId(1L)
                .appointmentDate("2026-05-12T09:30:00")
                .status("REQUESTED")
                .build();
        when(appointmentRepository.findById(10L)).thenReturn(Optional.of(appointment));
        when(appointmentRepository.save(any(Appointment.class))).thenAnswer(invocation -> invocation.getArgument(0));

        Appointment result = appointmentService.confirmAppointment(10L);

        assertThat(result.getStatus()).isEqualTo("CONFIRMED");
    }
}
