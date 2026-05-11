package com.medical.prescription.service;

import com.medical.prescription.client.PatientClient;
import com.medical.prescription.entity.Prescription;
import com.medical.prescription.repository.PrescriptionRepository;
import io.github.resilience4j.circuitbreaker.annotation.CircuitBreaker;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
@Slf4j
public class PrescriptionService {
    private final PrescriptionRepository prescriptionRepository;
    private final PatientClient patientClient;

    @CircuitBreaker(name = "patientService", fallbackMethod = "fallbackGetPatient")
    public Prescription issuePrescription(Prescription prescription) {
        // Validate patient exists via Feign
        PatientClient.PatientResponse patient = patientClient.getPatient(prescription.getPatientId());
        log.info("Issuing prescription for patient: {}", patient.getName());
        
        return prescriptionRepository.save(prescription);
    }

    public java.util.List<Prescription> getPrescriptionsByPatientId(Long patientId) {
        return prescriptionRepository.findByPatientId(patientId);
    }

    public Prescription fallbackGetPatient(Prescription prescription, Throwable t) {
        log.error("Patient service is down or error occurred: {}", t.getMessage());
        log.info("Issuing prescription without patient validation (Fallback)");
        return prescriptionRepository.save(prescription);
    }
}
