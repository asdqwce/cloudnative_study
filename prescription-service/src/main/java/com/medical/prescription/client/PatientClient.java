package com.medical.prescription.client;

import lombok.Data;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;

@FeignClient(name = "patient-service")
public interface PatientClient {
    @GetMapping("/patients/{id}")
    PatientResponse getPatient(@PathVariable("id") Long id);

    @Data
    class PatientResponse {
        private Long id;
        private String name;
        private String contact;
    }
}
