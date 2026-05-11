package com.medical.appointment.controller;

import com.medical.appointment.entity.Appointment;
import com.medical.appointment.service.AppointmentService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/appointments")
@RequiredArgsConstructor
public class AppointmentController {
    private final AppointmentService appointmentService;
    private final com.medical.appointment.repository.AppointmentRepository appointmentRepository;

    @PostMapping
    public Appointment createAppointment(@RequestBody Appointment appointment) {
        return appointmentService.createAppointment(appointment);
    }

    @PostMapping("/{id}/confirm")
    public Appointment confirmAppointment(@PathVariable Long id) {
        return appointmentService.confirmAppointment(id);
    }

    @GetMapping
    public java.util.List<Appointment> getAppointments(@RequestParam(required = false) Long patientId) {
        if (patientId != null) {
            // Using existing repository findByPatientId if available, 
            // otherwise using a custom method. Let's check repository first.
            return appointmentRepository.findAll().stream()
                    .filter(a -> a.getPatientId().equals(patientId))
                    .collect(java.util.stream.Collectors.toList());
        }
        return appointmentRepository.findAll();
    }
}
