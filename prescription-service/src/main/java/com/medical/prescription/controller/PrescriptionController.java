package com.medical.prescription.controller;

import com.medical.prescription.entity.Prescription;
import com.medical.prescription.service.PrescriptionService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/prescriptions")
@RequiredArgsConstructor
public class PrescriptionController {
    private final PrescriptionService prescriptionService;

    @PostMapping
    public Prescription issuePrescription(@RequestBody Prescription prescription) {
        return prescriptionService.issuePrescription(prescription);
    }

    @GetMapping
    public java.util.List<Prescription> getPrescriptions(@RequestParam(required = false) Long patientId) {
        if (patientId != null) {
            return prescriptionService.getPrescriptionsByPatientId(patientId);
        }
        // Return all if no patientId provided (admin view)
        return null; // Or implement findAll if needed
    }
}
