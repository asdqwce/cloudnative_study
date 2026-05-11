package com.medical.appointment.service;

import com.medical.appointment.dto.AppointmentEvent;
import com.medical.appointment.entity.Appointment;
import com.medical.appointment.repository.AppointmentRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AppointmentService {
    private final AppointmentRepository appointmentRepository;
    
    @org.springframework.beans.factory.annotation.Autowired(required = false)
    private org.springframework.kafka.core.KafkaTemplate<String, Object> kafkaTemplate;

    public AppointmentService(AppointmentRepository appointmentRepository) {
        this.appointmentRepository = appointmentRepository;
    }

    @Transactional
    public Appointment createAppointment(Appointment appointment) {
        appointment.setStatus("REQUESTED");
        return appointmentRepository.save(appointment);
    }

    @Transactional
    public Appointment confirmAppointment(Long id) {
        Appointment appointment = appointmentRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Appointment not found"));
        appointment.setStatus("CONFIRMED");
        
        Appointment saved = appointmentRepository.save(appointment);
        
        // Publish Event
        AppointmentEvent event = AppointmentEvent.builder()
                .appointmentId(saved.getId())
                .patientId(saved.getPatientId())
                .status(saved.getStatus())
                .build();
        
        if (kafkaTemplate != null) {
            kafkaTemplate.send("appointment-confirmed", event);
        } else {
            // Mock propagation for demo without Kafka
            System.out.println("KAFKA MOCK: Appointment confirmed - " + event);
        }
        
        return saved;
    }
}
