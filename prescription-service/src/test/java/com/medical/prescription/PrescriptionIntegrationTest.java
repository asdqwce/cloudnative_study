package com.medical.prescription;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.medical.prescription.client.PatientClient;
import com.medical.prescription.entity.Prescription;
import com.medical.testsupport.AbstractIntegrationTest;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.hamcrest.Matchers.is;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest(properties = {
        "eureka.client.enabled=false",
        "spring.cloud.discovery.enabled=false"
})
@AutoConfigureMockMvc
class PrescriptionIntegrationTest extends AbstractIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private PatientClient patientClient;

    @Test
    void issuePrescription() throws Exception {
        PatientClient.PatientResponse patient = new PatientClient.PatientResponse();
        patient.setId(1L);
        patient.setName("Integration Patient");
        when(patientClient.getPatient(1L)).thenReturn(patient);

        Prescription prescription = Prescription.builder()
                .patientId(1L)
                .medicine("Amoxicillin")
                .dosage("500mg")
                .prescriptionDate("2026-05-12")
                .build();

        mockMvc.perform(post("/prescriptions")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(prescription)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.patientId", is(1)))
                .andExpect(jsonPath("$.medicine", is("Amoxicillin")));
    }
}
