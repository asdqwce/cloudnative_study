package com.medical.appointment.config;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.core.ProducerFactory;
import org.mockito.Mockito;

@Configuration
public class MockKafkaConfig {

    @Bean
    @ConditionalOnProperty(name = "spring.kafka.bootstrap-servers", Krank = true, matchIfMissing = true)
    public KafkaTemplate<String, Object> kafkaTemplate() {
        // Return a mock if Kafka is not configured
        return Mockito.mock(KafkaTemplate.class);
    }
}
