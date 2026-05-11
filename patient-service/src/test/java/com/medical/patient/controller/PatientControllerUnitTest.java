package com.medical.patient.controller;

import com.medical.patient.entity.Patient;
import com.medical.patient.repository.PatientRepository;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

@Tag("unit")
class PatientControllerUnitTest {

    private final PatientRepository patientRepository = mock(PatientRepository.class);
    private final PatientController patientController = new PatientController(patientRepository);

    @Test
    void getPatientReturnsRepositoryPatient() {
        Patient patient = Patient.builder()
                .id(1L)
                .name("Unit Patient")
                .birthDate("1990-01-01")
                .gender("F")
                .contact("010-1111-2222")
                .build();
        when(patientRepository.findById(1L)).thenReturn(Optional.of(patient));

        Patient result = patientController.getPatient(1L);

        assertThat(result.getName()).isEqualTo("Unit Patient");
    }
}
