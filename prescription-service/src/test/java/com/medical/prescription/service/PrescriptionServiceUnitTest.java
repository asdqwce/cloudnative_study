package com.medical.prescription.service;

import com.medical.prescription.client.PatientClient;
import com.medical.prescription.entity.Prescription;
import com.medical.prescription.repository.PrescriptionRepository;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

@Tag("unit")
class PrescriptionServiceUnitTest {

    private final PrescriptionRepository prescriptionRepository = mock(PrescriptionRepository.class);
    private final PatientClient patientClient = mock(PatientClient.class);
    private final PrescriptionService prescriptionService = new PrescriptionService(prescriptionRepository, patientClient);

    @Test
    void issuePrescriptionSavesPrescriptionWhenPatientExists() {
        PatientClient.PatientResponse patient = new PatientClient.PatientResponse();
        patient.setId(1L);
        patient.setName("Unit Patient");
        when(patientClient.getPatient(1L)).thenReturn(patient);
        when(prescriptionRepository.save(any(Prescription.class))).thenAnswer(invocation -> invocation.getArgument(0));

        Prescription prescription = Prescription.builder()
                .patientId(1L)
                .medicine("Amoxicillin")
                .dosage("500mg")
                .prescriptionDate("2026-05-12")
                .build();

        Prescription result = prescriptionService.issuePrescription(prescription);

        assertThat(result.getMedicine()).isEqualTo("Amoxicillin");
    }
}
