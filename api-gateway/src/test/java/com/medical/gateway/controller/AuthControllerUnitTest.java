package com.medical.gateway.controller;

import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

@Tag("unit")
class AuthControllerUnitTest {

    @Test
    void getTestTokenReturnsSignedToken() {
        AuthController controller = new AuthController();
        ReflectionTestUtils.setField(controller, "secretKey", "very-long-secret-key-that-is-at-least-32-characters");

        Map<String, String> response = controller.getTestToken();

        assertThat(response).containsKey("token");
        assertThat(response.get("token")).isNotBlank();
    }
}
